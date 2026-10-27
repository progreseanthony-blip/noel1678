BEGIN;

-- Stable service identity: baseline/CO-linked rows share the baseline service;
-- project-only services and unclassified labor supply keep distinct identities.
CREATE FUNCTION app_private.labor_service_key(l public.project_labor) RETURNS text
 LANGUAGE sql STABLE SECURITY DEFINER SET search_path='' AS $$
 SELECT CASE WHEN l.quote_service_id IS NOT NULL THEN 'q:'||l.quote_service_id
  WHEN l.project_service_id IS NOT NULL THEN 'p:'||l.project_service_id ELSE 'u:'||l.project_id END
$$;

CREATE TABLE public.crew_service_assignments (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 project_id uuid NOT NULL REFERENCES public.projects(id),
 service_key text NOT NULL,
 valid_from date NOT NULL,
 valid_until date NOT NULL,
 created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
 CHECK(valid_until>=valid_from)
);
CREATE INDEX ON public.crew_service_assignments(crew_id,valid_from,valid_until);
ALTER TABLE public.crew_members
 ADD COLUMN labor_assignment_id uuid REFERENCES public.project_labor_assignments(id) ON DELETE RESTRICT,
 ADD COLUMN crew_service_assignment_id uuid REFERENCES public.crew_service_assignments(id) ON DELETE RESTRICT;
ALTER TABLE public.crew_members ADD CONSTRAINT crew_planning_links_paired CHECK(
 (labor_assignment_id IS NULL)=(crew_service_assignment_id IS NULL));
CREATE INDEX ON public.crew_members(labor_assignment_id);

ALTER TABLE public.crew_service_assignments ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.crew_service_assignments TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.crew_service_assignments FROM PUBLIC,anon,authenticated;
CREATE POLICY planning_service_read ON public.crew_service_assignments FOR SELECT TO authenticated
 USING(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(project_id)));

CREATE FUNCTION app_private.guard_crew_planning_link() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a public.project_labor_assignments; s public.crew_service_assignments; p uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF TG_TABLE_NAME='crew_service_assignments' THEN
  IF TG_OP='DELETE' THEN RAISE EXCEPTION 'End the service period instead of deleting history'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=NEW.crew_id AND project_id=NEW.project_id AND active)
   OR NOT EXISTS(SELECT 1 FROM public.project_labor l WHERE l.project_id=NEW.project_id AND app_private.labor_service_key(l)=NEW.service_key)
  THEN RAISE EXCEPTION 'Select a service planned in the crew project'; END IF;
  IF TG_OP='UPDATE' AND ((to_jsonb(NEW)-'valid_until'-'valid_from') IS DISTINCT FROM (to_jsonb(OLD)-'valid_until'-'valid_from') OR NEW.valid_from>OLD.valid_from)
  THEN RAISE EXCEPTION 'Create a new service period to change crew service'; END IF;
  IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id=NEW.project_id AND status='active')
  THEN RAISE EXCEPTION 'Project is read only'; END IF;
  IF EXISTS(SELECT 1 FROM public.crew_service_assignments x WHERE x.id<>NEW.id AND x.crew_id=NEW.crew_id
   AND daterange(x.valid_from,x.valid_until,'[]') && daterange(NEW.valid_from,NEW.valid_until,'[]'))
  THEN RAISE EXCEPTION 'A crew can only have one planned service during an interval'; END IF;
  IF TG_OP='UPDATE' AND EXISTS(SELECT 1 FROM public.crew_members m WHERE m.crew_service_assignment_id=NEW.id
   AND (m.valid_until IS NULL OR m.valid_until>NEW.valid_until))
  THEN RAISE EXCEPTION 'End affected memberships before shortening the service period'; END IF;
  RETURN NEW;
 END IF;
 IF TG_OP='UPDATE' AND NEW.valid_until IS NOT NULL AND (OLD.valid_until IS NULL OR NEW.valid_until<OLD.valid_until) AND EXISTS(
  SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
  WHERE l.worker_id=NEW.worker_id AND (l.base_crew_id=NEW.crew_id OR l.execution_crew_id=NEW.crew_id)
   AND d.report_date>NEW.valid_until AND d.report_date>=OLD.valid_from AND (OLD.valid_until IS NULL OR d.report_date<=OLD.valid_until))
 THEN RAISE EXCEPTION 'Membership dates already used by daily reports must be preserved'; END IF;
 IF NEW.labor_assignment_id IS NULL THEN
  -- Preserve unclassified legacy teams; never infer their historical service.
  IF TG_OP='INSERT' AND EXISTS(SELECT 1 FROM public.crew_service_assignments WHERE crew_id=NEW.crew_id)
  THEN RAISE EXCEPTION 'Select the worker planning assignment and crew service period'; END IF;
  RETURN NEW;
 END IF;
 SELECT * INTO STRICT a FROM public.project_labor_assignments WHERE id=NEW.labor_assignment_id FOR SHARE;
 SELECT * INTO STRICT s FROM public.crew_service_assignments WHERE id=NEW.crew_service_assignment_id FOR SHARE;
 SELECT project_id INTO p FROM public.project_labor WHERE id=a.project_labor_id;
 IF a.worker_id<>NEW.worker_id OR s.crew_id<>NEW.crew_id OR s.project_id<>p OR NEW.valid_until IS NULL
  OR NEW.valid_from<s.valid_from OR NEW.valid_until>s.valid_until
  OR a.start_date IS NULL OR a.end_date IS NULL OR NEW.valid_from<a.start_date OR NEW.valid_until>a.end_date
  OR NOT EXISTS(SELECT 1 FROM public.project_labor l WHERE l.id=a.project_labor_id AND app_private.labor_service_key(l)=s.service_key)
 THEN RAISE EXCEPTION 'Crew membership must fit the selected service and worker planned dates'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_crew_planning_link BEFORE INSERT OR UPDATE ON public.crew_members
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_crew_planning_link();
CREATE TRIGGER guard_crew_service_period BEFORE INSERT OR UPDATE OR DELETE ON public.crew_service_assignments
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_crew_planning_link();
CREATE TRIGGER access_audit AFTER INSERT OR UPDATE OR DELETE ON public.crew_service_assignments
 FOR EACH ROW EXECUTE FUNCTION app_private.audit();

CREATE FUNCTION app_private.protect_labor_plan_history() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE a public.project_labor_assignments; BEGIN
 a:=OLD;
 PERFORM pg_advisory_xact_lock(1678,2);
 IF TG_OP='DELETE' AND EXISTS(SELECT 1 FROM public.crew_members WHERE labor_assignment_id=a.id)
 THEN RAISE EXCEPTION 'Planning is linked to crew history. End its participation instead of deleting it'; END IF;
 IF TG_OP='UPDATE' AND EXISTS(SELECT 1 FROM public.crew_members m WHERE m.labor_assignment_id=a.id AND
  (NEW.worker_id IS DISTINCT FROM OLD.worker_id OR NEW.project_labor_id IS DISTINCT FROM OLD.project_labor_id
   OR NEW.start_date IS NULL OR NEW.end_date IS NULL OR NEW.start_date>m.valid_from OR NEW.end_date<m.valid_until))
 THEN RAISE EXCEPTION 'Adjust the crew participation period before reducing or changing worker planning'; END IF;
 IF (TG_OP='DELETE' OR NEW.start_date IS DISTINCT FROM OLD.start_date OR NEW.end_date IS DISTINCT FROM OLD.end_date
  OR NEW.project_labor_id IS DISTINCT FROM OLD.project_labor_id OR NEW.worker_id IS DISTINCT FROM OLD.worker_id)
  AND EXISTS(SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
   WHERE l.project_labor_id=a.project_labor_id AND l.worker_id=a.worker_id
    AND d.report_date BETWEEN a.start_date AND a.end_date AND (TG_OP='DELETE'
     OR NEW.worker_id IS DISTINCT FROM OLD.worker_id OR NEW.project_labor_id IS DISTINCT FROM OLD.project_labor_id
     OR NEW.start_date IS NULL OR NEW.end_date IS NULL OR d.report_date NOT BETWEEN NEW.start_date AND NEW.end_date))
 THEN RAISE EXCEPTION 'Planning dates already used by daily reports must be preserved'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $$;
CREATE TRIGGER protect_labor_plan_history BEFORE UPDATE OR DELETE ON public.project_labor_assignments
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_labor_plan_history();

CREATE FUNCTION app_private.protect_crew_labor_service() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF (NEW.project_id IS DISTINCT FROM OLD.project_id OR NEW.quote_service_id IS DISTINCT FROM OLD.quote_service_id
   OR NEW.project_service_id IS DISTINCT FROM OLD.project_service_id OR NEW.role_id IS DISTINCT FROM OLD.role_id
   OR NEW.role_name IS DISTINCT FROM OLD.role_name) AND EXISTS(
  SELECT 1 FROM public.project_labor_assignments a JOIN public.crew_members m ON m.labor_assignment_id=a.id WHERE a.project_labor_id=OLD.id)
 THEN RAISE EXCEPTION 'Crew-linked labor service and role must retain their history. Create a new planning row'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER protect_crew_labor_service BEFORE UPDATE ON public.project_labor
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_crew_labor_service();
REVOKE ALL ON FUNCTION app_private.protect_crew_labor_service() FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.get_labor_crew_planning(p_project uuid) RETURNS jsonb
 LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$ BEGIN
 IF NOT coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p_project)),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN jsonb_build_object(
 'project',(SELECT jsonb_build_object('id',id,'status',status) FROM public.projects WHERE id=p_project),
 'labor',coalesce((SELECT jsonb_agg(jsonb_build_object('id',l.id,'service_key',app_private.labor_service_key(l),
  'service_name',coalesce(q.name,ps.name,'General / Sin servicio'),'role_id',l.role_id,'role_name',l.role_name,
  'start_date',l.start_date,'end_date',l.end_date) ORDER BY coalesce(q.name,ps.name,''),l.role_name,l.id)
  FROM public.project_labor l LEFT JOIN public.quote_services q ON q.id=l.quote_service_id
   LEFT JOIN public.project_services ps ON ps.id=l.project_service_id WHERE l.project_id=p_project),'[]'::jsonb),
 'assignments',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'worker_id',a.worker_id,'worker_name',w.full_name,
  'project_labor_id',a.project_labor_id,'role_name',l.role_name,'service_key',app_private.labor_service_key(l),
  'start_date',a.start_date,'end_date',a.end_date) ORDER BY w.full_name,a.start_date,a.id)
  FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
  JOIN public.workers w ON w.id=a.worker_id WHERE l.project_id=p_project),'[]'::jsonb),
 'workers',coalesce((SELECT jsonb_agg(jsonb_build_object('id',w.id,'full_name',w.full_name,'role_id',w.role_id,
  'role_name',r.description) ORDER BY w.full_name) FROM public.workers w LEFT JOIN public.labor_roles r ON r.id=w.role_id
  WHERE w.status='Active'),'[]'::jsonb),
 'crews',coalesce((SELECT jsonb_agg(to_jsonb(c) ORDER BY c.name) FROM public.project_crews c WHERE c.project_id=p_project),'[]'::jsonb),
 'periods',coalesce((SELECT jsonb_agg(to_jsonb(s) ORDER BY s.valid_from) FROM public.crew_service_assignments s WHERE s.project_id=p_project),'[]'::jsonb),
 'members',coalesce((SELECT jsonb_agg(to_jsonb(m)||jsonb_build_object('worker_name',w.full_name) ORDER BY w.full_name,m.valid_from)
  FROM public.crew_members m JOIN public.project_crews c ON c.id=m.crew_id JOIN public.workers w ON w.id=m.worker_id
  WHERE c.project_id=p_project),'[]'::jsonb),
 'leaders',coalesce((SELECT jsonb_agg(to_jsonb(l)||jsonb_build_object('name',p.name) ORDER BY l.valid_from)
  FROM public.crew_leaders l JOIN public.project_crews c ON c.id=l.crew_id JOIN public.profiles p ON p.id=l.profile_id
  WHERE c.project_id=p_project),'[]'::jsonb),
 'foremen',coalesce((SELECT jsonb_agg(jsonb_build_object('id',p.id,'name',p.name,'valid_from',m.valid_from,'valid_until',m.valid_until)
  ORDER BY p.name,m.valid_from) FROM public.project_members m JOIN public.profiles p ON p.id=m.profile_id
  WHERE m.project_id=p_project AND m.responsibility='Foreman' AND p.role='Foreman' AND p.access_status='active'),'[]'::jsonb));
END $$;

-- Both existing and new labor allocations can be organized in one commit.
-- Existing allocations retain their dates; row dates specify crew participation.
CREATE FUNCTION public.save_labor_crew_plan(p_project uuid,p_service text,p_rows jsonb,
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
    AND app_private.labor_service_key(x)=p_service AND x.role_name IS NOT DISTINCT FROM labor_row.role_name
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

CREATE FUNCTION public.update_labor_crew_dates(p_assignment uuid,p_from date,p_until date)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 SELECT l.project_id INTO STRICT p FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
  WHERE a.id=p_assignment;
 IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 IF p_from IS NULL OR p_until IS NULL OR p_until<p_from THEN RAISE EXCEPTION 'Select valid planning dates'; END IF;
 IF EXISTS(SELECT 1 FROM public.project_labor_assignments own JOIN public.project_labor_assignments other
   ON other.worker_id=own.worker_id AND other.id<>own.id
  WHERE own.id=p_assignment AND daterange(other.start_date,other.end_date,'[]') && daterange(p_from,p_until,'[]'))
 THEN RAISE EXCEPTION 'Worker already has planning in this interval'; END IF;
 UPDATE public.project_labor_assignments SET start_date=p_from,end_date=p_until WHERE id=p_assignment;
END $$;

CREATE FUNCTION public.end_labor_crew_period(p_kind text,p_id uuid,p_until date)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF p_until IS NULL THEN RAISE EXCEPTION 'Select an end date'; END IF;
 IF p_kind='member' THEN
  SELECT c.project_id INTO STRICT p FROM public.crew_members m JOIN public.project_crews c ON c.id=m.crew_id WHERE m.id=p_id;
 ELSIF p_kind='leader' THEN
  SELECT c.project_id INTO STRICT p FROM public.crew_leaders l JOIN public.project_crews c ON c.id=l.crew_id WHERE l.id=p_id;
 ELSE RAISE EXCEPTION 'Invalid period type'; END IF;
 IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 IF p_kind='member' THEN UPDATE public.crew_members SET valid_until=p_until WHERE id=p_id;
 ELSE UPDATE public.crew_leaders SET valid_until=p_until WHERE id=p_id; END IF;
END $$;

CREATE FUNCTION app_private.protect_leadership_reports() RETURNS trigger
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$ BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF NEW.valid_until IS NOT NULL AND (OLD.valid_until IS NULL OR NEW.valid_until<OLD.valid_until) AND EXISTS(
  SELECT 1 FROM public.daily_report_sections s JOIN public.daily_reports d ON d.id=s.daily_report_id
  WHERE s.crew_id=OLD.crew_id AND (s.created_by=OLD.profile_id OR s.last_saved_by=OLD.profile_id)
   AND d.report_date>=OLD.valid_from AND (OLD.valid_until IS NULL OR d.report_date<=OLD.valid_until)
   AND d.report_date>NEW.valid_until)
 THEN RAISE EXCEPTION 'Leadership dates already used by daily reports must be preserved'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER protect_leadership_reports BEFORE UPDATE ON public.crew_leaders
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_leadership_reports();
REVOKE ALL ON FUNCTION app_private.protect_leadership_reports() FROM PUBLIC,anon,authenticated;

CREATE FUNCTION public.assign_labor_crew_leader(p_crew uuid,p_profile uuid,p_from date,p_until date)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE p uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 SELECT project_id INTO STRICT p FROM public.project_crews WHERE id=p_crew AND active;
 IF NOT coalesce(app_private.organize_project_team(p),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 IF p_from IS NULL OR p_until IS NULL OR p_until<p_from THEN RAISE EXCEPTION 'Select valid leadership dates'; END IF;
 INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until) VALUES(p_crew,p_profile,p_from,p_until);
END $$;
REVOKE ALL ON FUNCTION public.assign_labor_crew_leader(uuid,uuid,date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.assign_labor_crew_leader(uuid,uuid,date,date) TO authenticated;

-- Reuse the daily-report forms with the specific planned assignment as default.
CREATE FUNCTION public.get_daily_execution_planned_workspace(p_project uuid,p_day date,p_crew uuid)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path='' AS $$
DECLARE data jsonb; planned jsonb; x jsonb; filtered jsonb; BEGIN
 data:=public.get_daily_execution_workspace(p_project,p_day,p_crew);
 IF p_crew IS NULL THEN RETURN data; END IF;
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
 RETURN data||jsonb_build_object('planned_labor',planned);
END $$;

REVOKE ALL ON FUNCTION app_private.labor_service_key(public.project_labor),app_private.guard_crew_planning_link(),
 app_private.protect_labor_plan_history() FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.get_labor_crew_planning(uuid),public.save_labor_crew_plan(uuid,text,jsonb,uuid,text,uuid),
 public.update_labor_crew_dates(uuid,date,date),public.end_labor_crew_period(text,uuid,date),
 public.get_daily_execution_planned_workspace(uuid,date,uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_labor_crew_planning(uuid),public.save_labor_crew_plan(uuid,text,jsonb,uuid,text,uuid),
 public.update_labor_crew_dates(uuid,date,date),public.end_labor_crew_period(text,uuid,date),
 public.get_daily_execution_planned_workspace(uuid,date,uuid) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
