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

INSERT INTO public.machinery_inspections(id,project_machinery_id,internal_id,reception_date)
 VALUES('71000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','UNIT-1',current_date-1);
INSERT INTO public.machinery_inspections(id,project_machinery_id,internal_id,reception_date)
 VALUES('71000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001','UNIT-2',current_date-1);
INSERT INTO public.workers(id,full_name) VALUES('30000000-0000-0000-0000-000000000002','Second operator');
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000002',current_date-2,current_date+30);
INSERT INTO public.crew_members(crew_id,worker_id,valid_from,valid_until) VALUES
 ('50000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000002',current_date-2,current_date+30);

UPDATE public.quote_services SET unit_of_measure='CY' WHERE id='90000000-0000-0000-0000-000000000001';
UPDATE public.project_machinery SET is_principal=true,expected_quantity=2,quote_service_id='90000000-0000-0000-0000-000000000001',
 calculation_metadata='{"capacity":10,"trips_per_day":20}',start_date=current_date-2,end_date=current_date+10
 WHERE id='70000000-0000-0000-0000-000000000001';
INSERT INTO public.daily_reports(id,project_id,supervisor_id,report_date) VALUES
 ('88000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',current_date-1),
 ('88000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',current_date+1),
 ('88000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',current_date-2);
INSERT INTO public.report_machinery_logs(daily_report_id,project_machinery_id,machinery_id,machinery_inspection_id,production_value,operator_id)
 VALUES
 ('88000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001',11,'30000000-0000-0000-0000-000000000001'),
 ('88000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000002',3,'30000000-0000-0000-0000-000000000001'),
 ('88000000-0000-0000-0000-000000000001','70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001',null,5,'30000000-0000-0000-0000-000000000001'),
 ('88000000-0000-0000-0000-000000000002','70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001',999,'30000000-0000-0000-0000-000000000001'),
 ('88000000-0000-0000-0000-000000000003','70000000-0000-0000-0000-000000000001','60000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001',777,'30000000-0000-0000-0000-000000000001');
UPDATE public.daily_reports SET status='submitted' WHERE id::text LIKE '88000000%';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
UPDATE public.daily_reports SET status='rejected' WHERE id='88000000-0000-0000-0000-000000000003';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')->>'id' AS a \gset
SELECT public.save_daily_report_section(:'a',0,'Own capture',
 '[{"worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"09:00","check_out_time":"10:00","break_minutes":0}]',
 '[{"project_machinery_id":"70000000-0000-0000-0000-000000000001","machinery_id":"60000000-0000-0000-0000-000000000001","machinery_inspection_id":"71000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000001","operation_start":"09:00","operation_end":"10:00","start_meter":100,"end_meter":101,"production_value":4}]','[]',true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000005',true);
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')->>'id' AS b \gset
SELECT public.save_daily_report_section(:'b',0,'Other crew',
 '[{"worker_id":"30000000-0000-0000-0000-000000000002","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"10:00","check_out_time":"11:00","break_minutes":0}]',
 '[{"project_machinery_id":"70000000-0000-0000-0000-000000000001","machinery_id":"60000000-0000-0000-0000-000000000001","machinery_inspection_id":"71000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000002","operation_start":"10:00","operation_end":"11:00","start_meter":101,"end_meter":102,"production_value":7}]','[]',true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.assert_true((SELECT sum((x->>'today_other')::numeric)=7 FROM jsonb_array_elements(public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')->'machinery'->0->'actual') x),'submitted other crew contributes once to operational progress');
SELECT pg_temp.assert_true((SELECT sum((x->>'before')::numeric)=30 FROM jsonb_array_elements(public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date+1,'50000000-0000-0000-0000-000000000001')->'machinery'->0->'actual') x),'next day includes submitted crew history plus legacy production');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SELECT public.review_daily_report_section(:'a',true);
SELECT public.review_daily_report_section(:'b',true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')::text AS progress \gset
SELECT pg_temp.assert_true((SELECT sum((x->>'before')::numeric)=19 AND sum((x->>'today_other')::numeric)=7 FROM jsonb_array_elements(:'progress'::jsonb->'machinery'->0->'actual') x),'date cutoff, rejected exclusion and own section exclusion');
SELECT pg_temp.assert_true((SELECT (x->>'before')::numeric=11 AND (x->>'today_other')::numeric=7 FROM jsonb_array_elements(:'progress'::jsonb->'machinery'->0->'actual') x WHERE x->>'unit_id'='71000000-0000-0000-0000-000000000001'),'history keyed by physical identity');
SELECT pg_temp.assert_true(NOT (:'progress' ~ 'hourly_rate|cost|salary|operator_id|created_by|rate_override'),'operational response contains no financial or other crew identities');
SELECT pg_temp.assert_true(:'progress'::jsonb->'machinery'->0->>'unit'='CY' AND (:'progress'::jsonb->'machinery'->0->>'trips_per_day')::numeric=20 AND (:'progress'::jsonb->'machinery'->0->>'capacity_per_trip')::numeric=10,'service units and production targets supplied together');
SELECT pg_temp.assert_true(public.get_daily_execution_planned_workspace('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001') ? 'machinery_progress','workspace carries progress snapshot');
SELECT pg_temp.denied($q$SELECT public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000002',current_date,'50000000-0000-0000-0000-000000000001')$q$,'cross-project request denied');
SELECT pg_temp.denied($q$SELECT public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')$q$,'other crew denied');
SELECT pg_temp.denied($q$SELECT public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date,null)$q$,'Foreman consolidated scope denied');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SELECT pg_temp.denied($q$SELECT public.get_daily_machinery_progress('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')$q$,'pending account denied');
RESET ROLE;
SELECT 'Daily machinery progress tests passed';
ROLLBACK;
