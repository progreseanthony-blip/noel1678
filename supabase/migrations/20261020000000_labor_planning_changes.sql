BEGIN;

CREATE TABLE public.labor_planning_actions (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 project_id uuid NOT NULL REFERENCES public.projects(id),
 actor_id uuid NOT NULL REFERENCES public.profiles(id) DEFAULT auth.uid(),
 action text NOT NULL,
 reason text NOT NULL CHECK(length(trim(reason))>=3),
 before_data jsonb NOT NULL,
 after_data jsonb,
 created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.labor_planning_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY planning_action_read ON public.labor_planning_actions FOR SELECT TO authenticated
 USING(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(project_id)));
GRANT SELECT ON public.labor_planning_actions TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.labor_planning_actions FROM authenticated,anon;

CREATE FUNCTION app_private.crew_has_activity(p_crew uuid,p_from date,p_until date)
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.daily_report_sections s JOIN public.daily_reports d ON d.id=s.daily_report_id
  WHERE s.crew_id=p_crew AND d.report_date>=p_from AND (p_until IS NULL OR d.report_date<=p_until))
 OR EXISTS(SELECT 1 FROM public.crew_daily_reports r WHERE r.crew_id=p_crew AND r.report_date>=p_from
  AND (p_until IS NULL OR r.report_date<=p_until))
 OR EXISTS(SELECT 1 FROM public.daily_worker_transfers t JOIN public.daily_reports d ON d.id=t.daily_report_id
  WHERE p_crew IN (t.from_crew_id,t.to_crew_id) AND d.report_date>=p_from AND (p_until IS NULL OR d.report_date<=p_until))
$$;

-- Corrections are allowed only before execution, including for future teams
-- in a project that is already active. Direct API writes obey the same rules.
CREATE OR REPLACE FUNCTION app_private.protect_team_history() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF TG_TABLE_NAME IN ('crew_leaders','crew_members') THEN
  SELECT project_id INTO p FROM public.project_crews WHERE id=OLD.crew_id;
  IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Acceso denegado o proyecto en consulta'; END IF;
  IF TG_OP='DELETE' AND TG_TABLE_NAME='crew_members' THEN
   IF app_private.crew_has_activity(OLD.crew_id,OLD.valid_from,OLD.valid_until)
    THEN RAISE EXCEPTION 'La participación tiene actividad; finaliza su vigencia en lugar de cancelarla'; END IF;
   RETURN OLD;
  END IF;
  IF TG_OP='UPDATE' AND TG_TABLE_NAME='crew_leaders' AND
   (to_jsonb(NEW)-'profile_id')=(to_jsonb(OLD)-'profile_id') THEN
   IF app_private.crew_has_activity(OLD.crew_id,OLD.valid_from,OLD.valid_until)
    THEN RAISE EXCEPTION 'El Foreman tiene actividad vinculada; utiliza el cambio por fecha'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.project_members m JOIN public.profiles u ON u.id=m.profile_id
    WHERE m.project_id=p AND m.profile_id=NEW.profile_id AND m.responsibility='Foreman'
     AND u.role='Foreman' AND u.access_status='active' AND m.valid_from<=NEW.valid_from
     AND (m.valid_until IS NULL OR (NEW.valid_until IS NOT NULL AND m.valid_until>=NEW.valid_until)))
    THEN RAISE EXCEPTION 'Selecciona un Foreman activo y autorizado para todo el período'; END IF;
   RETURN NEW;
  END IF;
 END IF;
 IF TG_OP='DELETE' THEN RAISE EXCEPTION 'Finaliza la vigencia en lugar de borrar el historial'; END IF;
 IF (to_jsonb(NEW)-'valid_until') IS DISTINCT FROM (to_jsonb(OLD)-'valid_until')
  THEN RAISE EXCEPTION 'Finaliza la asignación y crea una nueva para cambiar su identidad'; END IF;
 RETURN NEW;
END $$;

CREATE FUNCTION public.change_labor_crew_foreman(p_leader uuid,p_profile uuid,p_mode text,p_from date,p_reason text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE old_leader public.crew_leaders; p uuid; next_id uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 SELECT * INTO STRICT old_leader FROM public.crew_leaders WHERE id=p_leader FOR UPDATE;
 SELECT project_id INTO p FROM public.project_crews WHERE id=old_leader.crew_id AND active;
 IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Acceso denegado o proyecto en consulta'; END IF;
 IF length(trim(coalesce(p_reason,'')))<3 THEN RAISE EXCEPTION 'Indica el motivo del cambio'; END IF;
 IF p_profile=old_leader.profile_id THEN RAISE EXCEPTION 'Selecciona un Foreman diferente'; END IF;
 IF p_mode='correct' THEN
  UPDATE public.crew_leaders SET profile_id=p_profile WHERE id=p_leader;
  next_id:=p_leader;
 ELSIF p_mode='replace' THEN
  IF p_from IS NULL OR NOT isfinite(p_from) OR p_from<=old_leader.valid_from OR
   (old_leader.valid_until IS NOT NULL AND p_from>old_leader.valid_until)
   THEN RAISE EXCEPTION 'La fecha del relevo debe estar dentro de la vigencia y ser posterior al inicio'; END IF;
  IF app_private.crew_has_activity(old_leader.crew_id,p_from,old_leader.valid_until)
   THEN RAISE EXCEPTION 'Hay actividad desde la fecha elegida; los reportes existentes deben conservar su responsable'; END IF;
  UPDATE public.crew_leaders SET valid_until=p_from-1 WHERE id=p_leader;
  INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until)
   VALUES(old_leader.crew_id,p_profile,p_from,old_leader.valid_until) RETURNING id INTO next_id;
 ELSE RAISE EXCEPTION 'Selecciona corrección o relevo'; END IF;
 INSERT INTO public.labor_planning_actions(project_id,action,reason,before_data,after_data)
 SELECT p,'foreman_'||p_mode,p_reason,to_jsonb(old_leader),to_jsonb(l) FROM public.crew_leaders l WHERE id=next_id;
END $$;

CREATE FUNCTION public.change_labor_worker_plan(p_assignment uuid,p_action text,p_until date,p_reason text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a public.project_labor_assignments; p uuid; m public.crew_members; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 SELECT * INTO STRICT a FROM public.project_labor_assignments WHERE id=p_assignment FOR UPDATE;
 SELECT project_id INTO p FROM public.project_labor WHERE id=a.project_labor_id;
 IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Acceso denegado o proyecto en consulta'; END IF;
 IF length(trim(coalesce(p_reason,'')))<3 THEN RAISE EXCEPTION 'Indica el motivo'; END IF;
 IF p_action NOT IN ('crew_end','finish','cancel') THEN RAISE EXCEPTION 'Acción inválida'; END IF;
 IF EXISTS(SELECT 1 FROM public.crew_members cm JOIN public.project_crews c ON c.id=cm.crew_id
  WHERE c.project_id=p AND cm.worker_id=a.worker_id AND cm.labor_assignment_id IS NULL
   AND daterange(cm.valid_from,cm.valid_until,'[]') && daterange(a.start_date,a.end_date,'[]'))
  THEN RAISE EXCEPTION 'Hay una participación anterior sin vínculo a esta plaza. Revisa su vigencia en Cuadrillas antes de modificar la planificación'; END IF;
 IF p_action<>'cancel' AND (p_until IS NULL OR NOT isfinite(p_until) OR p_until<a.start_date OR p_until>a.end_date)
  THEN RAISE EXCEPTION 'El último día debe estar dentro de las fechas planificadas'; END IF;
 IF p_action='cancel' AND (EXISTS(SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
  WHERE l.worker_id=a.worker_id AND l.project_labor_id=a.project_labor_id AND d.report_date BETWEEN a.start_date AND a.end_date)
  OR EXISTS(SELECT 1 FROM public.daily_worker_transfers t JOIN public.daily_reports d ON d.id=t.daily_report_id
   WHERE t.worker_id=a.worker_id AND t.project_labor_id=a.project_labor_id AND d.report_date BETWEEN a.start_date AND a.end_date))
  THEN RAISE EXCEPTION 'La asignación tiene ejecución; finalízala conservando el historial'; END IF;
 FOR m IN SELECT * FROM public.crew_members WHERE labor_assignment_id=a.id FOR UPDATE LOOP
  IF p_action='cancel' OR m.valid_from>p_until THEN
   DELETE FROM public.crew_members WHERE id=m.id;
  ELSIF m.valid_until IS NULL OR m.valid_until>p_until THEN
   IF app_private.crew_has_activity(m.crew_id,p_until+1,m.valid_until)
    THEN RAISE EXCEPTION 'Hay actividad posterior; revisa la fecha de retiro'; END IF;
   UPDATE public.crew_members SET valid_until=p_until WHERE id=m.id;
  END IF;
 END LOOP;
 IF p_action='cancel' THEN DELETE FROM public.project_labor_assignments WHERE id=a.id;
 ELSIF p_action='finish' THEN UPDATE public.project_labor_assignments SET end_date=p_until WHERE id=a.id;
 END IF;
 INSERT INTO public.labor_planning_actions(project_id,action,reason,before_data,after_data)
 VALUES(p,p_action,p_reason,to_jsonb(a),jsonb_build_object('last_day',p_until));
END $$;

REVOKE ALL ON FUNCTION app_private.crew_has_activity(uuid,date,date) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.change_labor_crew_foreman(uuid,uuid,text,date,text),
 public.change_labor_worker_plan(uuid,text,date,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.change_labor_crew_foreman(uuid,uuid,text,date,text),
 public.change_labor_worker_plan(uuid,text,date,text) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
