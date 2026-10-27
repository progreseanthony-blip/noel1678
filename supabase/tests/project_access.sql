-- Run ONLY in an isolated database with the project schema + both access migrations.
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
INSERT INTO public.project_crews(id,project_id,name) VALUES
 ('50000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','Crew A'),
 ('50000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','Crew B');
INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from) VALUES
 ('50000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003',current_date-2),
 ('50000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000005',current_date-2);
INSERT INTO public.crew_members(crew_id,worker_id,valid_from,valid_until) VALUES
 ('50000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001',current_date-2,current_date+30);
SELECT pg_temp.denied($q$INSERT INTO public.crew_members(crew_id,worker_id,valid_until) VALUES
 ('50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001',current_date+3)$q$,'overlapping crew membership');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.projects),'pending project access denied');
SELECT pg_temp.assert_true(public.get_access_context()->>'role' IS NULL,'pending role denied');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.projects),'supervisor sees assigned project only');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.project_labor),'supervisor sees scoped labor');
SELECT pg_temp.denied($q$INSERT INTO public.report_labor_logs(daily_report_id,worker_id,project_labor_id,check_in_time)
 VALUES('80000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001',
 '40000000-0000-0000-0000-000000000001','07:00')$q$,'cannot authorize foreign report through own resource');
SELECT pg_temp.denied($q$INSERT INTO public.project_members(project_id,profile_id,responsibility) VALUES
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Supervisor')$q$,'supervisor cannot assign self');
SELECT pg_temp.denied($q$UPDATE public.profiles SET role='Admin' WHERE id=auth.uid()$q$,'self promotion');
SELECT pg_temp.denied($q$UPDATE public.projects SET status='completed' WHERE id='20000000-0000-0000-0000-000000000001'$q$,'supervisor lifecycle change');
SELECT pg_temp.denied($q$INSERT INTO public.roles(name) VALUES('Injected')$q$,'role administration');
SELECT pg_temp.denied($q$INSERT INTO public.quotes(title) VALUES('Forbidden supervisor draft')$q$,'supervisor cannot create estimates');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.quotes),'planning source readable; legacy ownership and quote_members grant no access');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.quote_services),'planning source services readable');
WITH modified AS (UPDATE public.quotes SET status='draft' WHERE id='91000000-0000-0000-0000-000000000001' RETURNING id)
 SELECT pg_temp.assert_true((SELECT count(*)=0 FROM modified),'supervisor cannot edit estimate');
WITH modified AS (UPDATE public.quote_services SET quantity=99 WHERE id='90000000-0000-0000-0000-000000000001' RETURNING id)
 SELECT pg_temp.assert_true((SELECT count(*)=0 FROM modified),'supervisor cannot edit estimate resources');
WITH removed AS (DELETE FROM public.quote_services WHERE id='90000000-0000-0000-0000-000000000001' RETURNING id)
 SELECT pg_temp.assert_true((SELECT count(*)=0 FROM removed),'supervisor cannot delete estimate resources');
INSERT INTO public.project_crews(id,project_id,name) VALUES
 ('50000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','Supervisor crew');
SELECT pg_temp.denied($q$INSERT INTO public.project_crews(project_id,name) VALUES
 ('20000000-0000-0000-0000-000000000002','Forbidden crew')$q$,'supervisor cannot organize another project');
SELECT pg_temp.denied($q$INSERT INTO public.project_members(project_id,profile_id,responsibility) VALUES
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000004','Foreman')$q$,'supervisor cannot authorize people');
SELECT pg_temp.denied($q$INSERT INTO public.crew_leaders(crew_id,profile_id) VALUES
 ('50000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000004')$q$,'leader must already be an authorized Foreman');
INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from) VALUES
 ('50000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000003',current_date+1);
UPDATE public.crew_members SET valid_until=current_date WHERE crew_id='50000000-0000-0000-0000-000000000001';
INSERT INTO public.crew_members(crew_id,worker_id,valid_from,valid_until) VALUES
 ('50000000-0000-0000-0000-000000000003','30000000-0000-0000-0000-000000000001',current_date+1,current_date+30);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.crew_members WHERE crew_id='50000000-0000-0000-0000-000000000003'),'supervisor can move a planned worker with history');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.workers),'foreman cannot read raw worker/rate joins');
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.payroll_periods),'foreman cannot read payroll');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_crew_workspace())=1,'only own crew');
SELECT pg_temp.denied($q$SELECT public.get_crew_workspace('50000000-0000-0000-0000-000000000002')$q$,'other crew workspace');
SELECT pg_temp.denied($q$SELECT public.save_crew_report('50000000-0000-0000-0000-000000000001',current_date,'',
 '[{"worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"16:00","check_out_time":"07:00","break_minutes":30}]')$q$,'invalid shift');
SELECT public.save_crew_report('50000000-0000-0000-0000-000000000001',current_date,'Work completed',
 '[{"worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"07:00","check_out_time":"16:00","break_minutes":30}]',
 '[{"project_machinery_id":"70000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000001","start_meter":100,"end_meter":108,"production_value":25,"production_unit":"m3"}]',
 '[{"project_material_id":"70000000-0000-0000-0000-000000000002","quantity_used":3}]',true);
SELECT pg_temp.denied($q$SELECT public.save_crew_report('50000000-0000-0000-0000-000000000001',current_date,'Changed','[]')$q$,'submitted contribution immutable');
SELECT pg_temp.denied($q$SELECT public.get_operational_hours('50000000-0000-0000-0000-000000000002',current_date-1,current_date)$q$,'other crew hours');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT public.review_crew_report(id,true) FROM public.crew_daily_reports;
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.report_labor_logs),'merged exactly one time entry');
SELECT pg_temp.assert_true((SELECT total_net_hours=8.5 FROM public.report_labor_logs),'net hours calculated on server');
SELECT pg_temp.assert_true((SELECT total_hours=8 AND production_value=25 FROM public.report_machinery_logs),'machinery and production merged');
SELECT pg_temp.assert_true((SELECT quantity_used=3 FROM public.report_material_usage),'material consumption merged');
SELECT pg_temp.denied($q$DELETE FROM public.report_labor_logs WHERE crew_report_id IS NOT NULL$q$,'crew entries cannot be deleted by wizard');
SELECT pg_temp.denied($q$SELECT public.review_crew_report(id,true) FROM public.crew_daily_reports$q$,'duplicate approval');
UPDATE public.daily_reports SET status='submitted';
SELECT pg_temp.denied($q$UPDATE public.daily_reports SET status='approved'$q$,'own consolidated report approval');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
UPDATE public.daily_reports SET status='approved' WHERE project_id='20000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$UPDATE public.report_labor_logs SET total_net_hours=99$q$,'approved report detail immutable');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.assert_true(jsonb_array_length(public.get_operational_hours('50000000-0000-0000-0000-000000000001',current_date,current_date))=1,'foreman approved hours');
SELECT pg_temp.assert_true(NOT (public.get_operational_hours('50000000-0000-0000-0000-000000000001',current_date,current_date)::text ~ 'rate|cost|salary'),'operational export contains no costs');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
UPDATE public.projects SET status='completed' WHERE id='20000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$UPDATE public.project_labor SET expected_employees=5$q$,'completed project edits');
SELECT pg_temp.assert_true((SELECT count(*)>0 FROM public.access_audit),'audit entries');
SELECT pg_temp.denied($q$DELETE FROM public.crew_members$q$,'membership history retained');
SELECT pg_temp.denied($q$UPDATE public.roles SET name='Owner' WHERE name='Foreman'$q$,'system role immutable');
SELECT pg_temp.denied($q$UPDATE public.profiles SET access_status='disabled' WHERE role='Admin'$q$,'last administrator protected');
RESET ROLE;
SELECT 'Access integration tests passed' AS result;
ROLLBACK;
