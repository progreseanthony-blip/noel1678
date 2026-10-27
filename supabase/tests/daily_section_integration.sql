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

UPDATE public.projects SET calculation_metadata='{"baseline_frozen":true}';
INSERT INTO public.daily_reports(id,project_id,supervisor_id,report_date) VALUES
 ('80000000-0000-0000-0000-000000000003','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',current_date-1);
INSERT INTO public.report_labor_logs(id,daily_report_id,worker_id,project_labor_id,check_in_time,check_out_time,total_net_hours)
 VALUES('81000000-0000-0000-0000-000000000009','80000000-0000-0000-0000-000000000003',
 '30000000-0000-0000-0000-000000000001','40000000-0000-0000-0000-000000000001','07:00','15:00',7.5);

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_operation_projects())=0,'pending gets no operational project');
SELECT pg_temp.denied($q$SELECT public.get_daily_operation_reports('20000000-0000-0000-0000-000000000001')$q$,'pending cannot list reports');
SELECT pg_temp.denied($q$SELECT public.get_daily_report_entry_context('20000000-0000-0000-0000-000000000001')$q$,'pending cannot enter wizard');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_operation_projects())=1,'foreman lists only assigned project with a current crew');
SELECT pg_temp.assert_true(NOT(public.get_daily_operation_projects()::text ~ 'cost|rate|quote_id|calculation_metadata'),'project picker contains no financial payload');
SELECT pg_temp.denied($q$SELECT public.get_daily_operation_reports('20000000-0000-0000-0000-000000000002')$q$,'foreman cannot list other project reports');
SELECT pg_temp.denied($q$SELECT public.get_daily_report_entry_context('20000000-0000-0000-0000-000000000001',current_date,'80000000-0000-0000-0000-000000000002')$q$,'report ID must belong to route project');
SELECT pg_temp.assert_true((public.get_daily_report_entry_context('20000000-0000-0000-0000-000000000001',current_date,
 '80000000-0000-0000-0000-000000000003')->>'date')::date=current_date-1,'existing report ID determines the actual date');
SELECT pg_temp.assert_true((public.get_daily_report_entry_context('20000000-0000-0000-0000-000000000001',current_date-1)->>'legacy_resources')::boolean,'legacy report is identified without exposing rows');
SELECT pg_temp.denied($q$SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date-1,
 '50000000-0000-0000-0000-000000000001')$q$,'section cannot freeze existing legacy entries');
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,
 '50000000-0000-0000-0000-000000000001')->>'id' AS section \gset
SELECT public.save_daily_report_section_v2(:'section',0,'Evidence kept together','[]','[]','[]',false,
 '[{"x":10,"y":20},{"x":11,"y":21}]','["https://example.test/photo.jpg"]');
SELECT pg_temp.assert_true(public.get_daily_execution_workspace('20000000-0000-0000-0000-000000000001',current_date,
 '50000000-0000-0000-0000-000000000001')->'section'->'signature_points'='[{"x":10,"y":20},{"x":11,"y":21}]'::jsonb,'signature survives a reload');
SELECT pg_temp.assert_true(public.get_daily_execution_workspace('20000000-0000-0000-0000-000000000001',current_date,
 '50000000-0000-0000-0000-000000000001')->'section'->'evidence_photos'='["https://example.test/photo.jpg"]'::jsonb,'photos survive a reload');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section_v2(%L,1,'Invalid signature','[]','[]','[]',false,
 '[{"x":-1,"y":20}]','[]')$q$,:'section'),'invalid signature cannot partially save notes');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section_v2(%L,1,'Invalid URL','[]','[]','[]',false,
 '[]','["javascript:alert(1)"]')$q$,:'section'),'invalid evidence URL rejected');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section_v2(%L,0,'Stale media','[]','[]','[]',false,
 '[]','[]')$q$,:'section'),'stale revision cannot erase signature');
SELECT pg_temp.assert_true(public.get_daily_execution_workspace('20000000-0000-0000-0000-000000000001',current_date,
 '50000000-0000-0000-0000-000000000001')->'section'->>'notes'='Evidence kept together','failed saves preserve the entire section');
SELECT public.save_daily_report_section_v2(:'section',1,'Sent','[]','[]','[]',true,
 '[{"x":10,"y":20}]','["https://example.test/photo.jpg"]');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section_v2(%L,2,'Changed after sending','[]','[]','[]')$q$,:'section'),'submitted media is locked');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 AND min(total_net_hours)=7.5 FROM public.report_labor_logs
 WHERE id='81000000-0000-0000-0000-000000000009'),'legacy hours and identity unchanged');
SELECT public.review_daily_report_section(:'section',false,'Check signature');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_operation_reports('20000000-0000-0000-0000-000000000001'))=2,'new section uses existing report list');
SELECT pg_temp.assert_true((public.get_daily_report_entry_context('20000000-0000-0000-0000-000000000001')->>'has_sections')::boolean,'consolidated wizard knows its resources are section-owned');
SELECT public.ensure_daily_report('20000000-0000-0000-0000-000000000001',current_date)->>'id' AS consolidated \gset
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.daily_reports WHERE id=:'consolidated'),'concurrent wizard entry reuses the single report header');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.ensure_daily_report('20000000-0000-0000-0000-000000000001',current_date)$q$,'foreman cannot manage consolidated header');
SELECT public.save_daily_report_section_v2(:'section',3,'Corrected','[]','[]','[]',true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT public.review_daily_report_section(:'section',true);
UPDATE public.daily_reports SET status='submitted',submitted_by='10000000-0000-0000-0000-000000000001' WHERE id=:'consolidated';
SELECT pg_temp.assert_true((SELECT submitted_by=auth.uid() FROM public.daily_reports WHERE id=:'consolidated'),'submission actor cannot be forged');
SELECT pg_temp.denied(format($q$UPDATE public.daily_reports SET status='approved' WHERE id=%L$q$,:'consolidated'),'submitter cannot approve even when Foreman created the header');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
UPDATE public.daily_reports SET status='approved' WHERE id=:'consolidated';
SELECT pg_temp.assert_true((SELECT status='approved' FROM public.daily_reports WHERE id=:'consolidated'),'independent administrator approves the final consolidated report');
RESET ROLE;
SELECT 'Daily section integration tests passed' AS result;
ROLLBACK;
