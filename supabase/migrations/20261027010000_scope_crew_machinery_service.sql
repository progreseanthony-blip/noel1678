BEGIN;

-- Existing crews without service planning keep their historical workflow.
-- Once a service is planned, only its resources within that period are writable.
CREATE FUNCTION app_private.crew_machine_service_allowed(p_crew uuid,p_day date,p_machine uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT EXISTS(SELECT 1 FROM public.project_machinery m JOIN public.project_crews c ON c.project_id=m.project_id
  WHERE m.id=p_machine AND c.id=p_crew AND (
   NOT EXISTS(SELECT 1 FROM public.crew_service_assignments a WHERE a.crew_id=p_crew)
   OR EXISTS(SELECT 1 FROM public.crew_service_assignments a WHERE a.crew_id=p_crew
    AND a.project_id=m.project_id AND p_day BETWEEN a.valid_from AND a.valid_until
    AND a.service_key=CASE WHEN m.quote_service_id IS NOT NULL THEN 'q:'||m.quote_service_id
     WHEN m.project_service_id IS NOT NULL THEN 'p:'||m.project_service_id ELSE 'u:'||m.project_id END)))
$$;
REVOKE ALL ON FUNCTION app_private.crew_machine_service_allowed(uuid,date,uuid) FROM PUBLIC,anon,authenticated;

CREATE FUNCTION app_private.guard_crew_machine_service() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE crew uuid; day date;
BEGIN
 IF NEW.section_id IS NULL THEN RETURN NEW; END IF;
 SELECT s.crew_id,d.report_date INTO crew,day FROM public.daily_report_sections s
 JOIN public.daily_reports d ON d.id=s.daily_report_id WHERE s.id=NEW.section_id;
 IF crew IS NOT NULL AND NOT app_private.crew_machine_service_allowed(crew,day,NEW.project_machinery_id)
 THEN RAISE EXCEPTION 'This machine belongs to a service not assigned to the selected crew on this date'; END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION app_private.guard_crew_machine_service() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER guard_crew_machine_service BEFORE INSERT OR UPDATE ON public.report_machinery_logs
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_crew_machine_service();

CREATE OR REPLACE FUNCTION public.get_daily_execution_planned_workspace(p_project uuid,p_day date,p_crew uuid)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE data jsonb; planned jsonb; x jsonb; filtered jsonb;
BEGIN
 data:=public.get_daily_execution_workspace(p_project,p_day,p_crew);
 IF p_crew IS NOT NULL THEN
  planned:='[]';
  FOR x IN SELECT value FROM jsonb_array_elements(data->'planned_labor') LOOP
   SELECT coalesce(jsonb_agg(a.value),'[]'::jsonb) INTO filtered FROM jsonb_array_elements(x->'project_labor_assignments') a
   WHERE EXISTS(SELECT 1 FROM public.crew_members m WHERE m.crew_id=p_crew AND m.worker_id=(a.value->>'worker_id')::uuid
    AND m.valid_from<=p_day AND (m.valid_until IS NULL OR m.valid_until>=p_day)
    AND (m.labor_assignment_id IS NULL OR m.labor_assignment_id=(a.value->>'id')::uuid))
    OR EXISTS(SELECT 1 FROM public.daily_worker_transfers t WHERE t.daily_report_id=(data->'report'->>'id')::uuid
     AND t.to_crew_id=p_crew AND t.worker_id=(a.value->>'worker_id')::uuid AND t.project_labor_id=(x->>'id')::uuid AND t.status='approved');
   planned:=planned||jsonb_build_array(x||jsonb_build_object('project_labor_assignments',filtered));
  END LOOP;
  data:=jsonb_set(data,'{planned_labor}',planned);
  SELECT coalesce(jsonb_agg(x.value),'[]'::jsonb) INTO filtered
   FROM jsonb_array_elements(data->'planned_machinery') x
   WHERE app_private.crew_machine_service_allowed(p_crew,p_day,(x.value->>'id')::uuid);
  data:=jsonb_set(data,'{planned_machinery}',filtered);
 END IF;
 planned:=public.get_daily_machinery_progress(p_project,p_day,p_crew);
 IF p_crew IS NOT NULL THEN
  SELECT coalesce(jsonb_agg(x.value),'[]'::jsonb) INTO filtered
   FROM jsonb_array_elements(planned->'machinery') x
   WHERE app_private.crew_machine_service_allowed(p_crew,p_day,(x.value->>'id')::uuid);
  planned:=jsonb_set(planned,'{machinery}',filtered);
 END IF;
 RETURN data||jsonb_build_object('machinery_progress',planned);
END $$;
NOTIFY pgrst,'reload schema';
COMMIT;
