-- Phase 1: canonical execution records inside the existing daily report.
-- Additive: existing reports retain their identity, values and approval state.
BEGIN;

CREATE TABLE public.daily_report_sections (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id),
 crew_id uuid REFERENCES public.project_crews(id),
 created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
 last_saved_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','submitted','returned','approved')),
 notes text NOT NULL DEFAULT '',
 revision integer NOT NULL DEFAULT 0 CHECK(revision>=0),
 reviewed_by uuid REFERENCES public.profiles(id),
 reviewed_at timestamptz,
 review_notes text,
 created_at timestamptz NOT NULL DEFAULT now(),
 updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE NULLS NOT DISTINCT(daily_report_id,crew_id)
);

-- A loan changes execution responsibility for an interval, never crew membership.
CREATE TABLE public.daily_worker_transfers (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id),
 worker_id uuid NOT NULL REFERENCES public.workers(id),
 from_crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 to_crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 project_labor_id uuid NOT NULL REFERENCES public.project_labor(id),
 starts_at time NOT NULL,
 ends_at time NOT NULL,
 reason text NOT NULL CHECK(length(trim(reason))>0),
 status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','approved','rejected','cancelled')),
 requested_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
 authorized_by uuid REFERENCES public.profiles(id),
 authorized_at timestamptz,
 decision_notes text,
 created_at timestamptz NOT NULL DEFAULT now(),
 CHECK(from_crew_id<>to_crew_id),
 CHECK(ends_at>starts_at)
);

ALTER TABLE public.report_labor_logs
 ADD COLUMN section_id uuid REFERENCES public.daily_report_sections(id),
 ADD COLUMN base_crew_id uuid REFERENCES public.project_crews(id),
 ADD COLUMN execution_crew_id uuid REFERENCES public.project_crews(id),
 ADD COLUMN transfer_id uuid REFERENCES public.daily_worker_transfers(id);
ALTER TABLE public.report_machinery_logs
 ADD COLUMN section_id uuid REFERENCES public.daily_report_sections(id),
 ADD COLUMN execution_crew_id uuid REFERENCES public.project_crews(id),
 ADD COLUMN machinery_inspection_id uuid REFERENCES public.machinery_inspections(id),
 ADD COLUMN operation_start time,
 ADD COLUMN operation_end time;
ALTER TABLE public.report_machinery_logs ALTER COLUMN operator_id DROP NOT NULL;
ALTER TABLE public.report_machinery_logs ADD CONSTRAINT operating_machine_requires_operator
 CHECK(is_standby OR operator_id IS NOT NULL);
ALTER TABLE public.report_material_usage
 ADD COLUMN section_id uuid REFERENCES public.daily_report_sections(id),
 ADD COLUMN execution_crew_id uuid REFERENCES public.project_crews(id);
CREATE INDEX ON public.report_labor_logs(section_id);
CREATE INDEX ON public.report_machinery_logs(section_id);
CREATE INDEX ON public.report_material_usage(section_id);
CREATE INDEX ON public.daily_worker_transfers(daily_report_id,worker_id);

-- Transaction-scoped capability, inaccessible to API clients. Do not use a GUC:
-- clients may be able to set GUCs through other routines.
CREATE TABLE app_private.execution_writes (
 transaction_id bigint NOT NULL,
 section_id uuid NOT NULL,
 labor_snapshot jsonb NOT NULL DEFAULT '{}',
 PRIMARY KEY(transaction_id,section_id)
);
REVOKE ALL ON app_private.execution_writes FROM PUBLIC,anon,authenticated;

CREATE FUNCTION app_private.can_report(p_project uuid,p_day date,p_crew uuid)
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT app_private.is_admin() OR
  (app_private.role()='Supervisor' AND app_private.project_access(p_project,p_day)) OR
  (p_crew IS NOT NULL AND app_private.leads(p_crew,p_day) AND EXISTS(
   SELECT 1 FROM public.project_crews WHERE id=p_crew AND project_id=p_project))
$$;

CREATE FUNCTION app_private.lock_execution(p_report uuid) RETURNS public.daily_reports
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r public.daily_reports; BEGIN
 SELECT * INTO STRICT r FROM public.daily_reports WHERE id=p_report FOR UPDATE;
 IF r.status NOT IN ('draft','rejected') THEN RAISE EXCEPTION 'Report is locked'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id=r.project_id AND status='active')
 THEN RAISE EXCEPTION 'Only active projects accept execution changes'; END IF;
 RETURN r;
END $$;

ALTER TABLE public.daily_report_sections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_worker_transfers ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.daily_report_sections,public.daily_worker_transfers TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.daily_report_sections,public.daily_worker_transfers FROM authenticated,anon;
CREATE POLICY section_read ON public.daily_report_sections FOR SELECT TO authenticated USING (
 EXISTS(SELECT 1 FROM public.daily_reports d WHERE d.id=daily_report_id
 AND app_private.can_report(d.project_id,d.report_date,crew_id)));
-- Foreman reads through the sanitized workspace, since direct daily_reports RLS
-- deliberately does not grant Foreman access to financial/nested joins.
CREATE POLICY transfer_read ON public.daily_worker_transfers FOR SELECT TO authenticated USING (
 EXISTS(SELECT 1 FROM public.daily_reports d WHERE d.id=daily_report_id AND
 (app_private.can_report(d.project_id,d.report_date,from_crew_id) OR
 app_private.can_report(d.project_id,d.report_date,to_crew_id))));

CREATE FUNCTION app_private.guard_execution_log() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE r jsonb; old_section uuid; s public.daily_report_sections; d public.daily_reports;
 base uuid; start_t time; end_t time; elapsed numeric;
BEGIN
 r:=CASE WHEN TG_OP='DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
 IF TG_OP<>'INSERT' THEN old_section:=(to_jsonb(OLD)->>'section_id')::uuid; END IF;
 IF r->>'section_id' IS NULL AND old_section IS NULL THEN
  PERFORM 1 FROM public.daily_reports WHERE id=(r->>'daily_report_id')::uuid FOR UPDATE;
  -- Also close the legacy INSERT hole: a locked parent's children are immutable.
  IF EXISTS(SELECT 1 FROM public.daily_reports WHERE id=(r->>'daily_report_id')::uuid
   AND status IN ('submitted','approved')) THEN RAISE EXCEPTION 'Report is locked'; END IF;
  IF EXISTS(SELECT 1 FROM public.daily_report_sections WHERE daily_report_id=(r->>'daily_report_id')::uuid)
  THEN RAISE EXCEPTION 'This daily report uses atomic section saves'; END IF;
  IF TG_OP='DELETE' THEN RETURN OLD; END IF;
  IF TG_TABLE_NAME='report_labor_logs' AND EXISTS(
   SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports dr ON dr.id=l.daily_report_id
   JOIN public.daily_reports own ON own.id=(r->>'daily_report_id')::uuid
   WHERE l.section_id IS NOT NULL AND l.worker_id=(r->>'worker_id')::uuid AND l.id<>(r->>'id')::uuid
    AND dr.report_date=own.report_date AND tsrange(own.report_date+l.check_in_time,
     own.report_date+coalesce(l.check_out_time,'24:00'::time),'[)') &&
     tsrange(own.report_date+(r->>'check_in_time')::time,
      own.report_date+coalesce((r->>'check_out_time')::time,'24:00'::time),'[)'))
  THEN RAISE EXCEPTION 'Worker has overlapping canonical execution'; END IF;
  IF TG_TABLE_NAME='report_machinery_logs' AND NOT coalesce((r->>'is_standby')::boolean,false) AND EXISTS(
   SELECT 1 FROM public.report_machinery_logs m JOIN public.daily_reports dr ON dr.id=m.daily_report_id
   JOIN public.daily_reports own ON own.id=(r->>'daily_report_id')::uuid
   WHERE m.section_id IS NOT NULL AND m.id<>(r->>'id')::uuid AND dr.report_date=own.report_date
    AND NOT m.is_standby AND (m.operator_id=(r->>'operator_id')::uuid
     OR m.project_machinery_id=(r->>'project_machinery_id')::uuid))
  THEN RAISE EXCEPTION 'Use timed canonical entries to share this machine or operator'; END IF;
  RETURN NEW;
 END IF;
 IF TG_OP='UPDATE' AND (r->>'section_id')::uuid IS DISTINCT FROM old_section
 THEN RAISE EXCEPTION 'Execution section cannot be changed'; END IF;
 SELECT * INTO STRICT s FROM public.daily_report_sections
  WHERE id=coalesce(old_section,(r->>'section_id')::uuid);
 IF NOT EXISTS(SELECT 1 FROM app_private.execution_writes WHERE transaction_id=txid_current() AND section_id=s.id)
 THEN RAISE EXCEPTION 'Use the atomic section save operation'; END IF;
 d:=app_private.lock_execution(s.daily_report_id);
 IF s.status NOT IN ('draft','returned') THEN RAISE EXCEPTION 'Section is locked'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 IF (r->>'daily_report_id')::uuid<>s.daily_report_id OR
  (r->>'execution_crew_id')::uuid IS DISTINCT FROM s.crew_id
 THEN RAISE EXCEPTION 'Section, report and execution crew must agree'; END IF;
 IF s.crew_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews
  WHERE id=s.crew_id AND project_id=d.project_id AND active)
 THEN RAISE EXCEPTION 'Invalid execution crew'; END IF;

 IF TG_TABLE_NAME='report_labor_logs' THEN
  PERFORM pg_advisory_xact_lock(hashtextextended('worker:'||(r->>'worker_id')||':'||d.report_date,0));
  start_t:=(r->>'check_in_time')::time; end_t:=(r->>'check_out_time')::time;
  IF start_t IS NULL OR (end_t IS NOT NULL AND end_t<=start_t)
  THEN RAISE EXCEPTION 'A segment must start and end within the same day'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.project_labor l WHERE l.id=NEW.project_labor_id AND l.project_id=d.project_id)
  THEN RAISE EXCEPTION 'Labor service must belong to the report project'; END IF;
  SELECT m.crew_id INTO base FROM public.crew_members m JOIN public.project_crews c ON c.id=m.crew_id
   WHERE m.worker_id=NEW.worker_id AND c.project_id=d.project_id AND m.valid_from<=d.report_date
    AND (m.valid_until IS NULL OR m.valid_until>=d.report_date);
  IF TG_OP='UPDATE' AND NEW.base_crew_id IS DISTINCT FROM OLD.base_crew_id
  THEN RAISE EXCEPTION 'Base crew is a historical snapshot'; END IF;
  IF TG_OP='INSERT' AND EXISTS(SELECT 1 FROM app_private.execution_writes
   WHERE transaction_id=txid_current() AND section_id=s.id AND labor_snapshot ? NEW.id::text) THEN
   SELECT (labor_snapshot->>NEW.id::text)::uuid INTO base FROM app_private.execution_writes
    WHERE transaction_id=txid_current() AND section_id=s.id;
  END IF;
  NEW.base_crew_id:=CASE WHEN TG_OP='UPDATE' THEN OLD.base_crew_id ELSE base END;
  IF s.crew_id IS DISTINCT FROM base THEN
   IF s.crew_id IS NULL OR base IS NULL OR NOT EXISTS(
    SELECT 1 FROM public.daily_worker_transfers t WHERE t.id=NEW.transfer_id AND t.status='approved'
    AND t.daily_report_id=d.id AND t.worker_id=NEW.worker_id AND t.from_crew_id=base
    AND t.to_crew_id=s.crew_id AND t.project_labor_id=NEW.project_labor_id
    AND t.starts_at<=start_t AND end_t IS NOT NULL AND t.ends_at>=end_t)
   THEN RAISE EXCEPTION 'Execution outside the base crew requires an authorized loan'; END IF;
  ELSIF NEW.transfer_id IS NOT NULL THEN RAISE EXCEPTION 'A base-crew segment cannot reference a loan'; END IF;
  IF EXISTS(SELECT 1 FROM public.daily_worker_transfers t WHERE t.daily_report_id=d.id
   AND t.worker_id=NEW.worker_id AND t.status='approved' AND t.id IS DISTINCT FROM NEW.transfer_id
   AND tsrange(d.report_date+t.starts_at,d.report_date+t.ends_at,'[)') &&
    tsrange(d.report_date+start_t,d.report_date+coalesce(end_t,'24:00'::time),'[)'))
  THEN RAISE EXCEPTION 'Worker is reserved for an authorized loan in this interval'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
   WHERE a.worker_id=NEW.worker_id AND l.project_id=d.project_id
   AND (a.start_date IS NULL OR a.start_date<=d.report_date) AND (a.end_date IS NULL OR a.end_date>=d.report_date))
  THEN RAISE EXCEPTION 'Worker must be planned in this project on the report day'; END IF;
  IF EXISTS(SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports dr ON dr.id=l.daily_report_id
   WHERE l.worker_id=NEW.worker_id AND l.id<>NEW.id AND dr.report_date=d.report_date
   AND tsrange(d.report_date+l.check_in_time,d.report_date+coalesce(l.check_out_time,'24:00'::time),'[)') &&
    tsrange(d.report_date+start_t,d.report_date+coalesce(end_t,'24:00'::time),'[)'))
  THEN RAISE EXCEPTION 'Worker has overlapping execution segments'; END IF;
  IF end_t IS NULL THEN
   NEW.total_net_hours:=0; NEW.regular_hours:=0; NEW.overtime_hours:=0;
  ELSE
   elapsed:=extract(epoch FROM end_t-start_t)/60;
   IF NEW.break_minutes IS NULL OR NEW.break_minutes<0 OR NEW.break_minutes>elapsed
   THEN RAISE EXCEPTION 'Invalid segment break'; END IF;
   NEW.total_net_hours:=(elapsed-NEW.break_minutes)/60;
   -- These daily display values are not payroll's weekly classification.
   NEW.regular_hours:=least(8,NEW.total_net_hours);
   NEW.overtime_hours:=greatest(0,NEW.total_net_hours-8);
  END IF;
 ELSIF TG_TABLE_NAME='report_machinery_logs' THEN
  IF NOT EXISTS(SELECT 1 FROM public.project_machinery WHERE id=NEW.project_machinery_id
   AND project_id=d.project_id AND machinery_id=NEW.machinery_id)
  THEN RAISE EXCEPTION 'Machine must be planned in this project'; END IF;
  IF NEW.is_standby THEN
   IF coalesce(NEW.standby_hours,0)<0 THEN RAISE EXCEPTION 'Invalid standby hours'; END IF;
  ELSE
   start_t:=NEW.operation_start; end_t:=NEW.operation_end;
   IF start_t IS NULL OR end_t IS NULL OR end_t<=start_t OR NEW.machinery_inspection_id IS NULL OR NEW.operator_id IS NULL
   THEN RAISE EXCEPTION 'Physical machine, operator and operating interval are required'; END IF;
   PERFORM pg_advisory_xact_lock(hashtextextended('unit:'||NEW.machinery_inspection_id||':'||d.report_date,0));
   PERFORM pg_advisory_xact_lock(hashtextextended('operator:'||NEW.operator_id||':'||d.report_date,0));
   IF NOT EXISTS(SELECT 1 FROM public.machinery_inspections i WHERE i.id=NEW.machinery_inspection_id
    AND i.project_machinery_id=NEW.project_machinery_id
    AND coalesce(i.reception_date,i.received_at::date)<=d.report_date
    AND (i.returned_at IS NULL OR i.returned_at::date>d.report_date))
   THEN RAISE EXCEPTION 'Physical machine is not available for this resource/day'; END IF;
   IF NEW.start_meter IS NULL OR NEW.end_meter IS NULL OR NEW.end_meter<NEW.start_meter
   THEN RAISE EXCEPTION 'Invalid hour meter readings'; END IF;
   NEW.total_hours:=NEW.end_meter-NEW.start_meter;
   IF NEW.total_hours>extract(epoch FROM end_t-start_t)/3600
   THEN RAISE EXCEPTION 'Meter hours exceed operating interval'; END IF;
   IF EXISTS(SELECT 1 FROM public.report_machinery_logs m JOIN public.daily_reports dr ON dr.id=m.daily_report_id
    WHERE m.id<>NEW.id AND dr.report_date=d.report_date AND NOT m.is_standby
    AND (m.machinery_inspection_id=NEW.machinery_inspection_id OR m.operator_id=NEW.operator_id
     OR (m.machinery_inspection_id IS NULL AND m.project_machinery_id=NEW.project_machinery_id))
    AND (m.operation_start IS NULL OR m.operation_end IS NULL OR
     tsrange(d.report_date+m.operation_start,d.report_date+m.operation_end,'[)') &&
     tsrange(d.report_date+start_t,d.report_date+end_t,'[)')))
   THEN RAISE EXCEPTION 'Physical machine or operator already occupied in this interval'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.report_labor_logs l WHERE l.daily_report_id=d.id
    AND l.worker_id=NEW.operator_id AND l.execution_crew_id IS NOT DISTINCT FROM s.crew_id
    AND l.check_in_time<=start_t AND l.check_out_time>=end_t)
   THEN RAISE EXCEPTION 'Operator attendance must cover the machine interval in this crew'; END IF;
  END IF;
 ELSE
  IF NOT EXISTS(SELECT 1 FROM public.project_materials WHERE id=NEW.project_material_id
   AND project_id=d.project_id AND material_id=NEW.material_id) OR NEW.quantity_used<0
  THEN RAISE EXCEPTION 'Invalid planned material or quantity'; END IF;
 END IF;
 RETURN NEW;
END $$;

DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['report_labor_logs','report_machinery_logs','report_material_usage'] LOOP
  EXECUTE format('CREATE TRIGGER guard_execution_log BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION app_private.guard_execution_log()',t);
 END LOOP;
END $$;

CREATE FUNCTION public.open_daily_report_section(p_project uuid,p_day date,p_crew uuid DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.daily_reports; s public.daily_report_sections; BEGIN
 IF NOT coalesce(app_private.can_report(p_project,p_day,p_crew),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF p_crew IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=p_crew AND project_id=p_project AND active)
 THEN RAISE EXCEPTION 'Invalid crew'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id=p_project AND status='active')
 THEN RAISE EXCEPTION 'Project is read only'; END IF;
 PERFORM pg_advisory_xact_lock(hashtextextended('report:'||p_project||':'||p_day,0));
 SELECT * INTO d FROM public.daily_reports WHERE project_id=p_project AND report_date=p_day;
 IF d.id IS NULL THEN
  INSERT INTO public.daily_reports(project_id,report_date,supervisor_id,status)
   VALUES(p_project,p_day,auth.uid(),'draft') RETURNING * INTO d;
 END IF;
 PERFORM app_private.lock_execution(d.id);
 INSERT INTO public.daily_report_sections(daily_report_id,crew_id)
  VALUES(d.id,p_crew) ON CONFLICT(daily_report_id,crew_id) DO NOTHING;
 SELECT * INTO STRICT s FROM public.daily_report_sections WHERE daily_report_id=d.id AND crew_id IS NOT DISTINCT FROM p_crew;
 RETURN to_jsonb(s);
END $$;

-- Explicit field lists protect API responses, not just the screen. A new column
-- on a source table must not silently become visible to operational accounts.
CREATE FUNCTION app_private.execution_fields(p_table text,p_row jsonb) RETURNS jsonb
 LANGUAGE sql IMMUTABLE SET search_path='' AS $$
 SELECT coalesce(jsonb_object_agg(key,value),'{}'::jsonb) FROM jsonb_each(p_row)
 WHERE key=ANY(CASE p_table
 WHEN 'labor' THEN ARRAY['id','daily_report_id','section_id','worker_id','project_labor_id','project_task_id',
  'base_crew_id','execution_crew_id','transfer_id','check_in_time','check_out_time','break_minutes','total_net_hours',
  'is_unplanned','deviation_reason_id','notes','is_standby','standby_hours']
 WHEN 'machinery' THEN ARRAY['id','daily_report_id','section_id','machinery_id','project_machinery_id','operator_id',
  'execution_crew_id','machinery_inspection_id','operation_start','operation_end','start_meter','end_meter','total_hours',
  'fuel_added','production_value','production_unit','start_shift_photos','end_shift_photos',
  'is_unplanned','deviation_reason_id','notes','is_standby','standby_hours']
 WHEN 'material' THEN ARRAY['id','daily_report_id','section_id','material_id','project_material_id',
  'execution_crew_id','quantity_used','area_installed','unit','notes','is_waste','waste_reason']
 ELSE ARRAY[]::text[] END)
$$;

CREATE FUNCTION public.get_daily_execution_workspace(p_project uuid,p_day date,p_crew uuid DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE d public.daily_reports; s public.daily_report_sections; roster jsonb; BEGIN
 IF NOT coalesce(app_private.can_report(p_project,p_day,p_crew),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF p_crew IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=p_crew AND project_id=p_project)
 THEN RAISE EXCEPTION 'Crew belongs to a different project'; END IF;
 SELECT * INTO d FROM public.daily_reports WHERE project_id=p_project AND report_date=p_day;
 SELECT * INTO s FROM public.daily_report_sections WHERE daily_report_id=d.id AND crew_id IS NOT DISTINCT FROM p_crew;
 SELECT coalesce(jsonb_agg(jsonb_build_object('id',w.id,'full_name',w.full_name,'id_number',w.id_number,
  'role_id',w.role_id,'status',w.status,'labor_roles',jsonb_build_object('id',r.id,'description',r.description)) ORDER BY w.full_name),'[]'::jsonb)
 INTO roster FROM public.workers w LEFT JOIN public.labor_roles r ON r.id=w.role_id
 WHERE EXISTS(SELECT 1 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
  WHERE a.worker_id=w.id AND l.project_id=p_project AND (a.start_date IS NULL OR a.start_date<=p_day)
  AND (a.end_date IS NULL OR a.end_date>=p_day)) AND
 (p_crew IS NULL OR EXISTS(SELECT 1 FROM public.crew_members m WHERE m.worker_id=w.id AND m.crew_id=p_crew
  AND m.valid_from<=p_day AND (m.valid_until IS NULL OR m.valid_until>=p_day)) OR
  EXISTS(SELECT 1 FROM public.daily_worker_transfers t WHERE t.daily_report_id=d.id AND t.worker_id=w.id
   AND t.to_crew_id=p_crew AND t.status='approved'));
 RETURN jsonb_build_object(
  'project', (SELECT jsonb_build_object('id',id,'title',title,'status',status) FROM public.projects WHERE id=p_project),
  'report',CASE WHEN d.id IS NULL THEN NULL ELSE jsonb_build_object('id',d.id,'project_id',d.project_id,
   'report_date',d.report_date,'status',d.status,'weather_condition',d.weather_condition,
   'day_type',d.day_type,'stopped_at',d.stopped_at,'general_notes',d.general_notes) END,
  'section',CASE WHEN s.id IS NULL THEN NULL ELSE to_jsonb(s) END,
  'crews',coalesce((SELECT jsonb_agg(jsonb_build_object('id',c.id,'name',c.name) ORDER BY c.name)
   FROM public.project_crews c WHERE c.project_id=p_project AND c.active
    AND app_private.can_report(p_project,p_day,c.id)),'[]'::jsonb),
  'sections',coalesce((SELECT jsonb_agg(to_jsonb(x) ORDER BY x.created_at) FROM public.daily_report_sections x
   WHERE x.daily_report_id=d.id AND app_private.can_report(p_project,p_day,x.crew_id)),'[]'::jsonb),
  'workers',roster,
  'labor',coalesce((SELECT jsonb_agg(app_private.execution_fields('labor',to_jsonb(l)) ORDER BY l.check_in_time,l.id)
   FROM public.report_labor_logs l WHERE l.section_id=s.id),'[]'::jsonb),
  'machinery',coalesce((SELECT jsonb_agg(app_private.execution_fields('machinery',to_jsonb(m)) ORDER BY m.operation_start,m.id)
   FROM public.report_machinery_logs m WHERE m.section_id=s.id),'[]'::jsonb),
  'materials',coalesce((SELECT jsonb_agg(app_private.execution_fields('material',to_jsonb(m)) ORDER BY m.id)
   FROM public.report_material_usage m WHERE m.section_id=s.id),'[]'::jsonb),
  'transfers',coalesce((SELECT jsonb_agg(to_jsonb(t) ORDER BY t.starts_at) FROM public.daily_worker_transfers t
   WHERE t.daily_report_id=d.id AND (p_crew IS NULL OR t.from_crew_id=p_crew OR t.to_crew_id=p_crew)),'[]'::jsonb),
  'planned_labor',coalesce((SELECT jsonb_agg(jsonb_build_object('id',l.id,'role_id',l.role_id,
   'role_name',l.role_name,'quote_service_id',l.quote_service_id,'quote_services',jsonb_build_object('name',qs.name),
   'labor_roles',jsonb_build_object('id',lr.id,'description',lr.description),
   'project_labor_assignments',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'worker_id',a.worker_id,
    'start_date',a.start_date,'end_date',a.end_date,'workers',w.value))
    FROM public.project_labor_assignments a JOIN jsonb_array_elements(roster) w ON w.value->>'id'=a.worker_id::text
    WHERE a.project_labor_id=l.id AND (a.start_date IS NULL OR a.start_date<=p_day)
    AND (a.end_date IS NULL OR a.end_date>=p_day)),'[]'::jsonb)))
   FROM public.project_labor l LEFT JOIN public.quote_services qs ON qs.id=l.quote_service_id
   LEFT JOIN public.labor_roles lr ON lr.id=l.role_id WHERE l.project_id=p_project),'[]'::jsonb),
  'planned_machinery',coalesce((SELECT jsonb_agg(jsonb_build_object('id',m.id,'machinery_id',m.machinery_id,
   'machinery_name',m.machinery_name,'expected_quantity',m.expected_quantity,
   'received_quantity',m.received_quantity,'quote_service_id',m.quote_service_id,
   'is_principal',m.is_principal,'parent_machinery_id',m.parent_machinery_id,'start_date',m.start_date,'end_date',m.end_date,
   'calculation_metadata',jsonb_build_object(
    'capacity',coalesce(m.calculation_metadata->'capacity',to_jsonb(est.capacity_per_trip),'0'::jsonb),
    'trips_per_day',coalesce(m.calculation_metadata->'trips_per_day',to_jsonb(est.trips_per_day),'0'::jsonb),
    'performance_per_day',coalesce(m.calculation_metadata->'performance_per_day',to_jsonb(est.performance_per_day),'0'::jsonb)),
   'quote_services',jsonb_build_object('name',qs.name,'unit_of_measure',qs.unit_of_measure),
   'machinery',jsonb_build_object('id',cat.id,'description',cat.description,'operator_role_id',cat.operator_role_id,
    'capacity_yards',cat.capacity_yards,'fuel_gallons',cat.fuel_gallons,'machinery_type',cat.machinery_type),
   'machinery_inspections',coalesce((SELECT jsonb_agg(jsonb_build_object('id',i.id,'internal_id',i.internal_id,
    'internal_code',i.internal_code,'reception_date',i.reception_date,'returned_at',i.returned_at))
    FROM public.machinery_inspections i WHERE i.project_machinery_id=m.id
     AND coalesce(i.reception_date,i.received_at::date)<=p_day AND (i.returned_at IS NULL OR i.returned_at::date>p_day)),'[]'::jsonb)))
   FROM public.project_machinery m LEFT JOIN public.machinery cat ON cat.id=m.machinery_id
   LEFT JOIN public.quote_services qs ON qs.id=m.quote_service_id
   LEFT JOIN LATERAL(SELECT er.capacity_per_trip,er.trips_per_day,er.performance_per_day
    FROM public.quote_service_estimations e JOIN public.quote_service_estimation_resources er ON er.estimation_id=e.id
    WHERE e.quote_service_id=m.quote_service_id AND er.machine_id=m.machinery_id ORDER BY e.id,er.id LIMIT 1) est ON true
   WHERE m.project_id=p_project
    AND (m.start_date IS NULL OR m.start_date<=p_day) AND (m.end_date IS NULL OR m.end_date>=p_day)),'[]'::jsonb),
  'planned_materials',coalesce((SELECT jsonb_agg(jsonb_build_object('id',m.id,'material_id',m.material_id,
   'material_name',m.material_name,'expected_quantity',m.expected_quantity,'quote_service_id',m.quote_service_id,'quote_services',jsonb_build_object('name',qs.name),
   'materials',jsonb_build_object('description',cat.description,'unit',cat.unit)))
   FROM public.project_materials m LEFT JOIN public.materials cat ON cat.id=m.material_id
   LEFT JOIN public.quote_services qs ON qs.id=m.quote_service_id WHERE m.project_id=p_project),'[]'::jsonb),
  'deviation_reasons',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'code',code,'description',description,'category',category))
   FROM public.deviation_reasons),'[]'::jsonb));
END $$;

CREATE FUNCTION public.save_daily_report_section(p_section uuid,p_revision integer,p_notes text,
 p_labor jsonb,p_machinery jsonb,p_materials jsonb,p_submit boolean DEFAULT false)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.daily_report_sections; d public.daily_reports; item jsonb; payload jsonb; t text; cols text; rid uuid;
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
   WHEN 'report_labor_logs' THEN 'worker_id,project_labor_id,project_task_id,check_in_time,check_out_time,break_minutes,is_unplanned,deviation_reason_id,notes,is_standby,standby_hours,transfer_id'
   WHEN 'report_machinery_logs' THEN 'machinery_id,project_machinery_id,operator_id,start_meter,end_meter,total_hours,fuel_added,production_value,production_unit,start_shift_photos,end_shift_photos,is_unplanned,deviation_reason_id,notes,is_standby,standby_hours,machinery_inspection_id,operation_start,operation_end'
   ELSE 'material_id,project_material_id,quantity_used,area_installed,unit,notes,is_waste,waste_reason' END;
  FOR item IN SELECT value FROM jsonb_array_elements(payload) LOOP
   IF jsonb_typeof(item)<>'object' THEN RAISE EXCEPTION 'Each resource must be an object'; END IF;
   -- Keep stable row identity; an ID belonging to another section fails the PK
   -- and rolls back the entire operation. Never accept monetary fields here.
   EXECUTE format('INSERT INTO public.%I(id,daily_report_id,section_id,execution_crew_id,%s)
    SELECT $1,$2,$3,$4,%s FROM jsonb_populate_record(NULL::public.%I,$5)',t,cols,cols,t)
    USING coalesce((item->>'id')::uuid,gen_random_uuid()),d.id,s.id,s.crew_id,
    jsonb_build_object('break_minutes',0,'is_unplanned',false,'is_standby',false,'is_waste',false,
     'fuel_added',0,'total_hours',0,'start_meter',0,'start_shift_photos','[]'::jsonb,'end_shift_photos','[]'::jsonb)||item;
  END LOOP;
 END LOOP;
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

CREATE FUNCTION public.review_daily_report_section(p_section uuid,p_approve boolean,p_reason text DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE s public.daily_report_sections; d public.daily_reports; rid uuid; BEGIN
 SELECT daily_report_id INTO STRICT rid FROM public.daily_report_sections WHERE id=p_section;
 d:=app_private.lock_execution(rid);
 SELECT * INTO STRICT s FROM public.daily_report_sections WHERE id=p_section FOR UPDATE;
 IF NOT coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(d.project_id,d.report_date)),false)
 THEN RAISE EXCEPTION 'Only an assigned supervisor or administrator can review'; END IF;
 IF s.created_by=auth.uid() OR s.last_saved_by=auth.uid() THEN RAISE EXCEPTION 'Independent review required'; END IF;
 IF s.status<>'submitted' THEN RAISE EXCEPTION 'Only submitted sections can be reviewed'; END IF;
 IF NOT p_approve AND nullif(trim(p_reason),'') IS NULL THEN RAISE EXCEPTION 'Return reason is required'; END IF;
 UPDATE public.daily_report_sections SET status=CASE WHEN p_approve THEN 'approved' ELSE 'returned' END,
  review_notes=p_reason,reviewed_by=auth.uid(),reviewed_at=now(),updated_at=now(),revision=revision+1
  WHERE id=s.id RETURNING * INTO s;
 RETURN to_jsonb(s);
END $$;

CREATE FUNCTION public.request_daily_worker_transfer(p_report uuid,p_worker uuid,p_to_crew uuid,
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
 INSERT INTO public.daily_worker_transfers(daily_report_id,worker_id,from_crew_id,to_crew_id,project_labor_id,starts_at,ends_at,reason)
  VALUES(d.id,p_worker,base,p_to_crew,p_labor,p_start,p_end,p_reason) RETURNING id INTO tid;
 RETURN tid;
END $$;

CREATE FUNCTION public.review_daily_worker_transfer(p_transfer uuid,p_approve boolean)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE t public.daily_worker_transfers; d public.daily_reports; rid uuid; BEGIN
 SELECT daily_report_id INTO STRICT rid FROM public.daily_worker_transfers WHERE id=p_transfer;
 d:=app_private.lock_execution(rid);
 SELECT * INTO STRICT t FROM public.daily_worker_transfers WHERE id=p_transfer FOR UPDATE;
 IF NOT coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(d.project_id,d.report_date)),false)
 THEN RAISE EXCEPTION 'Supervisor authorization is required'; END IF;
 IF t.status<>'pending' THEN RAISE EXCEPTION 'Loan is already reviewed'; END IF;
 IF p_approve AND EXISTS(SELECT 1 FROM public.daily_worker_transfers x WHERE x.id<>t.id
  AND x.daily_report_id=t.daily_report_id AND x.worker_id=t.worker_id AND x.status='approved'
  AND tsrange(d.report_date+x.starts_at,d.report_date+x.ends_at,'[)') &&
   tsrange(d.report_date+t.starts_at,d.report_date+t.ends_at,'[)'))
 THEN RAISE EXCEPTION 'Authorized loans cannot overlap'; END IF;
 -- End the origin segment first; authorization does not edit attendance silently.
 IF p_approve AND EXISTS(SELECT 1 FROM public.report_labor_logs l WHERE l.daily_report_id=d.id
  AND l.worker_id=t.worker_id AND tsrange(d.report_date+l.check_in_time,
   d.report_date+coalesce(l.check_out_time,'24:00'::time),'[)') &&
   tsrange(d.report_date+t.starts_at,d.report_date+t.ends_at,'[)'))
 THEN RAISE EXCEPTION 'Close or adjust the origin attendance before authorizing the loan'; END IF;
 UPDATE public.daily_worker_transfers SET status=CASE WHEN p_approve THEN 'approved' ELSE 'rejected' END,
  authorized_by=auth.uid(),authorized_at=now() WHERE id=t.id;
END $$;

CREATE FUNCTION public.cancel_daily_worker_transfer(p_transfer uuid,p_reason text)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE t public.daily_worker_transfers; d public.daily_reports; rid uuid; BEGIN
 SELECT daily_report_id INTO STRICT rid FROM public.daily_worker_transfers WHERE id=p_transfer;
 d:=app_private.lock_execution(rid);
 SELECT * INTO STRICT t FROM public.daily_worker_transfers WHERE id=p_transfer FOR UPDATE;
 IF NOT coalesce(app_private.is_admin() OR
  (app_private.role()='Supervisor' AND app_private.project_access(d.project_id,d.report_date)) OR
  (t.status='pending' AND t.requested_by=auth.uid() AND app_private.leads(t.from_crew_id,d.report_date)),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF t.status NOT IN ('pending','approved') OR nullif(trim(p_reason),'') IS NULL
 THEN RAISE EXCEPTION 'A cancellation requires an open loan and a reason'; END IF;
 IF EXISTS(SELECT 1 FROM public.report_labor_logs WHERE transfer_id=t.id)
 THEN RAISE EXCEPTION 'Correct the recorded execution before cancelling this loan'; END IF;
 UPDATE public.daily_worker_transfers SET status='cancelled',decision_notes=p_reason,
  authorized_by=auth.uid(),authorized_at=now() WHERE id=t.id;
END $$;

-- Block final consolidation while canonical crew sections need attention.
CREATE FUNCTION app_private.guard_execution_submission() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NEW.status IN ('submitted','approved') AND NEW.status IS DISTINCT FROM OLD.status AND EXISTS(
  SELECT 1 FROM public.daily_report_sections WHERE daily_report_id=NEW.id AND
   (status<>'approved' AND (crew_id IS NOT NULL OR status<>'submitted')))
 THEN RAISE EXCEPTION 'Review all crew sections before submitting the consolidated daily report'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_execution_submission BEFORE UPDATE ON public.daily_reports
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_execution_submission();

CREATE TRIGGER access_audit AFTER INSERT OR UPDATE OR DELETE ON public.daily_report_sections
 FOR EACH ROW EXECUTE FUNCTION app_private.audit();
CREATE TRIGGER access_audit AFTER INSERT OR UPDATE OR DELETE ON public.daily_worker_transfers
 FOR EACH ROW EXECUTE FUNCTION app_private.audit();
REVOKE ALL ON FUNCTION app_private.can_report(uuid,date,uuid),app_private.lock_execution(uuid),
 app_private.guard_execution_log(),app_private.guard_execution_submission(),app_private.execution_fields(text,jsonb) FROM PUBLIC,anon,authenticated;
GRANT EXECUTE ON FUNCTION app_private.can_report(uuid,date,uuid) TO authenticated;
REVOKE ALL ON FUNCTION public.open_daily_report_section(uuid,date,uuid),
 public.get_daily_execution_workspace(uuid,date,uuid),
 public.save_daily_report_section(uuid,integer,text,jsonb,jsonb,jsonb,boolean),
 public.review_daily_report_section(uuid,boolean,text),
 public.request_daily_worker_transfer(uuid,uuid,uuid,uuid,time,time,text),
 public.review_daily_worker_transfer(uuid,boolean),public.cancel_daily_worker_transfer(uuid,text) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.open_daily_report_section(uuid,date,uuid),
 public.get_daily_execution_workspace(uuid,date,uuid),
 public.save_daily_report_section(uuid,integer,text,jsonb,jsonb,jsonb,boolean),
 public.review_daily_report_section(uuid,boolean,text),
 public.request_daily_worker_transfer(uuid,uuid,uuid,uuid,time,time,text),
 public.review_daily_worker_transfer(uuid,boolean),public.cancel_daily_worker_transfer(uuid,text) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
