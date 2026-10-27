-- Access is denied unless a known active role and an explicit assignment allow it.
-- This migration changes schema/policies only; it does not assign existing users.
BEGIN;
CREATE SCHEMA IF NOT EXISTS app_private;
REVOKE ALL ON SCHEMA app_private FROM PUBLIC;
GRANT USAGE ON SCHEMA app_private TO authenticated;

ALTER TABLE public.profiles ADD COLUMN access_status text NOT NULL DEFAULT 'active'
  CHECK (access_status IN ('active', 'pending', 'disabled'));
ALTER TABLE public.profiles ADD COLUMN worker_id uuid UNIQUE REFERENCES public.workers(id);
INSERT INTO public.roles(name, description) VALUES
 ('Supervisor', 'Assigned projects: estimates, planning and report review'),
 ('Foreman', 'Assigned crews: daily contributions and hours') ON CONFLICT (name) DO NOTHING;

CREATE TABLE public.project_members (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 project_id uuid NOT NULL REFERENCES public.projects(id),
 profile_id uuid NOT NULL REFERENCES public.profiles(id),
 responsibility text NOT NULL CHECK (responsibility IN ('Supervisor','Foreman')),
 valid_from date NOT NULL DEFAULT current_date,
 valid_until date,
 CHECK (valid_until IS NULL OR valid_until >= valid_from),
 UNIQUE(project_id, profile_id, valid_from)
);
CREATE INDEX ON public.project_members(profile_id, project_id);
CREATE TABLE public.project_crews (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 project_id uuid NOT NULL REFERENCES public.projects(id),
 name text NOT NULL CHECK (length(trim(name)) > 0),
 active boolean NOT NULL DEFAULT true,
 UNIQUE(project_id, name)
);
CREATE TABLE public.crew_leaders (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 profile_id uuid NOT NULL REFERENCES public.profiles(id),
 valid_from date NOT NULL DEFAULT current_date,
 valid_until date,
 CHECK (valid_until IS NULL OR valid_until >= valid_from)
);
CREATE INDEX ON public.crew_leaders(profile_id, crew_id);
CREATE TABLE public.crew_members (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 worker_id uuid NOT NULL REFERENCES public.workers(id),
 valid_from date NOT NULL DEFAULT current_date,
 valid_until date,
 CHECK (valid_until IS NULL OR valid_until >= valid_from)
);
CREATE INDEX ON public.crew_members(crew_id, worker_id);

-- Estimates exist before projects. Explicit access covers that stage as well.
CREATE TABLE public.quote_members (
 quote_id uuid NOT NULL REFERENCES public.quotes(id),
 profile_id uuid NOT NULL REFERENCES public.profiles(id),
 PRIMARY KEY(quote_id, profile_id)
);
ALTER TABLE public.quotes ADD COLUMN created_by uuid REFERENCES public.profiles(id) DEFAULT auth.uid();
CREATE TABLE public.access_audit (
 id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
 actor_id uuid,
 occurred_at timestamptz NOT NULL DEFAULT now(),
 entity text NOT NULL,
 operation text NOT NULL,
 old_data jsonb,
 new_data jsonb
);

CREATE FUNCTION app_private.role() RETURNS text LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path = '' AS $$
 SELECT role FROM public.profiles WHERE id = auth.uid() AND access_status = 'active'
 AND role IN ('Admin','Supervisor','Foreman')
$$;
CREATE FUNCTION app_private.is_admin() RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
 SET search_path = '' AS $$ SELECT coalesce(app_private.role() = 'Admin', false) $$;
CREATE FUNCTION app_private.project_access(p_id uuid, p_day date DEFAULT current_date)
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT app_private.is_admin() OR EXISTS (
 SELECT 1 FROM public.project_members m WHERE m.project_id = p_id AND m.profile_id = auth.uid()
 AND m.responsibility = app_private.role() AND m.valid_from <= p_day
 AND (m.valid_until IS NULL OR m.valid_until >= p_day)
 AND m.valid_from <= current_date AND (m.valid_until IS NULL OR m.valid_until >= current_date))
$$;
CREATE FUNCTION app_private.leads(p_crew uuid, p_day date DEFAULT current_date)
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = '' AS $$
 SELECT app_private.role() = 'Foreman' AND EXISTS (
 SELECT 1 FROM public.crew_leaders l JOIN public.project_crews c ON c.id = l.crew_id
 WHERE l.crew_id = p_crew AND l.profile_id = auth.uid() AND c.active
 AND l.valid_from <= p_day AND (l.valid_until IS NULL OR l.valid_until >= p_day)
 AND l.valid_from <= current_date AND (l.valid_until IS NULL OR l.valid_until >= current_date)
 AND app_private.project_access(c.project_id, p_day))
$$;
CREATE FUNCTION app_private.quote_access(p_id uuid) RETURNS boolean LANGUAGE sql STABLE
 SECURITY DEFINER SET search_path = '' AS $$
 SELECT app_private.is_admin() OR (app_private.role() = 'Supervisor' AND (
 EXISTS(SELECT 1 FROM public.quotes WHERE id=p_id AND created_by=auth.uid()) OR
 EXISTS(SELECT 1 FROM public.quote_members WHERE quote_id=p_id AND profile_id=auth.uid()) OR
 EXISTS(SELECT 1 FROM public.projects WHERE quote_id=p_id AND app_private.project_access(id))))
$$;

CREATE FUNCTION app_private.audit() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$ BEGIN
 INSERT INTO public.access_audit(actor_id,entity,operation,old_data,new_data)
 VALUES(auth.uid(),TG_TABLE_NAME,TG_OP,to_jsonb(OLD),to_jsonb(NEW));
 IF TG_OP = 'DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $$;
CREATE FUNCTION app_private.protect_profile() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$ BEGIN
 IF TG_OP='INSERT' THEN
   IF auth.uid() IS NOT NULL AND NOT app_private.is_admin() THEN
     NEW.role := 'Employee'; NEW.access_status := 'pending'; NEW.worker_id := NULL;
   END IF;
 ELSIF NOT app_private.is_admin() AND auth.uid() IS NOT NULL AND
   (NEW.role IS DISTINCT FROM OLD.role OR NEW.access_status IS DISTINCT FROM OLD.access_status
    OR NEW.worker_id IS DISTINCT FROM OLD.worker_id OR NEW.id IS DISTINCT FROM OLD.id) THEN
   RAISE EXCEPTION 'Only administrators can change access';
 END IF;
 IF TG_OP='UPDATE' AND OLD.role='Admin' AND OLD.access_status='active'
 AND (NEW.role <> 'Admin' OR NEW.access_status <> 'active') THEN
   PERFORM pg_advisory_xact_lock(1678,1);
   IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id<>OLD.id AND role='Admin' AND access_status='active')
   THEN RAISE EXCEPTION 'At least one active administrator is required'; END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER protect_profile BEFORE INSERT OR UPDATE ON public.profiles
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_profile();
CREATE FUNCTION app_private.protect_admin_delete() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$ BEGIN
 IF OLD.role='Admin' AND OLD.access_status='active' THEN
   PERFORM pg_advisory_xact_lock(1678,1);
   IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id<>OLD.id AND role='Admin' AND access_status='active')
   THEN RAISE EXCEPTION 'At least one active administrator is required'; END IF;
 END IF; RETURN OLD;
END $$;
CREATE TRIGGER protect_admin_delete BEFORE DELETE ON public.profiles
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_admin_delete();
-- The auth trigger creates pending accounts, including signups without a caller JWT.
CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger LANGUAGE plpgsql
 SECURITY DEFINER SET search_path = '' AS $$ BEGIN
 INSERT INTO public.profiles(id,email,name,role,access_status)
 VALUES(NEW.id,NEW.email,NEW.raw_user_meta_data->>'name','Employee','pending'); RETURN NEW;
END $$;

CREATE FUNCTION app_private.validate_team() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$
DECLARE p uuid; w uuid; BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 -- Ending historical membership remains possible after a role/plan changes.
 IF TG_OP='UPDATE' AND NEW.valid_until IS NOT NULL AND
   (OLD.valid_until IS NULL OR NEW.valid_until<=OLD.valid_until) THEN RETURN NEW; END IF;
 IF TG_TABLE_NAME='project_members' THEN
   IF NOT EXISTS(SELECT 1 FROM public.profiles WHERE id=NEW.profile_id
     AND role=NEW.responsibility AND access_status='active') THEN
     RAISE EXCEPTION 'Select an active user with the corresponding role'; END IF;
   IF EXISTS(SELECT 1 FROM public.project_members m WHERE m.id<>NEW.id
     AND m.project_id=NEW.project_id AND m.profile_id=NEW.profile_id
     AND daterange(m.valid_from,m.valid_until,'[]') && daterange(NEW.valid_from,NEW.valid_until,'[]'))
   THEN RAISE EXCEPTION 'Overlapping project membership'; END IF;
 ELSE
   SELECT project_id INTO p FROM public.project_crews WHERE id=NEW.crew_id;
   IF TG_TABLE_NAME='crew_leaders' THEN
     IF NOT EXISTS(SELECT 1 FROM public.project_members m JOIN public.profiles u ON u.id=m.profile_id
       WHERE m.project_id=p AND m.profile_id=NEW.profile_id AND m.responsibility='Foreman'
       AND u.role='Foreman' AND u.access_status='active' AND m.valid_from<=NEW.valid_from
       AND (m.valid_until IS NULL OR (NEW.valid_until IS NOT NULL AND m.valid_until>=NEW.valid_until)))
     THEN RAISE EXCEPTION 'Leader must be an assigned active Foreman for the entire interval'; END IF;
     IF EXISTS(SELECT 1 FROM public.crew_leaders l WHERE l.id<>NEW.id AND l.crew_id=NEW.crew_id
       AND daterange(l.valid_from,l.valid_until,'[]') && daterange(NEW.valid_from,NEW.valid_until,'[]'))
     THEN RAISE EXCEPTION 'A crew can only have one leader at a time'; END IF;
   ELSE
     IF NOT EXISTS(SELECT 1 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
       JOIN public.workers w ON w.id=a.worker_id WHERE a.worker_id=NEW.worker_id AND l.project_id=p
       AND w.status='Active' AND coalesce(a.start_date,NEW.valid_from)<=NEW.valid_from
       AND (a.end_date IS NULL OR (NEW.valid_until IS NOT NULL AND a.end_date>=NEW.valid_until)))
     THEN RAISE EXCEPTION 'Worker must be planned in this project for the entire interval'; END IF;
     IF EXISTS(SELECT 1 FROM public.crew_members m WHERE m.id<>NEW.id AND m.worker_id=NEW.worker_id
       AND daterange(m.valid_from,m.valid_until,'[]') && daterange(NEW.valid_from,NEW.valid_until,'[]'))
     THEN RAISE EXCEPTION 'Worker already belongs to a crew during this interval'; END IF;
   END IF;
 END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER validate_project_member BEFORE INSERT OR UPDATE ON public.project_members
 FOR EACH ROW EXECUTE FUNCTION app_private.validate_team();
CREATE TRIGGER validate_crew_leader BEFORE INSERT OR UPDATE ON public.crew_leaders
 FOR EACH ROW EXECUTE FUNCTION app_private.validate_team();
CREATE TRIGGER validate_crew_member BEFORE INSERT OR UPDATE ON public.crew_members
 FOR EACH ROW EXECUTE FUNCTION app_private.validate_team();

-- A contribution is independently owned/reviewed; it is merged exactly once.
CREATE TABLE public.crew_daily_reports (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 crew_id uuid NOT NULL REFERENCES public.project_crews(id),
 report_date date NOT NULL,
 created_by uuid NOT NULL DEFAULT auth.uid() REFERENCES public.profiles(id),
 notes text NOT NULL DEFAULT '',
 labor jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(labor)='array'),
 machinery jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(machinery)='array'),
 materials jsonb NOT NULL DEFAULT '[]' CHECK(jsonb_typeof(materials)='array'),
 status text NOT NULL DEFAULT 'draft' CHECK(status IN ('draft','submitted','returned','approved')),
 review_notes text,
 reviewed_by uuid REFERENCES public.profiles(id),
 reviewed_at timestamptz,
 daily_report_id uuid REFERENCES public.daily_reports(id),
 UNIQUE(crew_id,report_date)
);
ALTER TABLE public.report_labor_logs ADD COLUMN crew_report_id uuid REFERENCES public.crew_daily_reports(id);
ALTER TABLE public.report_machinery_logs ADD COLUMN crew_report_id uuid REFERENCES public.crew_daily_reports(id);
ALTER TABLE public.report_material_usage ADD COLUMN crew_report_id uuid REFERENCES public.crew_daily_reports(id);
-- Only the transactional review RPC may attach consolidated contribution IDs.
CREATE TABLE app_private.crew_merge_authorizations (
 transaction_id bigint NOT NULL,
 report_id uuid NOT NULL,
 PRIMARY KEY(transaction_id,report_id)
);
REVOKE ALL ON app_private.crew_merge_authorizations FROM PUBLIC,anon,authenticated;

-- Resolve project/estimate scope through the actual resource hierarchy, including
-- indirect child tables. Unknown tables remain admin-only.
CREATE FUNCTION app_private.row_scope(t text, r jsonb, depth integer DEFAULT 0)
 RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE fk record; parent jsonb; val text; BEGIN
 IF app_private.is_admin() THEN RETURN true; END IF;
 IF app_private.role() IS DISTINCT FROM 'Supervisor' OR depth>8 THEN RETURN false; END IF;
 IF t='projects' THEN RETURN app_private.project_access((r->>'id')::uuid); END IF;
 IF t='quotes' THEN RETURN app_private.quote_access((r->>'id')::uuid); END IF;
 IF r ? 'project_id' AND r->>'project_id' IS NOT NULL THEN
   RETURN app_private.project_access((r->>'project_id')::uuid); END IF;
 -- A detail belongs to its report, not to any arbitrarily selected resource FK.
 IF r->>'daily_report_id' IS NOT NULL THEN RETURN EXISTS(SELECT 1 FROM public.daily_reports
   WHERE id=(r->>'daily_report_id')::uuid AND app_private.project_access(project_id)); END IF;
 IF r ? 'quote_id' AND r->>'quote_id' IS NOT NULL THEN
   RETURN app_private.quote_access((r->>'quote_id')::uuid); END IF;
 FOR fk IN SELECT a.attname col, pc.relname parent_table, pa.attname parent_col
   FROM pg_catalog.pg_constraint c
   JOIN pg_catalog.pg_class tc ON tc.oid=c.conrelid
   JOIN pg_catalog.pg_namespace n ON n.oid=tc.relnamespace
   JOIN pg_catalog.pg_class pc ON pc.oid=c.confrelid
   JOIN pg_catalog.pg_attribute a ON a.attrelid=tc.oid AND a.attnum=c.conkey[1]
   JOIN pg_catalog.pg_attribute pa ON pa.attrelid=pc.oid AND pa.attnum=c.confkey[1]
   WHERE c.contype='f' AND n.nspname='public' AND tc.relname=t
   AND pc.relname IN ('projects','quotes','quote_services','quote_service_estimations',
    'quote_service_labors','quote_service_machineries','quote_service_materials',
    'quote_service_instruments','project_services','project_labor','project_machinery',
    'project_materials','project_instruments','daily_reports','project_crews','crew_daily_reports')
 LOOP
   val := r->>fk.col;
   IF val IS NOT NULL THEN
     EXECUTE format('SELECT to_jsonb(x) FROM public.%I x WHERE %I::text=$1',fk.parent_table,fk.parent_col)
       INTO parent USING val;
     IF parent IS NOT NULL AND app_private.row_scope(fk.parent_table,parent,depth+1) THEN RETURN true; END IF;
   END IF;
 END LOOP; RETURN false;
END $$;

CREATE FUNCTION app_private.table_access(t text, r jsonb, writing boolean)
 RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$ BEGIN
 IF app_private.is_admin() THEN RETURN true; END IF;
 IF t='profiles' THEN RETURN NOT writing AND (r->>'id'=auth.uid()::text OR
   (app_private.role()='Supervisor' AND EXISTS(SELECT 1 FROM public.project_members m
    WHERE m.profile_id=(r->>'id')::uuid AND app_private.project_access(m.project_id)))); END IF;
 IF app_private.role() IS DISTINCT FROM 'Supervisor' THEN RETURN false; END IF;
 IF t=ANY(ARRAY['roles','workers','labor_roles','machinery','materials','instruments','customers',
 'services','units','logistics_equipment','logistics_applications','machinery_applications',
 'deviation_reasons','disruption_reasons']) THEN RETURN NOT writing; END IF;
 IF t=ANY(ARRAY['project_members','project_crews','crew_leaders','crew_members','crew_daily_reports']) THEN
   RETURN NOT writing AND app_private.row_scope(t,r); END IF;
 IF t=ANY(ARRAY['projects','quotes','quote_services','quote_service_machineries','quote_service_labors',
 'quote_service_materials','quote_service_instruments','quote_service_estimations',
 'quote_service_estimation_resources','project_services','project_labor','project_labor_assignments',
 'project_machinery','project_machinery_assignments','project_materials','project_instruments',
 'project_instrument_assignments','project_tasks','daily_reports','report_labor_logs',
 'report_machinery_logs','report_material_usage','project_baseline_snapshots','project_non_working_days'])
 THEN RETURN app_private.row_scope(t,r); END IF;
 RETURN false;
END $$;

-- Replace permissive policies, rather than adding restrictive-looking policies
-- which Postgres would OR with the old allow-all policies.
DO $$ DECLARE t record; p record; BEGIN
 FOR t IN SELECT tablename FROM pg_tables WHERE schemaname='public' LOOP
   EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',t.tablename);
   FOR p IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename=t.tablename LOOP
     EXECUTE format('DROP POLICY %I ON public.%I',p.policyname,t.tablename);
   END LOOP;
   EXECUTE format('CREATE POLICY access_read ON public.%I FOR SELECT TO authenticated USING (app_private.table_access(%L,to_jsonb(%I),false))',t.tablename,t.tablename,t.tablename);
   EXECUTE format('CREATE POLICY access_insert ON public.%I FOR INSERT TO authenticated WITH CHECK (app_private.table_access(%L,to_jsonb(%I),true))',t.tablename,t.tablename,t.tablename);
   EXECUTE format('CREATE POLICY access_update ON public.%I FOR UPDATE TO authenticated USING (app_private.table_access(%L,to_jsonb(%I),true)) WITH CHECK (app_private.table_access(%L,to_jsonb(%I),true))',t.tablename,t.tablename,t.tablename,t.tablename,t.tablename);
   EXECUTE format('CREATE POLICY access_delete ON public.%I FOR DELETE TO authenticated USING (app_private.is_admin())',t.tablename);
 END LOOP;
END $$;
-- Own contact details can be edited; the trigger protects access fields.
CREATE POLICY own_contact ON public.profiles FOR UPDATE TO authenticated
 USING(id=auth.uid()) WITH CHECK(id=auth.uid());
CREATE POLICY own_quote ON public.quotes FOR INSERT TO authenticated
 WITH CHECK(app_private.role()='Supervisor' AND created_by=auth.uid() AND status='draft');

-- Existing definer RPCs must not become an alternate route around the new RLS.
DO $$ DECLARE f record; BEGIN
 FOR f IN SELECT p.oid::regprocedure signature FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
 WHERE n.nspname='public' AND p.prokind='f' AND p.prosecdef LOOP
   EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC, anon, authenticated',f.signature);
 END LOOP;
END $$;

CREATE FUNCTION public.get_access_context() RETURNS jsonb LANGUAGE sql STABLE
 SECURITY DEFINER SET search_path = '' AS $$
 SELECT jsonb_build_object('role',app_private.role(),'projects',coalesce((
 SELECT jsonb_agg(project_id) FROM public.project_members WHERE profile_id=auth.uid()
 AND responsibility=app_private.role() AND valid_from<=current_date
 AND (valid_until IS NULL OR valid_until>=current_date)),'[]'::jsonb))
$$;

-- Definer functions exposed below only return operational fields (never rates).
CREATE FUNCTION public.get_crew_workspace(p_crew uuid DEFAULT NULL, p_day date DEFAULT current_date)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE p uuid; BEGIN
 IF p_crew IS NULL THEN RETURN coalesce((SELECT jsonb_agg(jsonb_build_object(
 'id',c.id,'name',c.name,'project_id',c.project_id,'project_title',p.title))
 FROM public.project_crews c JOIN public.projects p ON p.id=c.project_id
 WHERE app_private.leads(c.id,p_day) OR (app_private.role()='Supervisor' AND app_private.project_access(p.id))
 OR app_private.is_admin()),'[]'::jsonb); END IF;
 SELECT project_id INTO p FROM public.project_crews WHERE id=p_crew;
 IF NOT coalesce(app_private.leads(p_crew,p_day) OR app_private.is_admin() OR
 (app_private.role()='Supervisor' AND app_private.project_access(p)),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN jsonb_build_object(
 'workers',coalesce((SELECT jsonb_agg(jsonb_build_object('id',w.id,'name',w.full_name,
 'project_labor_id',a.project_labor_id)) FROM public.crew_members m
 JOIN public.workers w ON w.id=m.worker_id
 JOIN public.project_labor_assignments a ON a.worker_id=w.id
 JOIN public.project_labor l ON l.id=a.project_labor_id AND l.project_id=p
 WHERE m.crew_id=p_crew AND w.status='Active' AND m.valid_from<=p_day
 AND (m.valid_until IS NULL OR m.valid_until>=p_day)
 AND (a.start_date IS NULL OR a.start_date<=p_day) AND (a.end_date IS NULL OR a.end_date>=p_day)),'[]'::jsonb),
 'machinery',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'name',machinery_name,'machinery_id',machinery_id))
 FROM public.project_machinery WHERE project_id=p),'[]'::jsonb),
 'materials',coalesce((SELECT jsonb_agg(jsonb_build_object('id',id,'name',material_name,'material_id',material_id))
 FROM public.project_materials WHERE project_id=p),'[]'::jsonb),
 'reports',coalesce((SELECT jsonb_agg(to_jsonb(r) ORDER BY report_date DESC) FROM public.crew_daily_reports r
 WHERE crew_id=p_crew AND (created_by=auth.uid() OR app_private.is_admin() OR app_private.role()='Supervisor')),'[]'::jsonb),
 'project_status',(SELECT status FROM public.projects WHERE id=p));
END $$;

CREATE FUNCTION public.save_crew_report(p_crew uuid,p_day date,p_notes text,p_labor jsonb,
 p_machinery jsonb DEFAULT '[]',p_materials jsonb DEFAULT '[]',p_submit boolean DEFAULT false)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE p uuid; rid uuid; e jsonb; a uuid; w uuid; start_at time; end_at time; minutes integer; BEGIN
 IF NOT coalesce(app_private.leads(p_crew,p_day),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 SELECT project_id INTO p FROM public.project_crews WHERE id=p_crew;
 PERFORM 1 FROM public.projects WHERE id=p AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Project is not active'; END IF;
 IF p_day>current_date THEN RAISE EXCEPTION 'Future reports are not allowed'; END IF;
 IF jsonb_typeof(p_labor)<>'array' OR jsonb_typeof(p_machinery)<>'array' OR jsonb_typeof(p_materials)<>'array'
 THEN RAISE EXCEPTION 'Invalid report data'; END IF;
 FOR e IN SELECT value FROM jsonb_array_elements(p_labor) LOOP
   w:=(e->>'worker_id')::uuid; a:=(e->>'project_labor_id')::uuid;
   IF NOT EXISTS(SELECT 1 FROM public.crew_members m JOIN public.workers w ON w.id=m.worker_id
     WHERE m.crew_id=p_crew AND m.worker_id=(e->>'worker_id')::uuid AND w.status='Active'
     AND m.valid_from<=p_day AND (m.valid_until IS NULL OR m.valid_until>=p_day))
   OR NOT EXISTS(SELECT 1 FROM public.project_labor_assignments pa JOIN public.project_labor l ON l.id=pa.project_labor_id
     WHERE pa.worker_id=w AND pa.project_labor_id=a AND l.project_id=p
     AND (pa.start_date IS NULL OR pa.start_date<=p_day) AND (pa.end_date IS NULL OR pa.end_date>=p_day))
   THEN RAISE EXCEPTION 'Worker is outside the crew or planning interval'; END IF;
   start_at:=(e->>'check_in_time')::time; end_at:=(e->>'check_out_time')::time;
   minutes:=(e->>'break_minutes')::integer;
   IF start_at IS NULL OR end_at IS NULL OR minutes IS NULL OR end_at<=start_at OR minutes<0
     OR minutes>=extract(epoch FROM end_at-start_at)/60 THEN RAISE EXCEPTION 'Invalid shift or break'; END IF;
 END LOOP;
 IF (SELECT count(*)<>count(DISTINCT value->>'worker_id') FROM jsonb_array_elements(p_labor))
 THEN RAISE EXCEPTION 'Duplicate worker'; END IF;
 FOR e IN SELECT value FROM jsonb_array_elements(p_machinery) LOOP
   IF NOT EXISTS(SELECT 1 FROM public.project_machinery WHERE id=(e->>'project_machinery_id')::uuid
     AND project_id=p AND machinery_id IS NOT NULL) OR NOT EXISTS(SELECT 1 FROM public.crew_members m
     WHERE m.crew_id=p_crew AND m.worker_id=(e->>'operator_id')::uuid
     AND m.valid_from<=p_day AND (m.valid_until IS NULL OR m.valid_until>=p_day))
     OR (e->>'end_meter') IS NULL OR (e->>'start_meter') IS NULL
     OR (e->>'end_meter')::numeric<(e->>'start_meter')::numeric OR (e->>'start_meter')::numeric<0
     OR coalesce((e->>'production_value')::numeric,0)<0
   THEN RAISE EXCEPTION 'Invalid machinery, operator or reading'; END IF;
 END LOOP;
 FOR e IN SELECT value FROM jsonb_array_elements(p_materials) LOOP
   IF NOT EXISTS(SELECT 1 FROM public.project_materials WHERE id=(e->>'project_material_id')::uuid
     AND project_id=p AND material_id IS NOT NULL) OR (e->>'quantity_used') IS NULL
     OR (e->>'quantity_used')::numeric<0 THEN RAISE EXCEPTION 'Invalid material usage'; END IF;
 END LOOP;
 INSERT INTO public.crew_daily_reports(crew_id,report_date,created_by,notes,labor,machinery,materials,status)
 VALUES(p_crew,p_day,auth.uid(),p_notes,p_labor,p_machinery,p_materials,CASE WHEN p_submit THEN 'submitted' ELSE 'draft' END)
 ON CONFLICT(crew_id,report_date) DO UPDATE SET notes=excluded.notes,labor=excluded.labor,
 machinery=excluded.machinery,materials=excluded.materials,status=excluded.status,
 review_notes=NULL,reviewed_by=NULL,reviewed_at=NULL
 WHERE crew_daily_reports.status IN ('draft','returned') AND crew_daily_reports.created_by=auth.uid()
 RETURNING id INTO rid;
 IF rid IS NULL THEN RAISE EXCEPTION 'Report is locked or belongs to another author'; END IF;
 RETURN rid;
END $$;

CREATE FUNCTION public.review_crew_report(p_report uuid,p_approve boolean,p_reason text DEFAULT NULL)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE r public.crew_daily_reports; p uuid; dr uuid; e jsonb; net numeric; BEGIN
 SELECT * INTO r FROM public.crew_daily_reports WHERE id=p_report FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Report not found'; END IF;
 SELECT project_id INTO p FROM public.project_crews WHERE id=r.crew_id;
 IF NOT coalesce(app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(p)),false)
 OR r.created_by=auth.uid() THEN RAISE EXCEPTION 'An independent approver is required'; END IF;
 PERFORM 1 FROM public.projects WHERE id=p AND status='active' FOR UPDATE;
 IF NOT FOUND OR r.status<>'submitted' THEN RAISE EXCEPTION 'Project or report is locked'; END IF;
 IF NOT p_approve THEN
   IF nullif(trim(p_reason),'') IS NULL THEN RAISE EXCEPTION 'Return reason is required'; END IF;
   UPDATE public.crew_daily_reports SET status='returned',review_notes=p_reason,
     reviewed_by=auth.uid(),reviewed_at=now() WHERE id=p_report; RETURN;
 END IF;
 SELECT id INTO dr FROM public.daily_reports WHERE project_id=p AND report_date=r.report_date FOR UPDATE;
 IF dr IS NULL THEN
   INSERT INTO public.daily_reports(project_id,report_date,supervisor_id,status)
   VALUES(p,r.report_date,auth.uid(),'draft') RETURNING id INTO dr;
 ELSIF EXISTS(SELECT 1 FROM public.daily_reports WHERE id=dr AND status IN ('submitted','approved')) THEN
   RAISE EXCEPTION 'Consolidated report is locked; reopen it before adding contributions';
 END IF;
 INSERT INTO app_private.crew_merge_authorizations VALUES(txid_current(),r.id);
 FOR e IN SELECT value FROM jsonb_array_elements(r.labor) LOOP
   -- Cross-project/day lock prevents duplicate worker hours across crews/projects.
   PERFORM pg_advisory_xact_lock(hashtext(e->>'worker_id'),hashtext(r.report_date::text));
   IF EXISTS(SELECT 1 FROM public.report_labor_logs l JOIN public.daily_reports d ON d.id=l.daily_report_id
     WHERE l.worker_id=(e->>'worker_id')::uuid AND d.report_date=r.report_date)
   THEN RAISE EXCEPTION 'Worker already has a time entry on this date'; END IF;
   net:=extract(epoch FROM (e->>'check_out_time')::time-(e->>'check_in_time')::time)/3600
        -(e->>'break_minutes')::numeric/60;
   INSERT INTO public.report_labor_logs(daily_report_id,worker_id,project_labor_id,
     check_in_time,check_out_time,break_minutes,total_net_hours,regular_hours,overtime_hours,crew_report_id)
   VALUES(dr,(e->>'worker_id')::uuid,(e->>'project_labor_id')::uuid,(e->>'check_in_time')::time,
     (e->>'check_out_time')::time,(e->>'break_minutes')::integer,net,least(8,net),greatest(0,net-8),r.id);
 END LOOP;
 FOR e IN SELECT value FROM jsonb_array_elements(r.machinery) LOOP
   PERFORM pg_advisory_xact_lock(hashtext(e->>'project_machinery_id'),hashtext(r.report_date::text));
   IF EXISTS(SELECT 1 FROM public.report_machinery_logs l WHERE l.daily_report_id=dr
     AND l.project_machinery_id=(e->>'project_machinery_id')::uuid)
   THEN RAISE EXCEPTION 'Machinery already has an entry on this date'; END IF;
   INSERT INTO public.report_machinery_logs(daily_report_id,machinery_id,project_machinery_id,operator_id,
     start_meter,end_meter,total_hours,production_value,production_unit,crew_report_id)
   SELECT dr,machinery_id,id,(e->>'operator_id')::uuid,(e->>'start_meter')::numeric,
     (e->>'end_meter')::numeric,(e->>'end_meter')::numeric-(e->>'start_meter')::numeric,
     coalesce((e->>'production_value')::numeric,0),e->>'production_unit',r.id
   FROM public.project_machinery WHERE id=(e->>'project_machinery_id')::uuid AND project_id=p;
 END LOOP;
 FOR e IN SELECT value FROM jsonb_array_elements(r.materials) LOOP
   INSERT INTO public.report_material_usage(daily_report_id,material_id,project_material_id,quantity_used,crew_report_id)
   SELECT dr,material_id,id,(e->>'quantity_used')::numeric,r.id FROM public.project_materials
   WHERE id=(e->>'project_material_id')::uuid AND project_id=p;
 END LOOP;
 UPDATE public.crew_daily_reports SET status='approved',daily_report_id=dr,
 reviewed_by=auth.uid(),reviewed_at=now() WHERE id=p_report;
 DELETE FROM app_private.crew_merge_authorizations WHERE transaction_id=txid_current() AND report_id=r.id;
END $$;

CREATE FUNCTION public.get_operational_hours(p_crew uuid,p_start date,p_end date)
 RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE p uuid; BEGIN
 SELECT project_id INTO p FROM public.project_crews WHERE id=p_crew;
 IF NOT coalesce(app_private.leads(p_crew) OR app_private.is_admin() OR
 (app_private.role()='Supervisor' AND app_private.project_access(p)),false)
 THEN RAISE EXCEPTION 'Access denied'; END IF;
 RETURN coalesce((SELECT jsonb_agg(jsonb_build_object('date',r.report_date,'worker',w.full_name,
 'check_in',l.check_in_time,'check_out',l.check_out_time,'break_minutes',l.break_minutes,
 'hours',l.total_net_hours,'status',d.status) ORDER BY r.report_date,w.full_name)
 FROM public.report_labor_logs l JOIN public.crew_daily_reports r ON r.id=l.crew_report_id
 JOIN public.daily_reports d ON d.id=l.daily_report_id JOIN public.workers w ON w.id=l.worker_id
 WHERE r.crew_id=p_crew AND r.report_date BETWEEN p_start AND p_end
 AND (app_private.role()<>'Foreman' OR r.created_by=auth.uid())),'[]'::jsonb);
END $$;

-- Guard state transitions and retain consolidated contributions during wizard saves.
CREATE FUNCTION app_private.guard_report() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$ BEGIN
 IF TG_OP='DELETE' THEN
   IF OLD.status='approved' THEN RAISE EXCEPTION 'Approved reports cannot be deleted'; END IF;
   RETURN OLD;
 END IF;
 IF TG_OP='UPDATE' THEN
   IF NEW.project_id<>OLD.project_id OR NEW.report_date<>OLD.report_date OR NEW.supervisor_id<>OLD.supervisor_id
   THEN RAISE EXCEPTION 'Report identity cannot be changed'; END IF;
   IF OLD.status='approved' THEN
     IF NOT app_private.is_admin() OR NEW.status<>'draft' OR nullif(trim(NEW.general_notes),'') IS NULL
     THEN RAISE EXCEPTION 'Administrator must reopen with a reason'; END IF;
   ELSIF NEW.status IN ('approved','rejected') AND NEW.status IS DISTINCT FROM OLD.status THEN
     IF OLD.status<>'submitted' OR auth.uid()=OLD.supervisor_id OR
       NOT (app_private.is_admin() OR (app_private.role()='Supervisor' AND app_private.project_access(OLD.project_id)))
     THEN RAISE EXCEPTION 'An independent approver is required'; END IF;
     NEW.approved_by:=auth.uid(); NEW.approved_at:=now();
   ELSIF OLD.status='submitted' AND NEW.status<>'rejected' THEN
     RAISE EXCEPTION 'Submitted report is locked';
   END IF;
 ELSIF NEW.status<>'draft' OR NEW.supervisor_id IS DISTINCT FROM auth.uid() THEN
   RAISE EXCEPTION 'New reports must be owned drafts';
 END IF; RETURN NEW;
END $$;
CREATE TRIGGER guard_daily_report BEFORE INSERT OR UPDATE OR DELETE ON public.daily_reports
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_report();

CREATE FUNCTION app_private.closed_scope(t text,r jsonb,depth integer DEFAULT 0)
 RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE fk record; parent jsonb; BEGIN
 IF depth>8 THEN RETURN false; END IF;
 IF t='projects' THEN RETURN EXISTS(SELECT 1 FROM public.projects WHERE id=(r->>'id')::uuid AND status='completed'); END IF;
 IF r->>'project_id' IS NOT NULL THEN
   RETURN EXISTS(SELECT 1 FROM public.projects WHERE id=(r->>'project_id')::uuid AND status='completed'); END IF;
 IF t='quotes' OR r->>'quote_id' IS NOT NULL THEN
   RETURN EXISTS(SELECT 1 FROM public.projects WHERE quote_id=(CASE WHEN t='quotes' THEN r->>'id' ELSE r->>'quote_id' END)::uuid AND status='completed'); END IF;
 FOR fk IN SELECT a.attname col,pc.relname parent_table,pa.attname parent_col
   FROM pg_catalog.pg_constraint c JOIN pg_catalog.pg_class tc ON tc.oid=c.conrelid
   JOIN pg_catalog.pg_namespace n ON n.oid=tc.relnamespace JOIN pg_catalog.pg_class pc ON pc.oid=c.confrelid
   JOIN pg_catalog.pg_attribute a ON a.attrelid=tc.oid AND a.attnum=c.conkey[1]
   JOIN pg_catalog.pg_attribute pa ON pa.attrelid=pc.oid AND pa.attnum=c.confkey[1]
   WHERE c.contype='f' AND n.nspname='public' AND tc.relname=t
   AND pc.relname IN ('projects','quotes','quote_services','quote_service_estimations','quote_service_labors',
   'quote_service_machineries','quote_service_materials','quote_service_instruments','project_labor',
   'project_machinery','project_materials','project_instruments','daily_reports')
 LOOP
   IF r->>fk.col IS NOT NULL THEN
     EXECUTE format('SELECT to_jsonb(x) FROM public.%I x WHERE %I::text=$1',fk.parent_table,fk.parent_col)
     INTO parent USING r->>fk.col;
     IF parent IS NOT NULL AND app_private.closed_scope(fk.parent_table,parent,depth+1) THEN RETURN true; END IF;
   END IF;
 END LOOP; RETURN false;
END $$;

CREATE FUNCTION app_private.quote_for_row(t text,r jsonb) RETURNS uuid LANGUAGE plpgsql STABLE
 SECURITY DEFINER SET search_path = '' AS $$
DECLARE q uuid; BEGIN
 IF t='quotes' THEN RETURN (r->>'id')::uuid; END IF;
 IF r->>'quote_id' IS NOT NULL THEN RETURN (r->>'quote_id')::uuid; END IF;
 IF r->>'quote_service_id' IS NOT NULL THEN
   SELECT quote_id INTO q FROM public.quote_services WHERE id=(r->>'quote_service_id')::uuid;
 ELSIF r->>'estimation_id' IS NOT NULL THEN
   SELECT s.quote_id INTO q FROM public.quote_service_estimations e JOIN public.quote_services s ON s.id=e.quote_service_id
     WHERE e.id=(r->>'estimation_id')::uuid;
 END IF; RETURN q;
END $$;

CREATE FUNCTION app_private.guard_project_write() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$
DECLARE r jsonb; prior jsonb; pid uuid; qid uuid; BEGIN
 r:=CASE WHEN TG_OP='DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
 IF TG_TABLE_NAME LIKE 'quote%' AND NOT app_private.is_admin() AND EXISTS(
   SELECT 1 FROM public.quotes WHERE status IN ('accepted','approved') AND
    (id=app_private.quote_for_row(TG_TABLE_NAME,r) OR
    (TG_OP IN ('UPDATE','DELETE') AND id=app_private.quote_for_row(TG_TABLE_NAME,to_jsonb(OLD)))))
 THEN RAISE EXCEPTION 'Only administrators can modify authorized estimates'; END IF;
 IF TG_OP<>'DELETE' AND r->>'crew_report_id' IS NOT NULL AND NOT EXISTS(
   SELECT 1 FROM app_private.crew_merge_authorizations WHERE transaction_id=txid_current()
   AND report_id=(r->>'crew_report_id')::uuid)
 THEN RAISE EXCEPTION 'Crew entries must be incorporated by the review operation'; END IF;
 IF TG_TABLE_NAME<>'projects' AND (app_private.closed_scope(TG_TABLE_NAME,r) OR
   (TG_OP IN ('UPDATE','DELETE') AND app_private.closed_scope(TG_TABLE_NAME,to_jsonb(OLD))))
 THEN RAISE EXCEPTION 'Reopen the project before editing related records'; END IF;
 IF TG_OP IN ('UPDATE','DELETE') THEN
   prior:=to_jsonb(OLD);
   IF prior->>'daily_report_id' IS NOT NULL THEN
     IF EXISTS(SELECT 1 FROM public.daily_reports WHERE id=(prior->>'daily_report_id')::uuid
       AND status IN ('approved','submitted')) THEN RAISE EXCEPTION 'Original report is locked'; END IF;
     IF prior->>'crew_report_id' IS NOT NULL THEN
       RAISE EXCEPTION 'Approved crew contributions are immutable'; END IF;
   END IF;
 END IF;
 IF TG_TABLE_NAME='projects' THEN
   IF NOT app_private.is_admin() AND (TG_OP<>'UPDATE' OR
     (r - ARRAY['calculation_metadata','updated_at']) IS DISTINCT FROM
     (to_jsonb(OLD) - ARRAY['calculation_metadata','updated_at']))
   THEN RAISE EXCEPTION 'Only administrators manage project lifecycle'; END IF;
   pid:=(r->>'id')::uuid;
 ELSE pid:=(r->>'project_id')::uuid; END IF;
 IF pid IS NULL AND r->>'daily_report_id' IS NOT NULL THEN
   SELECT project_id INTO pid FROM public.daily_reports WHERE id=(r->>'daily_report_id')::uuid;
 END IF;
 IF pid IS NULL AND r->>'project_labor_id' IS NOT NULL THEN
   SELECT project_id INTO pid FROM public.project_labor WHERE id=(r->>'project_labor_id')::uuid;
 ELSIF pid IS NULL AND r->>'project_machinery_id' IS NOT NULL THEN
   SELECT project_id INTO pid FROM public.project_machinery WHERE id=(r->>'project_machinery_id')::uuid;
 ELSIF pid IS NULL AND r->>'project_instrument_id' IS NOT NULL THEN
   SELECT project_id INTO pid FROM public.project_instruments WHERE id=(r->>'project_instrument_id')::uuid;
 END IF;
 IF pid IS NOT NULL THEN
   IF (r->>'project_labor_id' IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_labor
     WHERE id=(r->>'project_labor_id')::uuid AND project_id=pid)) OR
      (r->>'project_machinery_id' IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_machinery
     WHERE id=(r->>'project_machinery_id')::uuid AND project_id=pid)) OR
      (r->>'project_material_id' IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_materials
     WHERE id=(r->>'project_material_id')::uuid AND project_id=pid)) OR
      (r->>'project_instrument_id' IS NOT NULL AND NOT EXISTS(SELECT 1 FROM public.project_instruments
     WHERE id=(r->>'project_instrument_id')::uuid AND project_id=pid))
   THEN RAISE EXCEPTION 'Resource and report must belong to the same project'; END IF;
 END IF;
 IF pid IS NULL AND r->>'daily_report_id' IS NOT NULL THEN
   SELECT project_id INTO pid FROM public.daily_reports WHERE id=(r->>'daily_report_id')::uuid;
   IF EXISTS(SELECT 1 FROM public.daily_reports WHERE id=(r->>'daily_report_id')::uuid
     AND status IN ('approved','submitted')) THEN RAISE EXCEPTION 'Report is locked'; END IF;
 END IF;
 IF EXISTS(SELECT 1 FROM public.projects WHERE id=pid AND status='completed') AND
   NOT (TG_TABLE_NAME='projects' AND app_private.is_admin() AND TG_OP='UPDATE' AND r->>'status'='active')
 THEN RAISE EXCEPTION 'Reopen the project before editing'; END IF;
 IF TG_TABLE_NAME='project_labor_assignments' AND TG_OP<>'DELETE' THEN
   PERFORM pg_advisory_xact_lock(hashtext(r->>'worker_id'),1678);
   IF EXISTS(SELECT 1 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id
     WHERE a.worker_id=(r->>'worker_id')::uuid AND a.id<>(r->>'id')::uuid AND l.project_id<>pid
     AND daterange(a.start_date,a.end_date,'[]') && daterange((r->>'start_date')::date,(r->>'end_date')::date,'[]'))
   THEN RAISE EXCEPTION 'Worker is already planned in another project during this interval'; END IF;
 END IF;
 IF TG_TABLE_NAME='quotes' AND NOT app_private.is_admin() THEN
   IF r->>'created_by' IS DISTINCT FROM (CASE WHEN TG_OP='INSERT' THEN auth.uid()::text ELSE OLD.created_by::text END)
     OR (r->>'status' IN ('accepted','approved') AND (TG_OP='INSERT' OR NEW.status IS DISTINCT FROM OLD.status))
     OR (TG_OP='UPDATE' AND OLD.status IN ('accepted','approved'))
   THEN RAISE EXCEPTION 'Only administrators authorize estimates'; END IF;
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $$;
-- Fixed role identifiers cannot be renamed/deleted: permissions never depend on
-- a free-form label created in the role management dialog.
CREATE FUNCTION app_private.protect_system_role() RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
 IF OLD.name IN ('Admin','Supervisor','Foreman') AND (TG_OP='DELETE' OR NEW.name<>OLD.name)
 THEN RAISE EXCEPTION 'System roles cannot be renamed or deleted'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $$;
CREATE TRIGGER protect_system_role BEFORE UPDATE OR DELETE ON public.roles
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_system_role();
CREATE FUNCTION app_private.protect_team_history() RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN
 IF TG_OP='DELETE' THEN RAISE EXCEPTION 'End the assignment instead of deleting history'; END IF;
 IF (to_jsonb(NEW)-ARRAY['valid_until']) IS DISTINCT FROM (to_jsonb(OLD)-ARRAY['valid_until'])
 THEN RAISE EXCEPTION 'End this assignment and create a new one to change its identity'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER protect_member_history BEFORE UPDATE OR DELETE ON public.project_members
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_team_history();
CREATE TRIGGER protect_leader_history BEFORE UPDATE OR DELETE ON public.crew_leaders
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_team_history();
CREATE TRIGGER protect_crew_member_history BEFORE UPDATE OR DELETE ON public.crew_members
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_team_history();
CREATE FUNCTION app_private.protect_crew_project() RETURNS trigger LANGUAGE plpgsql SET search_path = '' AS $$
BEGIN IF NEW.project_id<>OLD.project_id THEN RAISE EXCEPTION 'A crew cannot move between projects'; END IF; RETURN NEW; END $$;
CREATE TRIGGER protect_crew_project BEFORE UPDATE ON public.project_crews
 FOR EACH ROW EXECUTE FUNCTION app_private.protect_crew_project();
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['projects','quotes','quote_services','quote_service_labors','quote_service_machineries',
 'quote_service_materials','quote_service_instruments','quote_service_estimations','quote_service_estimation_resources',
 'project_labor','project_labor_assignments',
 'project_machinery','project_machinery_assignments','project_materials','project_instruments',
 'project_instrument_assignments','project_tasks','daily_reports','report_labor_logs','report_machinery_logs',
 'report_material_usage','project_baseline_snapshots','project_non_working_days',
 'machinery_inspections','material_receptions','instrument_inspections','labor_checkins'] LOOP
   IF to_regclass('public.'||t) IS NOT NULL THEN
     EXECUTE format('CREATE TRIGGER guard_project_write BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION app_private.guard_project_write()',t);
   END IF;
 END LOOP;
 FOREACH t IN ARRAY ARRAY['profiles','project_members','project_crews','crew_leaders','crew_members',
 'quote_members','crew_daily_reports','daily_reports','projects'] LOOP
   EXECUTE format('CREATE TRIGGER access_audit AFTER INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION app_private.audit()',t);
 END LOOP;
END $$;

-- Deletions of planning/resources are allowed only in the supervisor's scope;
-- lifecycle and user deletions remain admin-only.
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['quote_services','quote_service_machineries','quote_service_labors',
 'quote_service_materials','quote_service_instruments','quote_service_estimations','quote_service_estimation_resources',
 'project_labor_assignments','project_machinery_assignments','project_instrument_assignments',
 'report_labor_logs','report_machinery_logs','report_material_usage'] LOOP
   IF to_regclass('public.'||t) IS NOT NULL THEN
     EXECUTE format('CREATE POLICY scoped_delete ON public.%I FOR DELETE TO authenticated USING (app_private.table_access(%L,to_jsonb(%I),true))',t,t,t);
   END IF;
 END LOOP;
END $$;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA app_private FROM PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA app_private TO authenticated;
REVOKE ALL ON FUNCTION public.get_access_context(),public.get_crew_workspace(uuid,date),
 public.save_crew_report(uuid,date,text,jsonb,jsonb,jsonb,boolean),public.review_crew_report(uuid,boolean,text),
 public.get_operational_hours(uuid,date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.get_access_context(),public.get_crew_workspace(uuid,date),
 public.save_crew_report(uuid,date,text,jsonb,jsonb,jsonb,boolean),public.review_crew_report(uuid,boolean,text),
 public.get_operational_hours(uuid,date,date) TO authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON public.project_members,public.project_crews,public.crew_leaders,
 public.crew_members,public.quote_members,public.crew_daily_reports TO authenticated;
GRANT SELECT ON public.access_audit TO authenticated;
REVOKE INSERT,UPDATE,DELETE ON public.access_audit FROM authenticated,anon;
NOTIFY pgrst,'reload schema';
COMMIT;
