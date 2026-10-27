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
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
SELECT pg_temp.denied($q$SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')$q$,'pending cannot open a section');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')$q$,'foreman cannot open another crew');
SELECT pg_temp.denied($q$SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,NULL)$q$,'foreman cannot use unassigned section');
SELECT pg_temp.denied($q$SELECT public.get_daily_execution_workspace('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')$q$,'cannot read another crew canonical workspace');
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')->>'id' AS a \gset
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000001')->>'id' AS a_again \gset
SELECT pg_temp.assert_true(:'a'=:'a_again','opening twice keeps a single crew section');
SELECT public.save_daily_report_section(:'a',0,'Morning',
 '[{"id":"81000000-0000-0000-0000-000000000001","worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"07:00","check_out_time":"10:00","break_minutes":0,"total_net_hours":999}]',
 '[]','[]');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,0,'Stale','[]','[]','[]')$q$,:'a'),'stale revision fails');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Bad',
 '[{"worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"07:00","check_out_time":"10:00","break_minutes":999}]','[]','[]')$q$,:'a'),'invalid break rolls back the replacement');

-- Read as an assigned supervisor, not through privileged test-only table access.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 AND min(total_net_hours)=3 FROM public.report_labor_logs),'failed save preserves prior rows; hours computed server-side');
SELECT pg_temp.assert_true((SELECT revision=1 AND notes='Morning' FROM public.daily_report_sections WHERE id=:'a'),'failed save preserves revision and notes');
SELECT pg_temp.denied($q$DELETE FROM public.report_labor_logs$q$,'legacy wholesale deletion cannot erase canonical sections');
SELECT pg_temp.denied($q$UPDATE public.report_labor_logs SET section_id=NULL$q$,'cannot detach canonical row from section');
SELECT pg_temp.denied($q$INSERT INTO public.daily_report_sections(daily_report_id)
 SELECT daily_report_id FROM public.daily_report_sections LIMIT 1$q$,'direct section writes denied');
SELECT daily_report_id AS report FROM public.daily_report_sections WHERE id=:'a' \gset
SELECT public.request_daily_worker_transfer(:'report','30000000-0000-0000-0000-000000000001',
 '50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001','10:00','12:00','Temporary assistance') AS loan \gset
SELECT public.review_daily_worker_transfer(:'loan',true);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.crew_members WHERE worker_id='30000000-0000-0000-0000-000000000001'),'temporary loan does not change base membership');
SELECT public.request_daily_worker_transfer(:'report','30000000-0000-0000-0000-000000000001',
 '50000000-0000-0000-0000-000000000002','40000000-0000-0000-0000-000000000001','11:00','13:00','Conflicting loan') AS overlap_loan \gset
SELECT pg_temp.denied(format($q$SELECT public.review_daily_worker_transfer(%L,true)$q$,:'overlap_loan'),'overlapping loans rejected');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000005',true);
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')->>'id' AS b \gset
SELECT pg_temp.denied(format($q$SELECT public.review_daily_worker_transfer(%L,true)$q$,:'overlap_loan'),'foreman cannot authorize a loan');
SELECT public.save_daily_report_section(:'b',0,'Loan execution',
 jsonb_build_array(jsonb_build_object('id','81000000-0000-0000-0000-000000000002',
 'worker_id','30000000-0000-0000-0000-000000000001','project_labor_id','40000000-0000-0000-0000-000000000001',
 'check_in_time','10:00','check_out_time','12:00','break_minutes',15,'transfer_id',:'loan')),
 '[{"id":"82000000-0000-0000-0000-000000000001","project_machinery_id":"70000000-0000-0000-0000-000000000001","machinery_id":"60000000-0000-0000-0000-000000000001","machinery_inspection_id":"71000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000001","operation_start":"10:00","operation_end":"11:00","start_meter":100,"end_meter":101,"rate_override":999}]',
 '[{"material_id":"60000000-0000-0000-0000-000000000002","project_material_id":"70000000-0000-0000-0000-000000000002","quantity_used":2}]');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Hijack','[]','[]','[]')$q$,:'a'),'other foreman cannot save origin section');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_execution_workspace(
 '20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')->'labor')=1,'destination foreman reads only own execution');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_execution_workspace(
 '20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')->'workers')=2,'destination roster includes its member and authorized temporary worker');
SELECT pg_temp.assert_true(NOT(public.get_daily_execution_workspace(
 '20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')::text ~
 'hourly_rate|internal_cost|total_pay|unplanned_cost|rate_override|replacement_cost'),'entire operational response excludes monetary fields');
SELECT pg_temp.assert_true(jsonb_array_length(public.get_daily_execution_workspace(
 '20000000-0000-0000-0000-000000000001',current_date,'50000000-0000-0000-0000-000000000002')->'sections')=1,'foreman workspace excludes origin section metadata');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
-- Return to the original crew, same service. Two distinct stable segment IDs.
SELECT public.save_daily_report_section(:'a',1,'A to B to A',
 '[{"id":"81000000-0000-0000-0000-000000000001","worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"07:00","check_out_time":"10:00","break_minutes":0},
 {"id":"81000000-0000-0000-0000-000000000003","worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"12:00","check_out_time":"16:00","break_minutes":15}]',
 '[{"project_machinery_id":"70000000-0000-0000-0000-000000000001","machinery_id":"60000000-0000-0000-0000-000000000001","machinery_inspection_id":"71000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000001","operation_start":"12:00","operation_end":"13:00","start_meter":101,"end_meter":102}]','[]');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,2,'Overlap',
 '[{"worker_id":"30000000-0000-0000-0000-000000000001","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"07:00","check_out_time":"16:00","break_minutes":30}]','[]','[]')$q$,:'a'),'base attendance cannot consume an authorized loan');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true((SELECT count(*)=3 AND sum(total_net_hours)=8.5 FROM public.report_labor_logs),'three segments preserve one day and a single total break');
SELECT pg_temp.assert_true((SELECT count(*)=2 AND sum(total_hours)=2 FROM public.report_machinery_logs),'physical machine can be used sequentially by different crews');
SELECT pg_temp.assert_true((SELECT count(*)=1 AND sum(quantity_used)=2 FROM public.report_material_usage),'saving origin crew preserves destination material');
SELECT pg_temp.assert_true((SELECT rate_override IS NULL FROM public.report_machinery_logs WHERE id='82000000-0000-0000-0000-000000000001'),'operational save rejects injected monetary fields');
SELECT pg_temp.assert_true((SELECT base_crew_id='50000000-0000-0000-0000-000000000001'
 AND execution_crew_id='50000000-0000-0000-0000-000000000002' FROM public.report_labor_logs
 WHERE id='81000000-0000-0000-0000-000000000002'),'base and execution crew stored separately');
SELECT jsonb_agg(to_jsonb(l))::text AS a_labor FROM public.report_labor_logs l WHERE section_id=:'a' \gset
SELECT jsonb_agg(to_jsonb(m))::text AS a_machine FROM public.report_machinery_logs m WHERE section_id=:'a' \gset
SELECT jsonb_agg(to_jsonb(l))::text AS b_labor FROM public.report_labor_logs l WHERE section_id=:'b' \gset
SELECT jsonb_agg(to_jsonb(m))::text AS b_machine FROM public.report_machinery_logs m WHERE section_id=:'b' \gset
SELECT jsonb_agg(to_jsonb(m))::text AS b_material FROM public.report_material_usage m WHERE section_id=:'b' \gset
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Overlapping machines',%L::jsonb,%L::jsonb,'[]')$q$,
 :'b',:'b_labor',(:'b_machine'::jsonb || jsonb_build_array(jsonb_build_object(
 'machinery_id','60000000-0000-0000-0000-000000000001','project_machinery_id','70000000-0000-0000-0000-000000000001',
 'machinery_inspection_id','71000000-0000-0000-0000-000000000002','operator_id','30000000-0000-0000-0000-000000000001',
 'operation_start','10:30','operation_end','11:30','start_meter',200,'end_meter',201)))::text),'same operator cannot run different machines simultaneously');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Occupied physical unit',%L::jsonb,%L::jsonb,'[]')$q$,
 :'b',(:'b_labor'::jsonb || '[{"worker_id":"30000000-0000-0000-0000-000000000002","project_labor_id":"40000000-0000-0000-0000-000000000001","check_in_time":"10:00","check_out_time":"12:00","break_minutes":0}]'::jsonb)::text,
 (:'b_machine'::jsonb || '[{"machinery_id":"60000000-0000-0000-0000-000000000001","project_machinery_id":"70000000-0000-0000-0000-000000000001","machinery_inspection_id":"71000000-0000-0000-0000-000000000001","operator_id":"30000000-0000-0000-0000-000000000002","operation_start":"10:30","operation_end":"11:30","start_meter":200,"end_meter":201}]'::jsonb)::text),'physical unit cannot be used simultaneously by different operators');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Outside attendance',%L::jsonb,%L::jsonb,'[]')$q$,
 :'b',:'b_labor',jsonb_set(:'b_machine'::jsonb,'{0,operation_end}','"13:00"')::text),'machine interval must be covered by crew attendance');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'No physical unit',%L::jsonb,%L::jsonb,'[]')$q$,
 :'b',:'b_labor',(:'b_machine'::jsonb #- '{0,machinery_inspection_id}')::text),'catalog identity alone cannot identify a physical machine');
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,1,'Tampered identity',%L::jsonb,%L::jsonb,'[]')$q$,
 :'b',jsonb_set(:'b_labor'::jsonb,'{0,id}','"81000000-0000-0000-0000-000000000001"')::text,:'b_machine'),'cannot steal a row ID from another section');
SELECT pg_temp.denied(format($q$INSERT INTO public.report_labor_logs(daily_report_id,worker_id,check_in_time)
 VALUES(%L,'30000000-0000-0000-0000-000000000001','11:00')$q$,:'report'),'legacy insert cannot bypass section/loan controls');
SELECT pg_temp.denied(format($q$UPDATE public.daily_reports SET status='submitted' WHERE id=%L$q$,:'report'),'unreviewed sections block final report submission');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000005',true);
SELECT public.save_daily_report_section(:'b',1,'Submitted B',:'b_labor'::jsonb,:'b_machine'::jsonb,:'b_material'::jsonb,true);
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,2,'Changed','[]','[]','[]')$q$,:'b'),'submitted section is immutable');
SELECT pg_temp.denied(format($q$SELECT public.review_daily_report_section(%L,true)$q$,:'b'),'foreman cannot approve sections');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.denied(format($q$SELECT public.review_daily_report_section(%L,false,'')$q$,:'b'),'return needs a reason');
SELECT public.review_daily_report_section(:'b',false,'Check readings');
SELECT pg_temp.assert_true((SELECT status='returned' AND revision=3 FROM public.daily_report_sections WHERE id=:'b'),'return reopens only the selected section');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000005',true);
SELECT public.save_daily_report_section(:'b',3,'Checked',:'b_labor'::jsonb,:'b_machine'::jsonb,:'b_material'::jsonb,true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT public.save_daily_report_section(:'a',2,'Submitted A',:'a_labor'::jsonb,:'a_machine'::jsonb,'[]',true);
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT public.review_daily_report_section(:'a',true);
SELECT public.review_daily_report_section(:'b',true);
SELECT pg_temp.assert_true((SELECT count(*)=3 AND sum(total_net_hours)=8.5 FROM public.report_labor_logs),'review does not merge or duplicate execution entries');
SELECT pg_temp.denied(format($q$SELECT public.cancel_daily_worker_transfer(%L,'Wrong loan')$q$,:'loan'),'recorded loan cannot be cancelled');
SELECT public.cancel_daily_worker_transfer(:'overlap_loan','No longer needed');
SELECT pg_temp.assert_true((SELECT status='cancelled' AND decision_notes='No longer needed' FROM public.daily_worker_transfers WHERE id=:'overlap_loan'),'unused loan cancelled with history');
UPDATE public.daily_reports SET status='submitted' WHERE id=:'report';
SELECT pg_temp.denied(format($q$SELECT public.save_daily_report_section(%L,4,'Parent locked','[]','[]','[]')$q$,:'a'),'submitted parent locks every crew');

SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date+1,'50000000-0000-0000-0000-000000000001')->>'id' AS review_section \gset
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT public.save_daily_report_section(:'review_section',0,'Supervisor edited this section','[]','[]','[]',true);
SELECT pg_temp.denied(format($q$SELECT public.review_daily_report_section(%L,true)$q$,:'review_section'),'last editor cannot approve another person original section');

-- Lock tests: parent lock applies to legacy inserts as well as section saves.
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
UPDATE public.daily_reports SET status='submitted' WHERE id='80000000-0000-0000-0000-000000000002';
SELECT pg_temp.denied($q$INSERT INTO public.report_labor_logs(daily_report_id,worker_id,check_in_time)
 VALUES('80000000-0000-0000-0000-000000000002','30000000-0000-0000-0000-000000000001','07:00')$q$,'cannot insert into submitted legacy report');
UPDATE public.projects SET status='completed' WHERE id='20000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date+2,'50000000-0000-0000-0000-000000000001')$q$,'closed project cannot open sections');
RESET ROLE;
SELECT 'Canonical daily execution integration tests passed' AS result;
ROLLBACK;
