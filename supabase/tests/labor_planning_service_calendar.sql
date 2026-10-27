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

INSERT INTO public.quote_service_estimations(id,quote_service_id,start_date,end_date,total_working_days,updated_at) VALUES
 ('93000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001','2026-10-01','2026-10-20',15,'2026-10-01'),
 ('93000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000001','2026-10-05','2026-10-25',17.5,'2026-10-02');
INSERT INTO public.project_tasks(project_id,project_service_id,name,planned_start_date,planned_end_date) VALUES
 ('20000000-0000-0000-0000-000000000001','92000000-0000-0000-0000-000000000001','CO task','2026-11-01','2026-11-20');
INSERT INTO public.project_non_working_days(project_id,date,partial_ratio) VALUES
 ('20000000-0000-0000-0000-000000000001','2026-10-12',1);
INSERT INTO public.roles(id,name) VALUES('94000000-0000-0000-0000-000000000001','Estimation role');
INSERT INTO public.quote_service_labors(id,quote_service_id,role_id,role_name,months_to_work,employees_quantity,hourly_rate,per_diem) VALUES
 ('95000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000001','Indirect role',1,1,10,0);
INSERT INTO public.project_labor(id,project_id,quote_service_labor_id,role_name) VALUES
 ('40000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000001','95000000-0000-0000-0000-000000000001','Indirect role');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true((SELECT bool_and(l->>'reference_start'='2026-10-05' AND l->>'reference_end'='2026-10-25' AND l->>'working_days'='17.5' AND l->>'reference_source'='estimation')
 FROM jsonb_array_elements(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')->'labor') l WHERE l->>'service_key'='q:90000000-0000-0000-0000-000000000001'),'latest service estimation used consistently');
SELECT pg_temp.assert_true((SELECT l->>'reference_start'='2026-11-01' AND l->>'reference_source'='service_plan'
 FROM jsonb_array_elements(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')->'labor') l WHERE l->>'id'='40000000-0000-0000-0000-000000000004'),'CO-only uses its own service calendar');
SELECT pg_temp.assert_true((SELECT l->>'reference_start'='2026-10-05' AND l->>'role_id' IS NULL
 AND l->>'reference_service_name'='Estimated service'
 FROM jsonb_array_elements(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')->'labor') l WHERE l->>'id'='40000000-0000-0000-0000-000000000005'),'indirect relation supplies service dates without mixing role catalogs');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')->'non_working_days')=1,'project working calendar available');
SELECT pg_temp.assert_true(NOT(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')::text ~ 'hourly_rate|internal_cost|direct_cost'),'reference payload has no financial fields');
SELECT pg_temp.denied($q$SELECT public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000002')$q$,'other project denied');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000001')$q$,'foreman planning denied');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SELECT pg_temp.assert_true((SELECT l->>'reference_start' IS NULL AND l->>'reference_end' IS NULL
 FROM jsonb_array_elements(public.get_labor_crew_planning_calendar('20000000-0000-0000-0000-000000000002')->'labor') l),'general labor does not inherit another service calendar');
ROLLBACK;
