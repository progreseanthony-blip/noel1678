-- Follow-up to the already applied access migration. Preserve all assignments.
BEGIN;

-- Source estimate data is read only and only through assigned projects.
-- Owning an old draft or a quote_members row no longer grants Supervisor access.
CREATE OR REPLACE FUNCTION app_private.quote_access(p_id uuid) RETURNS boolean LANGUAGE sql STABLE
 SECURITY DEFINER SET search_path = '' AS $$
 SELECT app_private.is_admin() OR (app_private.role()='Supervisor' AND EXISTS(
   SELECT 1 FROM public.projects WHERE quote_id=p_id AND app_private.project_access(id)))
$$;
DROP POLICY IF EXISTS own_quote ON public.quotes;

CREATE FUNCTION app_private.organize_project_team(p_id uuid) RETURNS boolean LANGUAGE sql STABLE
 SECURITY DEFINER SET search_path = '' AS $$
 SELECT (app_private.is_admin() OR
   (app_private.role()='Supervisor' AND app_private.project_access(p_id)))
   AND EXISTS(SELECT 1 FROM public.projects WHERE id=p_id AND status='active')
$$;

CREATE OR REPLACE FUNCTION app_private.table_access(t text,r jsonb,writing boolean)
 RETURNS boolean LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = '' AS $$
DECLARE p uuid; BEGIN
 IF app_private.is_admin() THEN RETURN true; END IF;
 IF t='profiles' THEN RETURN NOT writing AND (r->>'id'=auth.uid()::text OR
   (app_private.role()='Supervisor' AND EXISTS(SELECT 1 FROM public.project_members m
     WHERE m.profile_id=(r->>'id')::uuid AND app_private.project_access(m.project_id)))); END IF;
 IF app_private.role() IS DISTINCT FROM 'Supervisor' THEN RETURN false; END IF;
 IF t=ANY(ARRAY['roles','workers','labor_roles','machinery','materials','instruments','customers',
 'services','units','logistics_equipment','logistics_applications','machinery_applications',
 'deviation_reasons','disruption_reasons']) THEN RETURN NOT writing; END IF;
 IF t=ANY(ARRAY['project_members','crew_daily_reports']) THEN
   RETURN NOT writing AND app_private.row_scope(t,r); END IF;
 IF t=ANY(ARRAY['project_crews','crew_leaders','crew_members']) THEN
   IF NOT writing THEN RETURN app_private.row_scope(t,r); END IF;
   IF t='project_crews' THEN p:=(r->>'project_id')::uuid;
   ELSE SELECT project_id INTO p FROM public.project_crews WHERE id=(r->>'crew_id')::uuid; END IF;
   RETURN coalesce(app_private.organize_project_team(p),false);
 END IF;
 IF t=ANY(ARRAY['quotes','quote_services','quote_service_machineries','quote_service_labors',
 'quote_service_materials','quote_service_instruments','quote_service_estimations','quote_service_estimation_resources'])
 THEN RETURN NOT writing AND app_private.row_scope(t,r); END IF;
 IF t=ANY(ARRAY['projects','project_services','project_labor','project_labor_assignments',
 'project_machinery','project_machinery_assignments','project_materials','project_instruments',
 'project_instrument_assignments','project_tasks','daily_reports','report_labor_logs',
 'report_machinery_logs','report_material_usage','project_baseline_snapshots','project_non_working_days'])
 THEN RETURN app_private.row_scope(t,r); END IF;
 RETURN false;
END $$;

-- Keep project/crew history immutable and prevent changing closed teams even
-- through direct API requests. Role/project authorization is still admin-only.
CREATE FUNCTION app_private.guard_team_planning() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER
 SET search_path = '' AS $$
DECLARE r jsonb; p uuid; BEGIN
 r:=CASE WHEN TG_OP='DELETE' THEN to_jsonb(OLD) ELSE to_jsonb(NEW) END;
 IF TG_TABLE_NAME IN ('project_members','project_crews') THEN p:=(r->>'project_id')::uuid;
 ELSE SELECT project_id INTO p FROM public.project_crews WHERE id=(r->>'crew_id')::uuid; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.projects WHERE id=p AND status='active')
 THEN RAISE EXCEPTION 'Project team is read only until the project is active'; END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF; RETURN NEW;
END $$;
DO $$ DECLARE t text; BEGIN
 FOREACH t IN ARRAY ARRAY['project_members','project_crews','crew_leaders','crew_members'] LOOP
   EXECUTE format('CREATE TRIGGER guard_team_planning BEFORE INSERT OR UPDATE OR DELETE ON public.%I FOR EACH ROW EXECUTE FUNCTION app_private.guard_team_planning()',t);
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION app_private.organize_project_team(uuid),app_private.guard_team_planning() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION app_private.organize_project_team(uuid),app_private.guard_team_planning() TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
