BEGIN;

-- Operational progress includes submitted work, as in the original daily report.
-- Payroll and validated financial totals keep their own approval rules.
CREATE OR REPLACE FUNCTION public.get_daily_machinery_progress(p_project uuid,p_day date,p_crew uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE own_id uuid; result jsonb;
BEGIN
 IF p_day IS NULL OR NOT coalesce(app_private.can_report(p_project,p_day,p_crew),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF p_crew IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=p_crew AND project_id=p_project)
 THEN RAISE EXCEPTION 'Crew belongs to a different project'; END IF;
 SELECT s.id INTO own_id FROM public.daily_report_sections s
 JOIN public.daily_reports d ON d.id=s.daily_report_id
 WHERE d.project_id=p_project AND d.report_date=p_day AND s.crew_id IS NOT DISTINCT FROM p_crew;
 SELECT jsonb_build_object('date',p_day,'calendar',coalesce((
  SELECT jsonb_agg(jsonb_build_object('date',date,'partial_ratio',partial_ratio))
  FROM public.project_non_working_days WHERE project_id=p_project),'[]'::jsonb),
  'machinery',coalesce((SELECT jsonb_agg(jsonb_build_object(
   'id',m.id,'quote_service_id',m.quote_service_id,'name',m.machinery_name,
   'service_name',qs.name,'unit',qs.unit_of_measure,'is_principal',m.is_principal,
   'expected_quantity',m.expected_quantity,'start_date',m.start_date,'end_date',m.end_date,
   'capacity_per_trip',coalesce(nullif((m.calculation_metadata->>'capacity')::numeric,0),est.capacity_per_trip,0),
   'trips_per_day',coalesce(nullif((m.calculation_metadata->>'trips_per_day')::numeric,0),est.trips_per_day,0),
   'performance_per_day',coalesce(nullif((m.calculation_metadata->>'performance_per_day')::numeric,0),est.performance_per_day,0),
   'assignments',coalesce((SELECT jsonb_agg(jsonb_build_object('start_date',a.start_date,
     'end_date',a.end_date,'quantity',a.quantity) ORDER BY a.start_date,a.id)
     FROM public.project_machinery_assignments a WHERE a.project_machinery_id=m.id),'[]'::jsonb),
   'units',coalesce((SELECT jsonb_agg(jsonb_build_object('id',i.id,'name',coalesce(i.internal_id,i.internal_code,i.id::text)))
     FROM public.machinery_inspections i WHERE i.project_machinery_id=m.id),'[]'::jsonb),
   'actual',coalesce((SELECT jsonb_agg(to_jsonb(t)) FROM (
     SELECT l.machinery_inspection_id AS unit_id,
      coalesce(sum(l.production_value) FILTER(WHERE d.report_date<p_day),0) AS before,
      coalesce(sum(l.production_value) FILTER(WHERE d.report_date=p_day),0) AS today_other
     FROM public.report_machinery_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
     LEFT JOIN public.daily_report_sections s ON s.id=l.section_id
     WHERE l.project_machinery_id=m.id AND d.project_id=p_project AND d.report_date<=p_day
      AND d.status IN ('draft','submitted','approved')
      AND ((l.section_id IS NULL AND d.status IN ('submitted','approved')) OR s.status IN ('submitted','approved'))
      AND (d.report_date<p_day OR (p_crew IS NOT NULL AND l.section_id IS DISTINCT FROM own_id)
       OR (p_crew IS NULL AND l.section_id IS NOT NULL))
     GROUP BY l.machinery_inspection_id
    ) t),'[]'::jsonb)
   ) ORDER BY qs.name,m.machinery_name,m.id)
   FROM public.project_machinery m LEFT JOIN public.quote_services qs ON qs.id=m.quote_service_id
   LEFT JOIN LATERAL(SELECT er.capacity_per_trip,er.trips_per_day,er.performance_per_day
    FROM public.quote_service_estimations e JOIN public.quote_service_estimation_resources er ON er.estimation_id=e.id
    WHERE e.quote_service_id=m.quote_service_id AND er.machine_id=m.machinery_id
    ORDER BY e.id,er.id LIMIT 1) est ON true
   WHERE m.project_id=p_project AND m.is_principal),'[]'::jsonb)) INTO result;
 RETURN result;
END $$;

NOTIFY pgrst, 'reload schema';
COMMIT;
