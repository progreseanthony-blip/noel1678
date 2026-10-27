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
INSERT INTO public.quotes(id,title) VALUES('91000000-0000-0000-0000-000000000003','Shared leadership');
INSERT INTO public.quote_services(id,quote_id,name) VALUES
 ('90000000-0000-0000-0000-000000000003','91000000-0000-0000-0000-000000000003','Service A'),
 ('90000000-0000-0000-0000-000000000004','91000000-0000-0000-0000-000000000003','Service B');
SELECT pg_temp.denied($q$SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003')$q$,'each service needs supervision and leadership');
INSERT INTO public.quote_service_labors(id,quote_service_id,role_name,operational_role,coverage_scope,employees_quantity,months_to_work,hourly_rate,
 team_resource_id,team_resource_label,team_dedication,team_service_months,team_start,team_end) VALUES
 ('94000000-0000-0000-0000-000000000001','90000000-0000-0000-0000-000000000003','Superintendent','Supervisor','service',1,0.5,50,
  '93000000-0000-0000-0000-000000000001','Supervisor 1',50,1,current_date+40,current_date+50);
SELECT pg_temp.denied($q$UPDATE public.quotes SET status='sent' WHERE id='91000000-0000-0000-0000-000000000003'$q$,'partial coverage cannot be sent');
INSERT INTO public.quote_service_labors(id,quote_service_id,role_name,operational_role,coverage_scope,employees_quantity,months_to_work,hourly_rate,
 team_resource_id,team_resource_label,team_dedication,team_service_months,team_start,team_end) VALUES
 ('94000000-0000-0000-0000-000000000002','90000000-0000-0000-0000-000000000004','Superintendent','Supervisor','service',1,0.5,50,
  '93000000-0000-0000-0000-000000000001','Supervisor 1',50,1,current_date+40,current_date+50),
 ('94000000-0000-0000-0000-000000000003','90000000-0000-0000-0000-000000000003','Crew leader','Foreman','service',1,0.5,50,
  '93000000-0000-0000-0000-000000000002','Foreman 1',50,1,current_date+40,current_date+50),
 ('94000000-0000-0000-0000-000000000004','90000000-0000-0000-0000-000000000004','Crew leader','Foreman','service',1,0.5,50,
  '93000000-0000-0000-0000-000000000002','Foreman 1',50,1,current_date+40,current_date+50);
SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT sum(months_to_work*220*employees_quantity*hourly_rate)=22000 FROM public.quote_service_labors WHERE team_resource_id IS NOT NULL),'shared dedication distributes total costs without duplicating full-time resources');
UPDATE public.quote_service_labors SET team_dedication=100,months_to_work=1 WHERE id='94000000-0000-0000-0000-000000000002';
SELECT pg_temp.denied($q$SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003')$q$,'overlapping commitment over 100 percent rejected');
UPDATE public.quote_service_labors SET team_start=current_date+51,team_end=current_date+61 WHERE id='94000000-0000-0000-0000-000000000002';
SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003');
UPDATE public.quote_service_labors SET team_start=current_date+40,team_end=current_date+50,team_dedication=50,months_to_work=0.5 WHERE id='94000000-0000-0000-0000-000000000002';
UPDATE public.quote_service_labors SET hourly_rate=500 WHERE id='94000000-0000-0000-0000-000000000002';
SELECT pg_temp.denied($q$SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003')$q$,'inconsistent shared rates rejected');
UPDATE public.quote_service_labors SET hourly_rate=50 WHERE id='94000000-0000-0000-0000-000000000002';
UPDATE public.quotes SET status='sent' WHERE id='91000000-0000-0000-0000-000000000003';
INSERT INTO public.projects(id,title,quote_id) VALUES('20000000-0000-0000-0000-000000000003','Shared project','91000000-0000-0000-0000-000000000003');
INSERT INTO public.project_labor(project_id,quote_service_labor_id,quote_service_id,role_name)
 SELECT DISTINCT ON(team_resource_id) '20000000-0000-0000-0000-000000000003',id,quote_service_id,role_name
 FROM public.quote_service_labors WHERE team_resource_id IS NOT NULL ORDER BY team_resource_id,quote_service_id;
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_labor WHERE project_id='20000000-0000-0000-0000-000000000003'),'two shared people produce two physical slots, not four');
SELECT pg_temp.denied($q$DELETE FROM public.quote_service_labors WHERE id='94000000-0000-0000-0000-000000000001'$q$,'shared source budget cannot be deleted after planning');
SELECT pg_temp.denied($q$INSERT INTO public.project_labor(project_id,quote_service_labor_id,role_name) VALUES('20000000-0000-0000-0000-000000000003','94000000-0000-0000-0000-000000000002','Superintendent')$q$,'duplicate physical resource is rejected');
UPDATE public.profiles SET worker_id='30000000-0000-0000-0000-000000000001' WHERE id='10000000-0000-0000-0000-000000000002';
UPDATE public.profiles SET worker_id='30000000-0000-0000-0000-000000000003' WHERE id='10000000-0000-0000-0000-000000000003';
SELECT public.save_labor_crew_plan('20000000-0000-0000-0000-000000000003','q:90000000-0000-0000-0000-000000000003',
 (SELECT jsonb_agg(jsonb_build_object('project_labor_id',id,'worker_id',CASE operational_role WHEN 'Supervisor' THEN '30000000-0000-0000-0000-000000000001' ELSE '30000000-0000-0000-0000-000000000003' END,'valid_from',current_date+40,'valid_until',current_date+50))
  FROM public.project_labor WHERE project_id='20000000-0000-0000-0000-000000000003'));
SELECT pg_temp.assert_true((SELECT count(*)=2 FROM public.project_labor_assignments a JOIN public.project_labor l ON l.id=a.project_labor_id WHERE l.project_id='20000000-0000-0000-0000-000000000003'),'shared workers are assigned once');
INSERT INTO result SELECT public.get_labor_crew_planning_responsibilities('20000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT jsonb_array_length(payload->'shared_team_resources')=2 FROM result),'planning exposes shared resources');
SELECT pg_temp.assert_true((SELECT bool_and(jsonb_array_length(r->'services')=2) FROM result,jsonb_array_elements(payload->'shared_team_resources') r),'both covered services reference the same people');
SELECT pg_temp.assert_true((SELECT NOT(payload::text ~ 'hourly_rate|direct_cost|internal_cost|team_service_months') FROM result),'shared planning does not disclose financial fields');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT public.get_labor_crew_planning_responsibilities('20000000-0000-0000-0000-000000000003')$q$,'Foreman cannot access resource planning');
ROLLBACK;
