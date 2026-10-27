-- Run ONLY in an isolated database with the project schema + all three access/execution migrations.
-- All fixture data and test helpers are rolled back.
\set ON_ERROR_STOP on
BEGIN;
-- Schema-only restores may omit Supabase's default API grants.
GRANT USAGE ON SCHEMA public,auth TO authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
CREATE FUNCTION pg_temp.assert_true(ok boolean, label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF ok IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF; END $$;
CREATE FUNCTION pg_temp.denied(command text, label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
 BEGIN EXECUTE command;
 EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'PASS (denied): %',label; RETURN; END;
 RAISE EXCEPTION 'FAIL (allowed): %',label;
END $$;
INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
 ('10000000-0000-0000-0000-000000000001','admin@example.test','{}'),
 ('10000000-0000-0000-0000-000000000002','supervisor@example.test','{}'),
 ('10000000-0000-0000-0000-000000000003','foreman@example.test','{}'),
 ('10000000-0000-0000-0000-000000000004','pending@example.test','{}'),
 ('10000000-0000-0000-0000-000000000005','otherforeman@example.test','{}');
SELECT pg_temp.assert_true((SELECT access_status='pending' FROM public.profiles WHERE id='10000000-0000-0000-0000-000000000004'),'new accounts pending');
UPDATE public.profiles SET role=CASE right(id::text,1) WHEN '1' THEN 'Admin' WHEN '2' THEN 'Supervisor' ELSE 'Foreman' END,access_status='active'
 WHERE right(id::text,1)<>'4';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
INSERT INTO public.projects(id,title) VALUES
 ('20000000-0000-0000-0000-000000000001','Assigned'),('20000000-0000-0000-0000-000000000002','Other');
-- Legacy fixture estimates retain their original team requirements.
INSERT INTO public.quotes(id,title,created_by,team_planning_required,team_sharing_enabled) VALUES
 ('91000000-0000-0000-0000-000000000001','Planning source','10000000-0000-0000-0000-000000000001',false,false),
 ('91000000-0000-0000-0000-000000000002','Legacy supervisor draft','10000000-0000-0000-0000-000000000002',false,false);
INSERT INTO public.quote_members(quote_id,profile_id) VALUES
 ('91000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002');
INSERT INTO public.quote_services(id,quote_id,name) VALUES
 ('90000000-0000-0000-0000-000000000001','91000000-0000-0000-0000-000000000001','Estimated service');
UPDATE public.projects SET quote_id='91000000-0000-0000-0000-000000000001' WHERE id='20000000-0000-0000-0000-000000000001';
UPDATE public.quotes SET status='accepted' WHERE id='91000000-0000-0000-0000-000000000001';
INSERT INTO public.workers(id,full_name) VALUES('30000000-0000-0000-0000-000000000001','Worker');
INSERT INTO public.project_labor(id,project_id,role_name) VALUES
 ('40000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Labor'),
 ('40000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002','Other labor');
INSERT INTO public.daily_reports(id,project_id,supervisor_id,report_date) VALUES
 ('80000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000001',current_date);
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',current_date-2,current_date+30);
INSERT INTO public.machinery(id,description) VALUES('60000000-0000-0000-0000-000000000001','Test machine');
INSERT INTO public.materials(id,description) VALUES('60000000-0000-0000-0000-000000000002','Test material');
INSERT INTO public.project_machinery(id,project_id,machinery_name,machinery_id) VALUES
 ('70000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Planned machine','60000000-0000-0000-0000-000000000001');
INSERT INTO public.project_materials(id,project_id,material_name,material_id) VALUES
 ('70000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','Planned material','60000000-0000-0000-0000-000000000002');
INSERT INTO public.project_members(project_id,profile_id,responsibility,valid_from) VALUES
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','Supervisor',current_date-2),
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','Foreman',current_date-2),
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005','Foreman',current_date-2);

UPDATE public.project_labor SET quote_service_id='90000000-0000-0000-0000-000000000001' WHERE id='40000000-0000-0000-0000-000000000001';
INSERT INTO public.workers(id,full_name) VALUES ('30000000-0000-0000-0000-000000000003','Third'),('30000000-0000-0000-0000-000000000004','Fourth');
INSERT INTO public.project_labor(id,project_id,role_name,quote_service_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','Labor','90000000-0000-0000-0000-000000000001',current_date-2,current_date+30);
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000003',current_date,current_date+20);
INSERT INTO public.project_services(id,project_id,name) VALUES
 ('92000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','CO only');
INSERT INTO public.project_labor(id,project_id,role_name,project_service_id) VALUES
 ('40000000-0000-0000-0000-000000000004','20000000-0000-0000-0000-000000000001','Labor','92000000-0000-0000-0000-000000000001');

-- Authorized planning exposes only booking context, not foreign project access.
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000004',current_date,current_date+10);
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true(EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date,current_date+2)) b WHERE b->>'worker_id'='30000000-0000-0000-0000-000000000004' AND b->>'project_title'='Other'),'foreign-project booking includes its project name');
SELECT pg_temp.assert_true(EXISTS(SELECT 1 FROM jsonb_array_elements(public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date+30,current_date+30)) b WHERE b->>'worker_id'='30000000-0000-0000-0000-000000000001'),'last day of existing booking is inclusive');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date+31,current_date+35))=0,'worker available after all bookings end');
SELECT pg_temp.assert_true(NOT(public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date,current_date+2)::text ~ 'rate|cost|quote_id|calculation_metadata'),'no financial or internal project fields');
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.projects WHERE id='20000000-0000-0000-0000-000000000002'),'booking name does not grant access to foreign project');

SELECT pg_temp.denied($q$SELECT public.get_labor_worker_availability('20000000-0000-0000-0000-000000000002',current_date,current_date+2)$q$,'supervisor cannot use an unassigned project as authorization');
SELECT pg_temp.denied($q$SELECT public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date+2,current_date)$q$,'invalid period denied');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.get_labor_worker_availability('20000000-0000-0000-0000-000000000001',current_date,current_date+2)$q$,'foreman cannot access planning availability');
ROLLBACK;
