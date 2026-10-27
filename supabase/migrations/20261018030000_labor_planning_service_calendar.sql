BEGIN;

-- Extend the authorized planning payload with calendar fields only. Keep the
-- estimation as a reference; do not overwrite dates already planned per worker.
CREATE FUNCTION public.get_labor_crew_planning_calendar(p_project uuid) RETURNS jsonb
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE data jsonb; BEGIN
 data:=public.get_labor_crew_planning(p_project);
 RETURN data||jsonb_build_object(
 'labor',coalesce((SELECT jsonb_agg(entry.value||jsonb_build_object(
  'reference_service_name',reference_service.name,
  'reference_start',coalesce(est.start_date,task.start_date),
  'reference_end',coalesce(est.end_date,task.end_date),
  'working_days',est.total_working_days,
  'reference_source',CASE WHEN est.id IS NOT NULL THEN 'estimation'
    WHEN task.start_date IS NOT NULL OR task.end_date IS NOT NULL THEN 'service_plan' ELSE NULL END
 ) ORDER BY entry.ordinality)
 FROM jsonb_array_elements(data->'labor') WITH ORDINALITY entry(value,ordinality)
 JOIN public.project_labor l ON l.id=(entry.value->>'id')::uuid
 LEFT JOIN public.quote_service_labors ql ON ql.id=l.quote_service_labor_id
 LEFT JOIN public.project_services ps ON ps.id=l.project_service_id
 LEFT JOIN public.quote_services reference_service ON reference_service.id=coalesce(l.quote_service_id,ps.quote_service_id,ql.quote_service_id)
 LEFT JOIN LATERAL (
  SELECT e.id,(e.start_date AT TIME ZONE 'UTC')::date AS start_date,(e.end_date AT TIME ZONE 'UTC')::date AS end_date,e.total_working_days FROM public.quote_service_estimations e
  WHERE e.quote_service_id=coalesce(l.quote_service_id,ps.quote_service_id,ql.quote_service_id)
  ORDER BY e.updated_at DESC NULLS LAST,e.created_at DESC NULLS LAST,e.id DESC LIMIT 1
 ) est ON true
 LEFT JOIN LATERAL (
  SELECT min(t.planned_start_date) AS start_date,max(t.planned_end_date) AS end_date
  FROM public.project_tasks t WHERE t.project_id=p_project AND est.id IS NULL
   AND ((l.project_service_id IS NOT NULL AND t.project_service_id=l.project_service_id)
    OR (l.quote_service_id IS NOT NULL AND t.quote_service_id=l.quote_service_id))
 ) task ON true),'[]'::jsonb),
 'non_working_days',coalesce((SELECT jsonb_agg(jsonb_build_object('date',date,'partial_ratio',partial_ratio) ORDER BY date)
  FROM public.project_non_working_days WHERE project_id=p_project),'[]'::jsonb));
END $$;
REVOKE ALL ON FUNCTION public.get_labor_crew_planning_calendar(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_labor_crew_planning_calendar(uuid) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
