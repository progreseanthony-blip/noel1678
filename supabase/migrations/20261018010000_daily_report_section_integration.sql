BEGIN;

ALTER TABLE public.daily_reports
 ADD COLUMN submitted_by uuid REFERENCES public.profiles(id),
 ADD COLUMN submitted_at timestamptz;

-- The creator can be a Foreman. Independence of the final approval must also
-- be checked against the supervisor who actually submitted the consolidation.
CREATE FUNCTION app_private.guard_daily_report_submitter() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF TG_OP='INSERT' THEN NEW.submitted_by:=NULL; NEW.submitted_at:=NULL; RETURN NEW; END IF;
 IF NEW.status='submitted' AND NEW.status IS DISTINCT FROM OLD.status THEN
  IF NOT coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(NEW.project_id,NEW.report_date)),false)
  THEN RAISE EXCEPTION 'Only a supervisor or administrator can submit the consolidated report'; END IF;
  NEW.submitted_by:=auth.uid(); NEW.submitted_at:=now();
 ELSIF NEW.status IN ('approved','rejected') AND NEW.status IS DISTINCT FROM OLD.status THEN
  IF auth.uid()=coalesce(OLD.submitted_by,OLD.supervisor_id)
  THEN RAISE EXCEPTION 'The consolidated report submitter cannot approve or reject it'; END IF;
  NEW.submitted_by:=OLD.submitted_by; NEW.submitted_at:=OLD.submitted_at;
 ELSIF NEW.submitted_by IS DISTINCT FROM OLD.submitted_by OR NEW.submitted_at IS DISTINCT FROM OLD.submitted_at THEN
  RAISE EXCEPTION 'Submission identity is managed by the report workflow';
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_daily_report_submitter BEFORE INSERT OR UPDATE ON public.daily_reports
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_daily_report_submitter();

ALTER TABLE public.daily_report_sections
 ADD COLUMN signature_points jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(signature_points)='array'),
 ADD COLUMN evidence_photos jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(evidence_photos)='array');

CREATE FUNCTION public.get_daily_operation_projects() RETURNS jsonb
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',p.id,'title',p.title,'status',p.status,
  'client_name',p.client_name,'start_date',p.start_date) ORDER BY p.created_at DESC),'[]'::jsonb)
 FROM public.projects p WHERE
  (p.calculation_metadata->>'baseline_latest_version' IS NOT NULL OR
   coalesce((p.calculation_metadata->>'baseline_frozen')::boolean,false)) AND
  (app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p.id)) OR
   EXISTS(SELECT 1 FROM public.project_crews c WHERE c.project_id=p.id AND app_private.leads(c.id)))
$$;

CREATE FUNCTION public.get_daily_operation_reports(p_project uuid) RETURNS jsonb
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT coalesce(app_private.is_admin() OR app_private.project_access(p_project),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',d.id,'project_id',d.project_id,
  'report_date',d.report_date,'status',d.status,'weather_condition',d.weather_condition,
  'supervisor_id',d.supervisor_id,'submitted_by',d.submitted_by,'has_sections',EXISTS(SELECT 1 FROM public.daily_report_sections WHERE daily_report_id=d.id))
  ORDER BY d.report_date DESC) FROM public.daily_reports d WHERE d.project_id=p_project AND
  (app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p_project,d.report_date)) OR
   EXISTS(SELECT 1 FROM public.project_crews c WHERE c.project_id=p_project AND app_private.leads(c.id,d.report_date)))),'[]'::jsonb);
END $$;

-- One lightweight context call selects the correct report before loading any
-- resource. Foreman never falls back to unrestricted table/catalog queries.
CREATE FUNCTION public.get_daily_report_entry_context(p_project uuid,p_day date DEFAULT current_date,p_report uuid DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.daily_reports; day date:=p_day; crews jsonb; allowed boolean; BEGIN
 IF NOT coalesce(app_private.is_admin() OR app_private.project_access(p_project),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF p_report IS NOT NULL THEN
  SELECT * INTO STRICT d FROM public.daily_reports WHERE id=p_report AND project_id=p_project;
  day:=d.report_date;
 ELSE
  IF day IS NULL THEN RAISE EXCEPTION 'Report date is required'; END IF;
  SELECT * INTO d FROM public.daily_reports WHERE project_id=p_project AND report_date=day;
 END IF;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name) ORDER BY c.name),'[]'::jsonb)
 INTO crews FROM public.project_crews c WHERE c.project_id=p_project AND c.active AND app_private.can_report(p_project,day,c.id);
 allowed:=coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p_project,day))
  OR jsonb_array_length(crews)>0,false);
 IF NOT allowed THEN RAISE EXCEPTION 'No authorized crew or supervisor assignment for this date'; END IF;
 RETURN jsonb_build_object('project',(SELECT jsonb_build_object('id',id,'title',title,'status',status)
  FROM public.projects WHERE id=p_project),'date',day,'crews',crews,
  'report',CASE WHEN d.id IS NULL THEN NULL ELSE jsonb_build_object('id',d.id,'project_id',d.project_id,
   'report_date',d.report_date,'status',d.status,'weather_condition',d.weather_condition,
   'day_type',d.day_type,'stopped_at',d.stopped_at,'general_notes',d.general_notes) END,
  'has_sections',EXISTS(SELECT 1 FROM public.daily_report_sections WHERE daily_report_id=d.id),
  'legacy_resources',EXISTS(SELECT 1 FROM public.report_labor_logs WHERE daily_report_id=d.id AND section_id IS NULL)
   OR EXISTS(SELECT 1 FROM public.report_machinery_logs WHERE daily_report_id=d.id AND section_id IS NULL)
   OR EXISTS(SELECT 1 FROM public.report_material_usage WHERE daily_report_id=d.id AND section_id IS NULL));
END $$;

CREATE FUNCTION public.ensure_daily_report(p_project uuid,p_day date) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.daily_reports; BEGIN
 IF p_day IS NULL OR NOT coalesce(app_private.is_admin() OR
  (app_private.role()='Supervisor' AND app_private.project_access(p_project,p_day)),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id=p_project AND status='active')
 THEN RAISE EXCEPTION 'Project is read only'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('report:'||p_project||':'||p_day,0));
 SELECT * INTO d FROM public.daily_reports WHERE project_id=p_project AND report_date=p_day FOR UPDATE;
 IF d.id IS NULL THEN
  INSERT INTO public.daily_reports(project_id,report_date,supervisor_id,status)
   VALUES(p_project,p_day,auth.uid(),'draft') RETURNING * INTO d;
 END IF;
 IF d.status NOT IN ('draft','rejected') THEN RAISE EXCEPTION 'Report is locked'; END IF;
 RETURN jsonb_build_object('id',d.id,'report_date',d.report_date,'status',d.status);
END $$;

-- Do not lock legacy draft entries by silently introducing sections alongside
-- them. Conversion and legacy contribution reconciliation belong to phase 6.
CREATE FUNCTION app_private.guard_section_legacy_mix() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM 1 FROM public.daily_reports WHERE id=NEW.daily_report_id FOR UPDATE;
 IF EXISTS(SELECT 1 FROM public.report_labor_logs WHERE daily_report_id=NEW.daily_report_id AND section_id IS NULL)
  OR EXISTS(SELECT 1 FROM public.report_machinery_logs WHERE daily_report_id=NEW.daily_report_id AND section_id IS NULL)
  OR EXISTS(SELECT 1 FROM public.report_material_usage WHERE daily_report_id=NEW.daily_report_id AND section_id IS NULL)
 THEN RAISE EXCEPTION 'Legacy daily report: continue using the consolidated editor'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_section_legacy_mix BEFORE INSERT ON public.daily_report_sections
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_section_legacy_mix();

CREATE FUNCTION public.save_daily_report_section_v2(p_section uuid,p_revision integer,p_notes text,
 p_labor jsonb,p_machinery jsonb,p_materials jsonb,p_submit boolean DEFAULT false,
 p_signature jsonb DEFAULT '[]',p_photos jsonb DEFAULT '[]') RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; point jsonb; photo jsonb; BEGIN
 IF jsonb_typeof(p_signature) IS DISTINCT FROM 'array' OR jsonb_typeof(p_photos) IS DISTINCT FROM 'array'
 THEN RAISE EXCEPTION 'Evidence arrays are required'; END IF;
 IF jsonb_array_length(p_signature)>10000 OR jsonb_array_length(p_photos)>30
 THEN RAISE EXCEPTION 'Too much evidence'; END IF;
 FOR point IN SELECT value FROM jsonb_array_elements(p_signature) LOOP
  IF jsonb_typeof(point)<>'object' OR jsonb_typeof(point->'x') IS DISTINCT FROM 'number'
   OR jsonb_typeof(point->'y') IS DISTINCT FROM 'number' OR (point->>'x')::numeric<0 OR (point->>'y')::numeric<0
   OR (point->>'x')::numeric>10000 OR (point->>'y')::numeric>10000
  THEN RAISE EXCEPTION 'Invalid signature point'; END IF;
 END LOOP;
 FOR photo IN SELECT value FROM jsonb_array_elements(p_photos) LOOP
  IF jsonb_typeof(photo)<>'string' OR length(photo#>>'{}')>2048 OR (photo#>>'{}') !~ '^https?://'
  THEN RAISE EXCEPTION 'Invalid evidence URL'; END IF;
 END LOOP;
 result:=public.save_daily_report_section(p_section,p_revision,p_notes,p_labor,p_machinery,p_materials,p_submit);
 UPDATE public.daily_report_sections SET signature_points=p_signature,evidence_photos=p_photos
  WHERE id=p_section RETURNING to_jsonb(daily_report_sections) INTO result;
 RETURN result;
END $$;

REVOKE ALL ON FUNCTION app_private.guard_section_legacy_mix(),app_private.guard_daily_report_submitter() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_daily_operation_projects(),public.get_daily_operation_reports(uuid),
 public.get_daily_report_entry_context(uuid,date,uuid),
 public.ensure_daily_report(uuid,date),
 public.save_daily_report_section_v2(uuid,integer,text,jsonb,jsonb,jsonb,boolean,jsonb,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_daily_operation_projects(),public.get_daily_operation_reports(uuid),
 public.get_daily_report_entry_context(uuid,date,uuid),
 public.ensure_daily_report(uuid,date),
 public.save_daily_report_section_v2(uuid,integer,text,jsonb,jsonb,jsonb,boolean,jsonb,jsonb) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
