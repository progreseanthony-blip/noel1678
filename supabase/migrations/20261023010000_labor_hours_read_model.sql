-- Read-only operational access inside Labor Cost. No payroll mutations or prices.
BEGIN;
CREATE FUNCTION public.get_labor_hours_projects() RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF app_private.role() IS NULL THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'title',p.title)
 ORDER BY p.title) FROM public.projects p WHERE app_private.is_admin() OR EXISTS(
 SELECT 1 FROM public.project_members m WHERE m.project_id=p.id
 AND m.profile_id=auth.uid() AND m.responsibility=app_private.role())), '[]'::jsonb);
END $$;

CREATE FUNCTION public.get_labor_hours(p_project uuid,p_start date,p_end date,p_crew uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; crew_list jsonb;
BEGIN
 IF p_start IS NULL OR p_end IS NULL OR p_end<p_start OR p_end-p_start>365
 THEN RAISE EXCEPTION 'Choose a date range of up to 366 days'; END IF;
 IF app_private.role() IS NULL OR NOT EXISTS(
   SELECT 1 FROM generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') day
   WHERE app_private.is_admin() OR
    (app_private.role()='Supervisor' AND app_private.project_access(p_project,day::date)) OR
    EXISTS(SELECT 1 FROM public.project_crews c WHERE c.project_id=p_project
      AND (p_crew IS NULL OR c.id=p_crew) AND app_private.can_report(p_project,day::date,c.id)))
 OR NOT EXISTS(SELECT 1 FROM public.projects WHERE id=p_project)
 THEN RAISE EXCEPTION 'Access denied for this project and date range'; END IF;
 IF p_crew IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews c
 WHERE c.id=p_crew AND c.project_id=p_project AND EXISTS(
 SELECT 1 FROM generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') day
 WHERE app_private.can_report(p_project,day::date,c.id)))
 THEN RAISE EXCEPTION 'Access denied for this crew'; END IF;

 SELECT coalesce(jsonb_agg(jsonb_build_object('id',c.id,'name',c.name) ORDER BY c.name),'[]'::jsonb)
 INTO crew_list FROM public.project_crews c WHERE c.project_id=p_project AND EXISTS(
 SELECT 1 FROM generate_series(p_start::timestamp,p_end::timestamp,interval '1 day') day
 WHERE app_private.can_report(p_project,day::date,c.id));

 -- Classify full ISO weeks across all projects BEFORE restricting output.
 -- Every saved ID appears once; a merged legacy contribution is not a second row.
 WITH source AS (
  SELECT l.id,l.worker_id,d.project_id,d.report_date,
   coalesce(l.execution_crew_id,s.crew_id,old.crew_id) crew_id,
   l.check_in_time,l.check_out_time,coalesce(l.break_minutes,0) break_minutes,
   greatest(coalesce(l.total_net_hours,0),0)::numeric net_hours,
   CASE WHEN d.status='rejected' THEN 'rejected' ELSE coalesce(s.status,d.status) END status,
   CASE WHEN s.id IS NOT NULL THEN s.status='approved' AND d.status<>'rejected'
        ELSE d.status='approved' END validated,
   l.project_labor_id,l.transfer_id,
   extract(isoyear FROM d.report_date)::int iso_year,
   extract(week FROM d.report_date)::int iso_week
  FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
  LEFT JOIN public.daily_report_sections s ON s.id=l.section_id
  LEFT JOIN public.crew_daily_reports old ON old.id=l.crew_report_id
  WHERE d.report_date BETWEEN date_trunc('week',p_start::timestamp)::date
   AND (date_trunc('week',p_end::timestamp)::date+6)
 ), classified AS (
  SELECT source.*,coalesce(sum(CASE WHEN validated THEN net_hours ELSE 0 END) OVER(
   PARTITION BY worker_id,iso_year,iso_week
   ORDER BY report_date,check_in_time NULLS LAST,id
   ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING),0) previous_hours FROM source
 ), visible AS (
  SELECT a.*, CASE WHEN validated THEN least(net_hours,greatest(40-previous_hours,0)) END regular_hours,
   CASE WHEN validated THEN greatest(net_hours-greatest(40-previous_hours,0),0) END overtime_hours
  FROM classified a WHERE project_id=p_project AND report_date BETWEEN p_start AND p_end
   AND (p_crew IS NULL OR crew_id=p_crew)
   AND (app_private.is_admin() OR
    (app_private.role()='Supervisor' AND app_private.project_access(p_project,report_date)) OR
    (crew_id IS NOT NULL AND app_private.can_report(p_project,report_date,crew_id)))
 ) SELECT coalesce(jsonb_agg(jsonb_build_object(
  'id',v.id,'worker_id',v.worker_id,'worker',w.full_name,'id_number',w.id_number,
  'date',v.report_date,'crew_id',v.crew_id,'crew',c.name,'role',pl.role_name,'service',qs.name,
  'check_in',v.check_in_time,'check_out',v.check_out_time,'break_minutes',v.break_minutes,
  'net_hours',v.net_hours,'regular_hours',v.regular_hours,'overtime_hours',v.overtime_hours,
  'status',v.status,'validated',v.validated,'transfer_id',v.transfer_id,
  'iso_year',v.iso_year,'iso_week',v.iso_week
 ) ORDER BY v.report_date,w.full_name,v.check_in_time,v.id),'[]'::jsonb) INTO result
 FROM visible v JOIN public.workers w ON w.id=v.worker_id
 LEFT JOIN public.project_crews c ON c.id=v.crew_id
 LEFT JOIN public.project_labor pl ON pl.id=v.project_labor_id
 LEFT JOIN public.quote_services qs ON qs.id=pl.quote_service_id;

 RETURN jsonb_build_object('project',(SELECT title FROM public.projects WHERE id=p_project),
 'crews',crew_list,'rows',result,'periods',coalesce((SELECT jsonb_agg(jsonb_build_object(
 'id',id,'name',name,'start_date',start_date,'end_date',end_date,'status',status)
 ORDER BY end_date DESC) FROM public.payroll_periods WHERE project_id=p_project),'[]'::jsonb));
END $$;
REVOKE ALL ON FUNCTION public.get_labor_hours_projects(),public.get_labor_hours(uuid,date,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_labor_hours_projects(),public.get_labor_hours(uuid,date,date,uuid) TO authenticated;
NOTIFY pgrst, 'reload schema';
COMMIT;
