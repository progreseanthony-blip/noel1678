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
CREATE FUNCTION pg_temp.plan_rows() RETURNS jsonb LANGUAGE sql AS $$
 SELECT jsonb_agg(jsonb_build_object('assignment_id',a.id,'worker_id',a.worker_id,'valid_from',a.start_date,'valid_until',a.end_date))
 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id WHERE l.project_id='20000000-0000-0000-0000-000000000001'
$$;
CREATE TEMP TABLE result(payload jsonb);
GRANT ALL ON result TO authenticated;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.assert_true(jsonb_array_length(public.get_labor_crew_planning('20000000-0000-0000-0000-000000000001')->'assignments')=2,'load existing dates without finance');
SELECT pg_temp.assert_true(NOT(public.get_labor_crew_planning('20000000-0000-0000-0000-000000000001')::text ~ 'hourly_rate|internal_cost|direct_cost'),'planning payload no financial fields');
INSERT INTO result SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',pg_temp.plan_rows(),NULL,'Unified crew','10000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.crew_members),'multi select saved');
SELECT pg_temp.assert_true((SELECT bool_and(m.valid_from=a.start_date AND m.valid_until=a.end_date) FROM public.crew_members m JOIN public.project_labor_assignments a ON a.id=m.labor_assignment_id),'individual dates inherited exactly');
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','p:92000000-0000-0000-0000-000000000001',pg_temp.plan_rows(),NULL,'Wrong service','10000000-0000-0000-0000-000000000003')$q$,'source from different service rejected');
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM public.project_crews),'atomic failure leaves no crew');
SELECT pg_temp.denied($q$DELETE FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'$q$,'linked plan cannot be deleted');
SELECT pg_temp.denied($q$UPDATE public.project_labor_assignments SET end_date=current_date WHERE worker_id='30000000-0000-0000-0000-000000000001'$q$,'linked plan cannot be shortened');
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',pg_temp.plan_rows(),NULL,'Duplicate','10000000-0000-0000-0000-000000000005')$q$,'overlapping membership rejected');
SELECT pg_temp.denied($q$SELECT public.get_labor_crew_planning('20000000-0000-0000-0000-000000000002')$q$,'supervisor other project denied');
SELECT pg_temp.denied($q$INSERT INTO public.project_members(project_id,profile_id,responsibility) VALUES('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000004','Foreman')$q$,'supervisor cannot authorize accounts');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.get_labor_crew_planning('20000000-0000-0000-0000-000000000001')$q$,'foreman planning read denied');
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',pg_temp.plan_rows())$q$,'foreman planning write denied');
SELECT public.get_daily_execution_planned_workspace('20000000-0000-0000-0000-000000000001',current_date,(SELECT (payload->>'crew_id')::uuid FROM result));
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SELECT public.end_labor_crew_period('member',(SELECT id FROM public.crew_members WHERE worker_id='30000000-0000-0000-0000-000000000001'),current_date);
SELECT public.update_labor_crew_dates((SELECT id FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),current_date-2,current_date+40);
-- Grow the same service period with an adjacent continuation; no source dates are rewritten.
SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',
 (SELECT jsonb_build_array(jsonb_build_object('assignment_id',id,'worker_id',worker_id,'valid_from',current_date+1,'valid_until',current_date+40)) FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),
 (SELECT (payload->>'crew_id')::uuid FROM result));
SELECT pg_temp.assert_true((SELECT count(*)=1 AND max(valid_until)=current_date+40 FROM public.crew_service_assignments),'service period extends without duplicate');
-- New staff and crew are one transaction; a later invalid row rolls everything back.
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','p:92000000-0000-0000-0000-000000000001',
 jsonb_build_array(jsonb_build_object('project_labor_id','40000000-0000-0000-0000-000000000004','worker_id','30000000-0000-0000-0000-000000000004','valid_from',current_date,'valid_until',current_date+10),
 jsonb_build_object('project_labor_id','40000000-0000-0000-0000-000000000004','worker_id','30000000-0000-0000-0000-000000000003','valid_from',current_date,'valid_until',current_date+10)),NULL,'Rollback crew','10000000-0000-0000-0000-000000000005')$q$,'batch rollback');
SELECT pg_temp.assert_true(NOT EXISTS(SELECT 1 FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000004'),'failed batch leaves no plan');
SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','p:92000000-0000-0000-0000-000000000001',
 jsonb_build_array(jsonb_build_object('project_labor_id','40000000-0000-0000-0000-000000000004','worker_id','30000000-0000-0000-0000-000000000004','valid_from',current_date,'valid_until',current_date+10)),NULL,'CO crew','10000000-0000-0000-0000-000000000005');
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_crews),'new staff and CO service crew saved');
-- Exact planning assignment wins over an unrelated legacy allocation of the same worker.
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000004','30000000-0000-0000-0000-000000000003',current_date,current_date+10);
SELECT pg_temp.assert_true((SELECT count(*)=1 FROM jsonb_array_elements(public.get_daily_execution_planned_workspace(
 '20000000-0000-0000-0000-000000000001',current_date,(SELECT (payload->>'crew_id')::uuid FROM result))->'planned_labor') l,
 jsonb_array_elements(l->'project_labor_assignments') a WHERE a->>'worker_id'='30000000-0000-0000-0000-000000000003'),'daily default uses exact planned source');
SELECT pg_temp.denied($q$UPDATE public.project_labor SET quote_service_id=NULL WHERE id='40000000-0000-0000-0000-000000000003'$q$,'linked service cannot be rewritten');
UPDATE public.projects SET calculation_metadata='{"baseline_frozen":true}' WHERE id='20000000-0000-0000-0000-000000000001';
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT public.open_daily_report_section('20000000-0000-0000-0000-000000000001',current_date+5,(SELECT (payload->>'crew_id')::uuid FROM result))->>'id' AS section_id \gset
SELECT public.save_daily_report_section(:'section_id',0,'History',
 '[{"worker_id":"30000000-0000-0000-0000-000000000003","project_labor_id":"40000000-0000-0000-0000-000000000003","check_in_time":"07:00","check_out_time":"15:00","break_minutes":30}]','[]','[]');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SELECT pg_temp.denied($q$SELECT public.end_labor_crew_period('member',(SELECT id FROM public.crew_members WHERE worker_id='30000000-0000-0000-0000-000000000003'),current_date+2)$q$,'recorded membership dates preserved');
SELECT pg_temp.denied($q$SELECT public.end_labor_crew_period('leader',(SELECT id FROM public.crew_leaders WHERE crew_id=(SELECT (payload->>'crew_id')::uuid FROM result) AND valid_from<=current_date+5 AND (valid_until IS NULL OR valid_until>=current_date+5)),current_date+2)$q$,'recorded leadership dates preserved');
UPDATE public.projects SET status='completed' WHERE id='20000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',pg_temp.plan_rows())$q$,'completed project read only');
ROLLBACK;
