BEGIN;
-- Scheduling context for authorized planners. Showing a booking's project name
-- does not grant access to that project or expose its financial information.
CREATE FUNCTION public.get_labor_worker_availability(p_project uuid,p_from date,p_until date)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 IF p_from IS NULL OR p_until IS NULL OR p_until<p_from THEN RAISE EXCEPTION 'Select valid planning dates'; END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('worker_id',a.worker_id,'project_title',p.title,
  'role_name',l.role_name,'start_date',a.start_date,'end_date',a.end_date) ORDER BY a.worker_id,p.title,a.start_date,a.id)
  FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
  JOIN public.projects p ON p.id=l.project_id JOIN public.workers w ON w.id=a.worker_id AND w.status='Active'
  WHERE daterange(a.start_date,a.end_date,'[]') && daterange(p_from,p_until,'[]')),'[]'::jsonb);
END $$;
REVOKE ALL ON FUNCTION public.get_labor_worker_availability(uuid,date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_labor_worker_availability(uuid,date,date) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
