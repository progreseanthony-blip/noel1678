-- Reconcile NEW automatic segments without rewriting recorded historical breaks.
BEGIN;
ALTER TABLE public.report_labor_logs ADD COLUMN break_mode text NOT NULL DEFAULT 'recorded'
 CHECK(break_mode IN ('recorded','auto_daily','manual'));

CREATE FUNCTION app_private.reconcile_daily_breaks(p_section uuid,p_workers uuid[],p_submit boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE day date; worker uuid; gross numeric; fixed numeric; outside_auto numeric;
 required_auto numeric; remaining numeric; amount integer; row record; locked_other boolean; has_auto boolean;
BEGIN
 SELECT d.report_date INTO STRICT day FROM public.daily_reports d
 JOIN public.daily_report_sections s ON s.daily_report_id=d.id WHERE s.id=p_section;
 FOREACH worker IN ARRAY coalesce(p_workers,'{}'::uuid[]) LOOP
  PERFORM pg_advisory_xact_lock(hashtextextended('worker:'||worker||':'||day,0));
  SELECT coalesce(sum(CASE WHEN l.check_out_time>l.check_in_time AND NOT l.is_standby
      THEN extract(epoch FROM l.check_out_time-l.check_in_time)/60 ELSE 0 END),0),
   coalesce(sum(CASE WHEN l.break_mode<>'auto_daily' THEN l.break_minutes ELSE 0 END),0),
   coalesce(sum(CASE WHEN l.break_mode='auto_daily' AND l.section_id IS DISTINCT FROM p_section
      THEN l.break_minutes ELSE 0 END),0),
   coalesce(bool_or(l.section_id IS DISTINCT FROM p_section AND l.break_mode='auto_daily'
      AND (s.status IN ('approved','submitted') OR d.status IN ('approved','submitted'))),false),
   coalesce(bool_or(l.break_mode='auto_daily'),false)
  INTO gross,fixed,outside_auto,locked_other,has_auto
  FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
  LEFT JOIN public.daily_report_sections s ON s.id=l.section_id
  WHERE l.worker_id=worker AND d.report_date=day;
  IF NOT has_auto THEN CONTINUE; END IF;
  required_auto:=greatest(0,CASE WHEN gross>=360 THEN 30 ELSE 0 END-fixed);
  IF outside_auto>required_auto AND (p_submit OR locked_other) THEN
   RAISE EXCEPTION 'The daily break is assigned to another crew report. Reconcile that attendance before submitting';
  END IF;
  remaining:=greatest(0,required_auto-outside_auto);
  FOR row IN SELECT id,check_in_time,check_out_time,is_standby FROM public.report_labor_logs
   WHERE section_id=p_section AND worker_id=worker AND break_mode='auto_daily'
   ORDER BY check_in_time NULLS LAST,id LOOP
   amount:=CASE WHEN row.check_out_time>row.check_in_time AND NOT row.is_standby
    THEN least(remaining,floor(extract(epoch FROM row.check_out_time-row.check_in_time)/60))::int ELSE 0 END;
   UPDATE public.report_labor_logs SET break_minutes=amount WHERE id=row.id;
   remaining:=remaining-amount;
  END LOOP;
  IF remaining>0 AND (p_submit OR locked_other) THEN
   RAISE EXCEPTION 'The daily break must be recorded on the remaining attendance before submitting';
  END IF;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION app_private.reconcile_daily_breaks(uuid,uuid[],boolean) FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.get_daily_break_context(p_project uuid,p_day date,p_crew uuid) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF p_day IS NULL OR p_crew IS NULL OR NOT EXISTS(SELECT 1 FROM public.project_crews
  WHERE id=p_crew AND project_id=p_project) OR NOT coalesce(app_private.can_report(p_project,p_day,p_crew),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN coalesce((WITH allowed AS (
  SELECT m.worker_id FROM public.crew_members m WHERE m.crew_id=p_crew AND m.valid_from<=p_day
   AND (m.valid_until IS NULL OR m.valid_until>=p_day)
  UNION SELECT t.worker_id FROM public.daily_worker_transfers t JOIN public.daily_reports d ON d.id=t.daily_report_id
   WHERE t.to_crew_id=p_crew AND t.status='approved' AND d.project_id=p_project AND d.report_date=p_day
 ), totals AS (
  SELECT a.worker_id,
   coalesce(sum(CASE WHEN l.check_out_time>l.check_in_time AND NOT l.is_standby
    THEN extract(epoch FROM l.check_out_time-l.check_in_time)/60 ELSE 0 END),0) elapsed_minutes,
   coalesce(sum(CASE WHEN l.break_mode<>'auto_daily' THEN l.break_minutes ELSE 0 END),0) fixed_break,
   coalesce(sum(CASE WHEN l.break_mode='auto_daily' THEN l.break_minutes ELSE 0 END),0) auto_break
  FROM allowed a LEFT JOIN public.report_labor_logs l ON l.worker_id=a.worker_id
   AND EXISTS(SELECT 1 FROM public.daily_reports d WHERE d.id=l.daily_report_id AND d.report_date=p_day)
   AND NOT EXISTS(SELECT 1 FROM public.daily_report_sections s JOIN public.daily_reports d ON d.id=s.daily_report_id
    WHERE s.id=l.section_id AND s.crew_id=p_crew AND d.project_id=p_project AND d.report_date=p_day)
  GROUP BY a.worker_id
 ) SELECT jsonb_object_agg(worker_id::text,jsonb_build_object('elapsed_minutes',elapsed_minutes,
   'fixed_break',fixed_break,'auto_break',auto_break)) FROM totals),'{}'::jsonb);
END $$;
REVOKE ALL ON FUNCTION public.get_daily_break_context(uuid,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_daily_break_context(uuid,date,uuid) TO authenticated;

CREATE OR REPLACE FUNCTION app_private.execution_fields(p_table text,p_row jsonb) RETURNS jsonb
 LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT coalesce(jsonb_object_agg(key,value),'{}'::jsonb) FROM jsonb_each(p_row)
 WHERE key=ANY(CASE p_table
 WHEN 'labor' THEN ARRAY['id','daily_report_id','section_id','worker_id','project_labor_id','project_task_id',
  'base_crew_id','execution_crew_id','transfer_id','check_in_time','check_out_time','break_minutes','break_mode','total_net_hours',
  'is_unplanned','deviation_reason_id','notes','is_standby','standby_hours']
 WHEN 'machinery' THEN ARRAY['id','daily_report_id','section_id','machinery_id','project_machinery_id','operator_id',
  'execution_crew_id','machinery_inspection_id','operation_start','operation_end','start_meter','end_meter','total_hours',
  'fuel_added','production_value','production_unit','start_shift_photos','end_shift_photos',
  'is_unplanned','deviation_reason_id','notes','is_standby','standby_hours']
 WHEN 'material' THEN ARRAY['id','daily_report_id','section_id','material_id','project_material_id',
  'execution_crew_id','quantity_used','area_installed','unit','notes','is_waste','waste_reason']
 ELSE ARRAY[]::text[] END)
$$;

CREATE OR REPLACE FUNCTION public.save_daily_report_section(p_section uuid,p_revision integer,p_notes text,
 p_labor jsonb,p_machinery jsonb,p_materials jsonb,p_submit boolean DEFAULT false)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.daily_report_sections; d public.daily_reports; item jsonb; payload jsonb; t text; cols text; rid uuid; affected_workers uuid[]; wid uuid;
BEGIN
 -- Lock parent before section: consistent ordering across save/review/transfer.
 SELECT daily_report_id INTO STRICT rid FROM public.daily_report_sections WHERE id=p_section;
 d:=app_private.lock_execution(rid);
 SELECT * INTO STRICT s FROM public.daily_report_sections WHERE id=p_section FOR UPDATE;
 IF NOT coalesce(app_private.can_report(d.project_id,d.report_date,s.crew_id),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF s.revision<>p_revision THEN RAISE EXCEPTION 'Section changed. Reload before saving' USING ERRCODE='40001'; END IF;
 IF s.status NOT IN ('draft','returned') THEN RAISE EXCEPTION 'Section is locked'; END IF;
 IF jsonb_typeof(p_labor) IS DISTINCT FROM 'array' OR jsonb_typeof(p_machinery) IS DISTINCT FROM 'array'
  OR jsonb_typeof(p_materials) IS DISTINCT FROM 'array' THEN RAISE EXCEPTION 'Resource arrays are required'; END IF;
 IF jsonb_array_length(p_labor)+jsonb_array_length(p_machinery)+jsonb_array_length(p_materials)>1000
 THEN RAISE EXCEPTION 'Too many execution entries'; END IF;
 SELECT array_agg(worker_id ORDER BY worker_id) INTO affected_workers FROM (
  SELECT worker_id FROM public.report_labor_logs WHERE section_id=s.id
  UNION SELECT (value->>'worker_id')::uuid FROM jsonb_array_elements(p_labor)
 ) workers;
 FOREACH wid IN ARRAY coalesce(affected_workers,'{}'::uuid[]) LOOP
  PERFORM pg_advisory_xact_lock(hashtextextended('worker:'||wid||':'||d.report_date,0));
 END LOOP;
 INSERT INTO app_private.execution_writes(transaction_id,section_id,labor_snapshot)
  SELECT txid_current(),s.id,coalesce(jsonb_object_agg(id::text,base_crew_id),'{}'::jsonb)
   FROM public.report_labor_logs WHERE section_id=s.id;
 -- Delete machinery before labor. Validation checks the complete replacement
 -- after labor is inserted, in this same transaction (a failure rolls it all back).
 DELETE FROM public.report_machinery_logs WHERE section_id=s.id;
 DELETE FROM public.report_labor_logs WHERE section_id=s.id;
 DELETE FROM public.report_material_usage WHERE section_id=s.id;
 FOREACH t IN ARRAY ARRAY['report_labor_logs','report_machinery_logs','report_material_usage'] LOOP
  payload:=CASE t WHEN 'report_labor_logs' THEN p_labor WHEN 'report_machinery_logs' THEN p_machinery ELSE p_materials END;
  cols:=CASE t
   WHEN 'report_labor_logs' THEN 'worker_id,project_labor_id,project_task_id,check_in_time,check_out_time,break_minutes,break_mode,is_unplanned,deviation_reason_id,notes,is_standby,standby_hours,transfer_id'
   WHEN 'report_machinery_logs' THEN 'machinery_id,project_machinery_id,operator_id,start_meter,end_meter,total_hours,fuel_added,production_value,production_unit,start_shift_photos,end_shift_photos,is_unplanned,deviation_reason_id,notes,is_standby,standby_hours,machinery_inspection_id,operation_start,operation_end'
   ELSE 'material_id,project_material_id,quantity_used,area_installed,unit,notes,is_waste,waste_reason' END;
  FOR item IN SELECT value FROM jsonb_array_elements(payload) LOOP
   IF jsonb_typeof(item)<>'object' THEN RAISE EXCEPTION 'Each resource must be an object'; END IF;
   -- Keep stable row identity; an ID belonging to another section fails the PK
   -- and rolls back the entire operation. Never accept monetary fields here.
   EXECUTE format('INSERT INTO public.%I(id,daily_report_id,section_id,execution_crew_id,%s)
    SELECT $1,$2,$3,$4,%s FROM jsonb_populate_record(NULL::public.%I,$5)',t,cols,cols,t)
    USING coalesce((item->>'id')::uuid,gen_random_uuid()),d.id,s.id,s.crew_id,
    jsonb_build_object('break_mode','recorded','break_minutes',0,'is_unplanned',false,'is_standby',false,'is_waste',false,
     'fuel_added',0,'total_hours',0,'start_meter',0,'start_shift_photos','[]'::jsonb,'end_shift_photos','[]'::jsonb)||item;
  END LOOP;
 END LOOP;
 PERFORM app_private.reconcile_daily_breaks(s.id,affected_workers,p_submit);
 IF p_submit AND EXISTS(SELECT 1 FROM public.report_labor_logs WHERE section_id=s.id AND check_out_time IS NULL)
 THEN RAISE EXCEPTION 'Finish attendance segments before submission'; END IF;
 -- Replacing attendance cannot invalidate another crew's existing machine work.
 IF EXISTS(SELECT 1 FROM public.report_machinery_logs m WHERE m.daily_report_id=d.id
  AND m.section_id IS NOT NULL AND NOT m.is_standby AND NOT EXISTS(
   SELECT 1 FROM public.report_labor_logs l WHERE l.daily_report_id=d.id AND l.worker_id=m.operator_id
   AND l.execution_crew_id IS NOT DISTINCT FROM m.execution_crew_id
   AND l.check_in_time<=m.operation_start AND l.check_out_time>=m.operation_end))
 THEN RAISE EXCEPTION 'Attendance changes would invalidate recorded machine operation'; END IF;
 UPDATE public.daily_report_sections SET notes=coalesce(p_notes,''),revision=revision+1,
  last_saved_by=auth.uid(),
  status=CASE WHEN p_submit THEN 'submitted' ELSE 'draft' END,reviewed_by=NULL,reviewed_at=NULL,
  review_notes=NULL,updated_at=now() WHERE id=s.id RETURNING * INTO s;
 DELETE FROM app_private.execution_writes WHERE transaction_id=txid_current() AND section_id=s.id;
 RETURN to_jsonb(s);
END $$;


-- Admin financial calculation consumes the SAME classified rows as operational hours.
CREATE FUNCTION public.get_labor_payroll_data(p_project uuid,p_start date,p_end date) RETURNS jsonb
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE data jsonb; priced jsonb; machinery jsonb;
BEGIN
 IF NOT app_private.is_admin() THEN RAISE EXCEPTION 'Administrator access required'; END IF;
 data:=public.get_labor_hours(p_project,p_start,p_end,NULL);
 SELECT coalesce(jsonb_agg(r.value || jsonb_build_object('hourly_rate',coalesce(role.hourly_rate,0),
  'role_id',w.role_id) ORDER BY r.value->>'date',r.value->>'check_in',r.value->>'id'),'[]'::jsonb)
 INTO priced FROM jsonb_array_elements(data->'rows') r
 JOIN public.workers w ON w.id=(r.value->>'worker_id')::uuid
 LEFT JOIN public.labor_roles role ON role.id=w.role_id
 WHERE (r.value->>'validated')::boolean;
 SELECT coalesce(jsonb_agg(jsonb_build_object('operator_id',m.operator_id,
  'total_hours',m.total_hours,'rate_override',m.rate_override)),'[]'::jsonb)
 INTO machinery FROM public.report_machinery_logs m JOIN public.daily_reports d ON d.id=m.daily_report_id
 LEFT JOIN public.daily_report_sections s ON s.id=m.section_id
 WHERE d.project_id=p_project AND d.report_date BETWEEN p_start AND p_end
 AND m.rate_override IS NOT NULL AND CASE WHEN s.id IS NOT NULL
  THEN s.status='approved' AND d.status<>'rejected' ELSE d.status='approved' END;
 RETURN jsonb_build_object('rows',priced,'machinery',machinery);
END $$;
REVOKE ALL ON FUNCTION public.get_labor_payroll_data(uuid,date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_labor_payroll_data(uuid,date,date) TO authenticated;

CREATE FUNCTION app_private.guard_closed_payroll() RETURNS trigger
LANGUAGE plpgsql SET search_path='' AS $$
BEGIN
 IF OLD.status='closed' THEN RAISE EXCEPTION 'Closed payroll periods are read-only'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 RETURN NEW;
END $$;
REVOKE ALL ON FUNCTION app_private.guard_closed_payroll() FROM PUBLIC,anon,authenticated;
CREATE TRIGGER protect_closed_payroll BEFORE UPDATE OR DELETE ON public.payroll_periods
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_closed_payroll();
NOTIFY pgrst,'reload schema';
COMMIT;
