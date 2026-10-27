BEGIN;
CREATE FUNCTION public.get_daily_transfer_context(p_project uuid,p_day date,p_crew uuid DEFAULT NULL)
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF p_day IS NULL OR NOT coalesce(app_private.can_report(p_project,p_day,p_crew),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF p_crew IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=p_crew AND project_id=p_project)
 THEN RAISE EXCEPTION 'Crew belongs to a different project'; END IF;
 RETURN jsonb_build_object(
  'crews',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'name',name) ORDER BY name)
   FROM public.project_crews WHERE project_id=p_project AND active),'[]'::jsonb),
  'labor',coalesce((SELECT jsonb_agg(jsonb_build_object('id',l.id,'role_name',coalesce(l.role_name,lr.description,'Worker'),
   'service_name',coalesce(q.name,ps.name,'Unassigned'),
   'crew_ids',coalesce((SELECT jsonb_agg(c.id) FROM public.project_crews c
    WHERE c.project_id=p_project AND c.active AND (
     NOT EXISTS(SELECT 1 FROM public.crew_service_assignments s WHERE s.crew_id=c.id)
     OR EXISTS(SELECT 1 FROM public.crew_service_assignments s WHERE s.crew_id=c.id
      AND s.service_key=app_private.labor_service_key(l) AND s.valid_from<=p_day AND s.valid_until>=p_day))),'[]'::jsonb)))
   FROM public.project_labor l LEFT JOIN public.quote_services q ON q.id=l.quote_service_id
   LEFT JOIN public.project_services ps ON ps.id=l.project_service_id
   LEFT JOIN public.labor_roles lr ON lr.id=l.role_id
   WHERE l.project_id=p_project),'[]'::jsonb),
  'transfers',coalesce((SELECT jsonb_agg(jsonb_build_object('id',t.id,'worker_id',t.worker_id,
   'worker_name',w.full_name,'from_crew_id',t.from_crew_id,'from_name',a.name,
   'to_crew_id',t.to_crew_id,'to_name',b.name,'project_labor_id',t.project_labor_id,
   'starts_at',t.starts_at,'ends_at',t.ends_at,'reason',t.reason,'status',t.status,
   'requested_by',t.requested_by,'decision_notes',t.decision_notes) ORDER BY t.starts_at,t.id)
   FROM public.daily_worker_transfers t JOIN public.daily_reports d ON d.id=t.daily_report_id
   JOIN public.workers w ON w.id=t.worker_id
   JOIN public.project_crews a ON a.id=t.from_crew_id JOIN public.project_crews b ON b.id=t.to_crew_id
   WHERE d.project_id=p_project AND d.report_date=p_day
    AND (app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p_project,p_day))
     OR t.from_crew_id=p_crew OR t.to_crew_id=p_crew)),'[]'::jsonb));
END $$;

REVOKE ALL ON FUNCTION public.get_daily_transfer_context(uuid,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_daily_transfer_context(uuid,date,uuid) TO authenticated;
CREATE OR REPLACE FUNCTION public.request_daily_worker_transfer(p_report uuid,p_worker uuid,p_to_crew uuid,
 p_labor uuid,p_start time,p_end time,p_reason text)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.daily_reports; base uuid; tid uuid; BEGIN
 d:=app_private.lock_execution(p_report);
 SELECT m.crew_id INTO base FROM public.crew_members m JOIN public.project_crews c ON c.id=m.crew_id
  WHERE m.worker_id=p_worker AND c.project_id=d.project_id AND m.valid_from<=d.report_date
   AND (m.valid_until IS NULL OR m.valid_until>=d.report_date);
 IF base IS NULL OR NOT coalesce(app_private.can_report(d.project_id,d.report_date,base),false)
 THEN RAISE EXCEPTION 'Only the origin leader or assigned supervisor may request a loan'; END IF;
 IF p_start IS NULL OR p_end IS NULL OR p_end<=p_start THEN RAISE EXCEPTION 'Invalid loan interval'; END IF;
 IF p_to_crew=base OR NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=p_to_crew AND project_id=d.project_id AND active)
  OR NOT EXISTS(SELECT 1 FROM public.project_labor WHERE id=p_labor AND project_id=d.project_id)
 THEN RAISE EXCEPTION 'Destination crew and labor must belong to this project'; END IF;
 IF EXISTS(SELECT 1 FROM public.crew_service_assignments WHERE crew_id=p_to_crew)
 AND NOT EXISTS(SELECT 1 FROM public.crew_service_assignments s JOIN public.project_labor l
  ON l.id=p_labor AND s.service_key=app_private.labor_service_key(l)
  WHERE s.crew_id=p_to_crew AND s.valid_from<=d.report_date AND s.valid_until>=d.report_date)
 THEN RAISE EXCEPTION 'The destination service is not planned for this crew on the report date'; END IF;
 SELECT id INTO tid FROM public.daily_worker_transfers WHERE daily_report_id=d.id
  AND worker_id=p_worker AND from_crew_id=base AND to_crew_id=p_to_crew AND project_labor_id=p_labor
  AND starts_at=p_start AND ends_at=p_end AND reason=p_reason AND status='pending';
 IF tid IS NOT NULL THEN RETURN tid; END IF;
 INSERT INTO public.daily_worker_transfers(daily_report_id,worker_id,from_crew_id,to_crew_id,project_labor_id,starts_at,ends_at,reason)
  VALUES(d.id,p_worker,base,p_to_crew,p_labor,p_start,p_end,p_reason) RETURNING id INTO tid;
 RETURN tid;
END $$;
NOTIFY pgrst,'reload schema';
COMMIT;
