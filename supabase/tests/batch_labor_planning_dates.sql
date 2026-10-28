-- Isolated schema-only test database; all fixtures are rolled back.
\set ON_ERROR_STOP on
BEGIN;
CREATE FUNCTION pg_temp.assert_true(ok boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF; END $$;
CREATE FUNCTION pg_temp.denied(command text,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 BEGIN EXECUTE command;
 EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'PASS (denied): %',label; RETURN; END;
 RAISE EXCEPTION 'FAIL (allowed): %',label;
END $$;
INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
 ('10000000-0000-0000-0000-000000000001','batch-admin@example.test','{}'),
 ('10000000-0000-0000-0000-000000000002','batch-foreman@example.test','{}');
UPDATE public.profiles SET role=CASE right(id::text,1) WHEN '1' THEN 'Admin' ELSE 'Foreman' END,access_status='active';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
INSERT INTO public.projects(id,title) VALUES
 ('20000000-0000-0000-0000-000000000001','Batch'),('20000000-0000-0000-0000-000000000002','Other');
INSERT INTO public.workers(id,full_name) VALUES
 ('30000000-0000-0000-0000-000000000001','First'),('30000000-0000-0000-0000-000000000002','Second');
INSERT INTO public.project_labor(id,project_id,role_name) VALUES
 ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Operator'),
 ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','Labor'),
 ('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000002','Labor');
INSERT INTO public.project_labor_assignments(id,project_labor_id,worker_id,start_date,end_date) VALUES
 ('50000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',current_date,current_date+5),
 ('50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002',current_date,current_date+5),
 ('50000000-0000-0000-0000-000000000003','40000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000002',current_date+8,current_date+10);
CREATE FUNCTION pg_temp.selection() RETURNS uuid[] LANGUAGE sql AS $$
 SELECT ARRAY['50000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000002']::uuid[] $$;
SET LOCAL ROLE authenticated;
SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date,current_date+7);
RESET ROLE;
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_labor_assignments WHERE id=ANY(pg_temp.selection()) AND end_date=current_date+7),'all selected periods updated');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date,current_date+9)$q$,'second worker overlaps another project');
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_labor_assignments WHERE id=ANY(pg_temp.selection()) AND end_date=current_date+7),'failure rolls back first worker too');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',ARRAY['50000000-0000-0000-0000-000000000003']::uuid[],current_date,current_date+7)$q$,'foreign project assignment rejected');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',ARRAY[]::uuid[],current_date,current_date+7)$q$,'empty selection rejected');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',ARRAY[NULL]::uuid[],current_date,current_date+7)$q$,'null assignment rejected');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',ARRAY['50000000-0000-0000-0000-000000000001','50000000-0000-0000-0000-000000000001']::uuid[],current_date,current_date+7)$q$,'duplicate selection rejected');
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date+1,current_date)$q$,'invalid interval rejected');
-- The original trigger must still preserve crew-linked planning dates.
INSERT INTO public.project_crews(id,project_id,name) VALUES
 ('60000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Crew');
INSERT INTO public.crew_service_assignments(id,crew_id,project_id,service_key,valid_from,valid_until) VALUES
 ('70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','u:20000000-0000-0000-0000-000000000001',current_date,current_date+7);
INSERT INTO public.crew_members(crew_id,worker_id,labor_assignment_id,crew_service_assignment_id,valid_from,valid_until) VALUES
 ('60000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002','50000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001',current_date,current_date+7);
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date,current_date+6)$q$,'crew history prevents shortening');
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_labor_assignments WHERE id=ANY(pg_temp.selection()) AND end_date=current_date+7),'history rejection rolls back batch');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date,current_date+7)$q$,'foreman cannot edit planning');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
UPDATE public.projects SET status='completed' WHERE id='20000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$SELECT public.update_labor_crew_dates_batch('20000000-0000-0000-0000-000000000001',pg_temp.selection(),current_date,current_date+7)$q$,'completed project read only');
SELECT pg_temp.assert_true(NOT has_function_privilege('anon','public.update_labor_crew_dates_batch(uuid,uuid[],date,date)','EXECUTE'),'anonymous execution denied');
ROLLBACK;
