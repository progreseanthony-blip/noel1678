BEGIN;
-- Existing estimates retain their contractual totals and are reviewed manually.
ALTER TABLE public.quotes ADD COLUMN team_planning_required boolean NOT NULL DEFAULT false;
ALTER TABLE public.quotes ALTER COLUMN team_planning_required SET DEFAULT true;
ALTER TABLE public.labor_roles ADD COLUMN operational_role text NOT NULL DEFAULT 'none'
 CHECK(operational_role IN ('none','Supervisor','Foreman'));
ALTER TABLE public.quote_service_labors ADD COLUMN operational_role text NOT NULL DEFAULT 'none'
 CHECK(operational_role IN ('none','Supervisor','Foreman')),
 ADD COLUMN coverage_scope text NOT NULL DEFAULT 'service' CHECK(coverage_scope IN ('service','project'));
ALTER TABLE public.project_labor ADD COLUMN operational_role text NOT NULL DEFAULT 'none'
 CHECK(operational_role IN ('none','Supervisor','Foreman')),
 ADD COLUMN coverage_scope text NOT NULL DEFAULT 'service' CHECK(coverage_scope IN ('service','project'));

CREATE FUNCTION public.validate_quote_team(p_quote uuid) RETURNS void LANGUAGE plpgsql
 SECURITY DEFINER SET search_path='' AS $$
DECLARE responsibility text; BEGIN
 IF NOT coalesce(app_private.quote_access(p_quote),false) THEN RAISE EXCEPTION 'Acceso denegado'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND team_planning_required) THEN RETURN; END IF;
 FOREACH responsibility IN ARRAY ARRAY['Supervisor','Foreman'] LOOP
  IF NOT EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
   WHERE s.quote_id=p_quote AND l.operational_role=responsibility AND l.employees_quantity>=1
    AND l.employees_quantity=trunc(l.employees_quantity) AND l.months_to_work>0 AND l.hourly_rate>0
    AND (responsibility<>'Supervisor' OR l.coverage_scope='project'))
   THEN RAISE EXCEPTION 'La cotización requiere al menos una plaza de %, con cantidad entera, duración y tarifa; Supervisor debe cubrir el proyecto',responsibility; END IF;
 END LOOP;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.operational_role<>'none' AND
   (coalesce(l.employees_quantity,0)<1 OR l.employees_quantity<>trunc(l.employees_quantity)
     OR coalesce(l.months_to_work,0)<=0 OR coalesce(l.hourly_rate,0)<=0 OR (l.operational_role='Supervisor' AND l.coverage_scope<>'project')))
  THEN RAISE EXCEPTION 'Revisa cantidad, duración, tarifa y alcance de las plazas de Supervisor y Foreman'; END IF;
END $$;
CREATE FUNCTION app_private.guard_quote_team() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF TG_TABLE_NAME='quotes' THEN
  IF NEW.status IN ('sent','accepted') THEN PERFORM public.validate_quote_team(NEW.id); END IF;
 ELSE
  IF NEW.quote_id IS NOT NULL THEN PERFORM public.validate_quote_team(NEW.quote_id); END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_quote_team AFTER INSERT OR UPDATE OF status ON public.quotes
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_quote_team();
CREATE TRIGGER guard_project_team_budget BEFORE INSERT ON public.projects
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_quote_team();

CREATE FUNCTION app_private.copy_team_budget() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF NEW.quote_service_labor_id IS NOT NULL THEN
  SELECT operational_role,coverage_scope,coalesce(NEW.quote_service_id,quote_service_id)
   INTO NEW.operational_role,NEW.coverage_scope,NEW.quote_service_id
   FROM public.quote_service_labors WHERE id=NEW.quote_service_labor_id;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER copy_team_budget BEFORE INSERT ON public.project_labor
 FOR EACH ROW EXECUTE FUNCTION app_private.copy_team_budget();

CREATE FUNCTION public.get_labor_crew_planning_responsibilities(p_project uuid) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 result:=public.get_labor_crew_planning_calendar(p_project);
 result:=jsonb_set(result,'{labor}',coalesce((SELECT jsonb_agg(e.value||jsonb_build_object(
  'operational_role',l.operational_role,'coverage_scope',l.coverage_scope))
  FROM jsonb_array_elements(result->'labor') e JOIN public.project_labor l ON l.id=(e.value->>'id')::uuid),'[]'));
 result:=jsonb_set(result,'{workers}',coalesce((SELECT jsonb_agg(e.value||jsonb_build_object(
  'profile_id',p.id,'profile_role',p.role,'access_status',p.access_status))
  FROM jsonb_array_elements(result->'workers') e LEFT JOIN public.profiles p ON p.worker_id=(e.value->>'id')::uuid),'[]'));
 RETURN result||jsonb_build_object('can_authorize',app_private.is_admin());
END $$;

ALTER FUNCTION public.save_labor_crew_plan(uuid,text,jsonb,uuid,text,uuid) RENAME TO save_labor_crew_plan_base;
CREATE OR REPLACE FUNCTION public.save_labor_crew_plan_base(p_project uuid,p_service text,p_rows jsonb,
 p_crew uuid DEFAULT NULL,p_crew_name text DEFAULT NULL,p_foreman uuid DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb; a public.project_labor_assignments; labor_row public.project_labor; selected public.project_labor;
 s public.crew_service_assignments; cid uuid:=p_crew; mid uuid; rows_out jsonb:='[]';
 first_day date; last_day date; day_from date; day_until date; worker uuid; leader public.crew_leaders; BEGIN
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 -- All organization writes use the team lock before row locks/worker locks.
 PERFORM pg_advisory_xact_lock(1678,2);
 PERFORM 1 FROM public.projects WHERE id=p_project FOR UPDATE;
 IF jsonb_typeof(p_rows) IS DISTINCT FROM 'array' OR jsonb_array_length(p_rows)=0 OR jsonb_array_length(p_rows)>500
 THEN RAISE EXCEPTION 'Select between 1 and 500 worker periods'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.project_labor l WHERE l.project_id=p_project AND app_private.labor_service_key(l)=p_service)
 THEN RAISE EXCEPTION 'Select a planned service in this project'; END IF;
 IF cid IS NOT NULL AND nullif(trim(p_crew_name),'') IS NOT NULL THEN RAISE EXCEPTION 'Choose an existing crew or create a new one'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  IF jsonb_typeof(item)<>'object' THEN RAISE EXCEPTION 'Invalid worker row'; END IF;
  day_from:=(item->>'valid_from')::date; day_until:=(item->>'valid_until')::date;
  IF day_from IS NULL OR day_until IS NULL OR day_until<day_from THEN RAISE EXCEPTION 'Each worker needs a valid start and end date'; END IF;
  first_day:=least(first_day,day_from); last_day:=greatest(last_day,day_until);
 END LOOP;
 IF cid IS NULL AND nullif(trim(p_crew_name),'') IS NOT NULL THEN
  INSERT INTO public.project_crews(project_id,name) VALUES(p_project,trim(p_crew_name)) RETURNING id INTO cid;
 END IF;
 IF cid IS NOT NULL THEN
  IF NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=cid AND project_id=p_project AND active)
  THEN RAISE EXCEPTION 'Select an active crew in this project'; END IF;
  SELECT * INTO s FROM public.crew_service_assignments WHERE crew_id=cid AND service_key=p_service
   AND valid_from<=last_day+1 AND valid_until>=first_day-1 ORDER BY valid_from LIMIT 1;
  IF s.id IS NOT NULL AND (s.valid_from>first_day OR s.valid_until<last_day) THEN
   UPDATE public.crew_service_assignments SET valid_from=least(valid_from,first_day),valid_until=greatest(valid_until,last_day) WHERE id=s.id RETURNING * INTO s;
  END IF;
  IF s.id IS NULL THEN
   INSERT INTO public.crew_service_assignments(crew_id,project_id,service_key,valid_from,valid_until)
    VALUES(cid,p_project,p_service,first_day,last_day) RETURNING * INTO s;
  END IF;
  SELECT * INTO leader FROM public.crew_leaders WHERE crew_id=cid AND valid_from<=last_day
   AND (valid_until IS NULL OR valid_until>=first_day) ORDER BY valid_from LIMIT 1;
  IF leader.id IS NULL THEN
   IF p_foreman IS NULL THEN RAISE EXCEPTION 'Select an authorized Foreman covering all selected dates'; END IF;
   INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until) VALUES(cid,p_foreman,first_day,last_day);
  ELSE
   IF p_foreman IS NOT NULL AND p_foreman<>leader.profile_id THEN RAISE EXCEPTION 'End the current leadership period before choosing a different Foreman'; END IF;
   IF leader.valid_until<last_day THEN
    UPDATE public.crew_leaders SET valid_until=last_day WHERE id=leader.id;
   END IF;
   IF leader.valid_from>first_day THEN
    INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until) VALUES(cid,leader.profile_id,first_day,leader.valid_from-1);
   END IF;
  END IF;
 END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  day_from:=(item->>'valid_from')::date; day_until:=(item->>'valid_until')::date;
  worker:=(item->>'worker_id')::uuid;
  IF worker IS NULL THEN RAISE EXCEPTION 'Select a worker'; END IF;
  IF item->>'assignment_id' IS NOT NULL THEN
   SELECT * INTO STRICT a FROM public.project_labor_assignments WHERE id=(item->>'assignment_id')::uuid FOR UPDATE;
   SELECT * INTO STRICT labor_row FROM public.project_labor WHERE id=a.project_labor_id;
   IF a.worker_id<>worker OR labor_row.project_id<>p_project OR app_private.labor_service_key(labor_row)<>p_service
    OR a.start_date IS NULL OR a.end_date IS NULL OR day_from<a.start_date OR day_until>a.end_date
   THEN RAISE EXCEPTION 'Worker participation must fit its existing service assignment dates'; END IF;
  ELSE
   SELECT * INTO STRICT labor_row FROM public.project_labor WHERE id=(item->>'project_labor_id')::uuid;
   IF labor_row.project_id<>p_project OR app_private.labor_service_key(labor_row)<>p_service
   THEN RAISE EXCEPTION 'Labor role belongs to another service'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.workers WHERE id=worker AND status='Active')
   THEN RAISE EXCEPTION 'Select an active worker'; END IF;
   -- Reuse a physical planned slot for non-overlapping periods; retain history.
   IF EXISTS(SELECT 1 FROM public.project_labor_assignments pa JOIN public.project_labor x ON x.id=pa.project_labor_id
    WHERE pa.worker_id=worker AND daterange(pa.start_date,pa.end_date,'[]') && daterange(day_from,day_until,'[]'))
   THEN RAISE EXCEPTION 'Worker already has planning in this interval'; END IF;
   SELECT x.* INTO selected FROM public.project_labor x WHERE x.project_id=p_project
    AND app_private.labor_service_key(x)=p_service AND x.role_name IS NOT DISTINCT FROM labor_row.role_name AND x.operational_role=labor_row.operational_role AND x.coverage_scope=labor_row.coverage_scope
    AND NOT EXISTS(SELECT 1 FROM public.project_labor_assignments pa WHERE pa.project_labor_id=x.id AND pa.worker_id=worker)
    AND NOT EXISTS(SELECT 1 FROM public.project_labor_assignments pa WHERE pa.project_labor_id=x.id
     AND daterange(pa.start_date,pa.end_date,'[]') && daterange(day_from,day_until,'[]'))
    ORDER BY x.id LIMIT 1;
   IF selected.id IS NULL THEN RAISE EXCEPTION 'No planned vacancy covers the full interval for role %',labor_row.role_name; END IF;
   INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date)
    VALUES(selected.id,worker,day_from,day_until) RETURNING * INTO a;
  END IF;
  IF cid IS NOT NULL THEN
   INSERT INTO public.crew_members(crew_id,worker_id,valid_from,valid_until,labor_assignment_id,crew_service_assignment_id)
    VALUES(cid,worker,day_from,day_until,a.id,s.id) RETURNING id INTO mid;
  ELSE mid:=NULL; END IF;
  rows_out:=rows_out||jsonb_build_array(jsonb_build_object('assignment_id',a.id,'membership_id',mid));
 END LOOP;
 RETURN jsonb_build_object('crew_id',cid,'period_id',s.id,'rows',rows_out);
END $$;

REVOKE ALL ON FUNCTION public.save_labor_crew_plan_base(uuid,text,jsonb,uuid,text,uuid) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION public.save_labor_crew_plan(p_project uuid,p_service text,p_rows jsonb,p_crew uuid DEFAULT NULL,
 p_crew_name text DEFAULT NULL,p_foreman uuid DEFAULT NULL) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE e jsonb; l public.project_labor; u public.profiles; first_day date; last_day date; a public.project_labor_assignments; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN RAISE EXCEPTION 'Acceso denegado'; END IF;
 FOR e IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  IF e->>'assignment_id' IS NOT NULL THEN
   SELECT * INTO STRICT a FROM public.project_labor_assignments WHERE id=(e->>'assignment_id')::uuid;
   SELECT * INTO STRICT l FROM public.project_labor WHERE id=a.project_labor_id;
  ELSE SELECT * INTO STRICT l FROM public.project_labor WHERE id=(e->>'project_labor_id')::uuid; END IF;
  IF l.project_id<>p_project THEN RAISE EXCEPTION 'La plaza pertenece a otro proyecto'; END IF;
  IF l.operational_role='none' THEN CONTINUE; END IF;
  first_day:=(e->>'valid_from')::date; last_day:=(e->>'valid_until')::date;
  SELECT * INTO u FROM public.profiles WHERE worker_id=(e->>'worker_id')::uuid AND access_status='active' AND role=l.operational_role;
  IF u.id IS NULL THEN RAISE EXCEPTION 'El trabajador requiere un usuario activo vinculado con rol %',l.operational_role; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.project_members m WHERE m.project_id=p_project AND m.profile_id=u.id
   AND m.responsibility=l.operational_role AND m.valid_from<=first_day AND (m.valid_until IS NULL OR m.valid_until>=last_day)) THEN
   IF NOT app_private.is_admin() THEN RAISE EXCEPTION 'El administrador debe autorizar este responsable para todo el período'; END IF;
   -- Never change existing permissions/history to make a new assignment fit.
   IF EXISTS(SELECT 1 FROM public.project_members m WHERE m.project_id=p_project AND m.profile_id=u.id
    AND daterange(m.valid_from,m.valid_until,'[]') && daterange(first_day,last_day,'[]'))
    THEN RAISE EXCEPTION 'Amplía o revisa la autorización existente en Responsables del proyecto'; END IF;
   INSERT INTO public.project_members(project_id,profile_id,responsibility,valid_from,valid_until)
    VALUES(p_project,u.id,l.operational_role,first_day,last_day);
  END IF;
 END LOOP;
 RETURN public.save_labor_crew_plan_base(p_project,p_service,p_rows,p_crew,p_crew_name,p_foreman);
END $$;
REVOKE ALL ON FUNCTION public.validate_quote_team(uuid),public.get_labor_crew_planning_responsibilities(uuid),
 public.save_labor_crew_plan(uuid,text,jsonb,uuid,text,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.validate_quote_team(uuid),public.get_labor_crew_planning_responsibilities(uuid),
 public.save_labor_crew_plan(uuid,text,jsonb,uuid,text,uuid) TO authenticated;
REVOKE ALL ON FUNCTION app_private.guard_quote_team(),app_private.copy_team_budget() FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
