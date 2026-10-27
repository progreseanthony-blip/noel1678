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
INSERT INTO result SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001',
 'q:90000000-0000-0000-0000-000000000001',pg_temp.plan_rows(),NULL,'Test crew','10000000-0000-0000-0000-000000000003');
SELECT public.change_labor_crew_foreman((SELECT id FROM public.crew_leaders LIMIT 1),'10000000-0000-0000-0000-000000000005','correct',NULL,'Error de selección');
SELECT pg_temp.assert_true((SELECT profile_id='10000000-0000-0000-0000-000000000005' FROM public.crew_leaders LIMIT 1),'correction keeps dates and substitutes identity');
SELECT pg_temp.denied($q$SELECT public.change_labor_crew_foreman((SELECT id FROM public.crew_leaders LIMIT 1),'10000000-0000-0000-0000-000000000004','correct',NULL,'Wrong account')$q$,'unauthorized replacement blocked');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
INSERT INTO public.daily_reports(id,project_id,supervisor_id,report_date) VALUES
 ('80000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001',current_date+1);
RESET ROLE;
INSERT INTO public.daily_report_sections(daily_report_id,crew_id) VALUES
 ('80000000-0000-0000-0000-000000000001',(SELECT id FROM public.project_crews LIMIT 1));
SET LOCAL ROLE authenticated;
SELECT pg_temp.denied($q$SELECT public.change_labor_crew_foreman((SELECT id FROM public.crew_leaders LIMIT 1),'10000000-0000-0000-0000-000000000003','correct',NULL,'Has execution')$q$,'correction with activity blocked');
SELECT public.change_labor_crew_foreman((SELECT id FROM public.crew_leaders LIMIT 1),'10000000-0000-0000-0000-000000000003','replace',current_date+2,'Relevo programado');
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.crew_leaders),'replacement creates dated history');
SELECT pg_temp.assert_true((SELECT valid_until=current_date+1 FROM public.crew_leaders WHERE profile_id='10000000-0000-0000-0000-000000000005'),'old Foreman ends the previous day');
SELECT public.change_labor_worker_plan((SELECT id FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),'crew_end',current_date+1,'Cambio de equipo');
SELECT pg_temp.assert_true((SELECT end_date=current_date+30 FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),'crew removal retains source planning');
SELECT public.change_labor_worker_plan((SELECT id FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),'finish',current_date+1,'Fin del trabajo');
SELECT pg_temp.assert_true((SELECT end_date=current_date+1 FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000001'),'finishing releases later dates');
SELECT pg_temp.denied($q$SELECT public.change_labor_worker_plan((SELECT id FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000003'),'cancel',NULL,'Tiene actividad')$q$,'cannot cancel used membership');
SELECT pg_temp.assert_true((SELECT count(*)=4 FROM public.labor_planning_actions),'only successful changes audited');
INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date) VALUES
 ('40000000-0000-0000-0000-000000000004','30000000-0000-0000-0000-000000000004',current_date+40,current_date+50);
SELECT public.change_labor_worker_plan((SELECT id FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000004'),'cancel',NULL,'Asignación errónea');
SELECT pg_temp.assert_true(NOT EXISTS(SELECT 1 FROM public.project_labor_assignments WHERE worker_id='30000000-0000-0000-0000-000000000004'),'unused planning cancelled');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.change_labor_worker_plan((SELECT id FROM public.project_labor_assignments LIMIT 1),'cancel',NULL,'Foreman denied')$q$,'Foreman cannot change planning');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
INSERT INTO public.quotes(id,title,team_sharing_enabled) VALUES('91000000-0000-0000-0000-000000000003','New mandatory team',false);
SELECT pg_temp.denied($q$UPDATE public.quotes SET status='sent' WHERE id='91000000-0000-0000-0000-000000000003'$q$,'new estimate cannot be sent without budgeted team');
INSERT INTO public.quote_services(id,quote_id,name) VALUES
 ('90000000-0000-0000-0000-000000000003','91000000-0000-0000-0000-000000000003','General management');
INSERT INTO public.quote_service_labors(quote_service_id,role_name,operational_role,coverage_scope,employees_quantity,months_to_work,hourly_rate) VALUES
 ('90000000-0000-0000-0000-000000000003','Superintendent','Supervisor','project',2,1,50),
 ('90000000-0000-0000-0000-000000000003','Crew leader','Foreman','service',1,1,30);
UPDATE public.quotes SET status='sent' WHERE id='91000000-0000-0000-0000-000000000003';
SELECT pg_temp.assert_true((SELECT status='sent' FROM public.quotes WHERE id='91000000-0000-0000-0000-000000000003'),'valid team permits issuing');
INSERT INTO public.projects(id,title,quote_id) VALUES('20000000-0000-0000-0000-000000000003','Budget transfer','91000000-0000-0000-0000-000000000003');
INSERT INTO public.project_labor(project_id,quote_service_labor_id,role_name)
 SELECT '20000000-0000-0000-0000-000000000003',id,role_name FROM public.quote_service_labors
 WHERE quote_service_id='90000000-0000-0000-0000-000000000003' AND operational_role='Supervisor';
SELECT pg_temp.assert_true(EXISTS(SELECT 1 FROM public.project_labor WHERE project_id='20000000-0000-0000-0000-000000000003'
 AND operational_role='Supervisor' AND coverage_scope='project'),'function and scope transfer from estimate to planning');
RESET ROLE;
INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES('10000000-0000-0000-0000-000000000006','linked@example.test','{}');
SET LOCAL ROLE authenticated;
UPDATE public.profiles SET role='Foreman',access_status='active',worker_id='30000000-0000-0000-0000-000000000004'
 WHERE id='10000000-0000-0000-0000-000000000006';
INSERT INTO public.project_labor(id,project_id,role_name,operational_role,quote_service_id) VALUES
 ('40000000-0000-0000-0000-000000000006','20000000-0000-0000-0000-000000000001','Crew leader','Foreman','90000000-0000-0000-0000-000000000001');
SELECT pg_temp.denied($q$SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',jsonb_build_array(jsonb_build_object('project_labor_id','40000000-0000-0000-0000-000000000006','worker_id','30000000-0000-0000-0000-000000000003','valid_from',current_date+40,'valid_until',current_date+50)))$q$,'budgeted Foreman requires linked active account');
SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000001','q:90000000-0000-0000-0000-000000000001',jsonb_build_array(jsonb_build_object('project_labor_id','40000000-0000-0000-0000-000000000006','worker_id','30000000-0000-0000-0000-000000000004','valid_from',current_date+40,'valid_until',current_date+50)));
SELECT pg_temp.assert_true(EXISTS(SELECT 1 FROM public.project_members WHERE profile_id='10000000-0000-0000-0000-000000000006' AND valid_from=current_date+40 AND valid_until=current_date+50),'Admin assigning budgeted Foreman also authorizes account dates');
SELECT pg_temp.assert_true(public.get_labor_crew_planning_responsibilities('20000000-0000-0000-0000-000000000001')->'can_authorize'='true'::jsonb,'Admin gets account-link action');
ROLLBACK;
