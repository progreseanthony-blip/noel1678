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
-- Automatic mode is explicitly adopted; no existing budget is silently changed.
UPDATE public.quotes SET team_allocation_automatic=true,total_amount=44000 WHERE id='91000000-0000-0000-0000-000000000003';
UPDATE public.quote_services SET direct_cost=22000 WHERE quote_id='91000000-0000-0000-0000-000000000003';
UPDATE public.quote_service_labors SET months_to_work=1,team_dedication=100 WHERE team_resource_id IS NOT NULL;
SELECT pg_temp.denied($q$SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003')$q$,'full coverage must first allocate and confirm, not duplicate');
CREATE TEMP TABLE preview(payload jsonb);
GRANT ALL ON preview TO authenticated;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT (payload->>'total')::numeric=22000 FROM preview),'preview halves identical concurrent budgets');
SELECT pg_temp.assert_true((SELECT count(*)=0 FROM public.quote_team_allocation_approvals),'preview does not record consent');
SELECT pg_temp.assert_true((SELECT sum(months_to_work)=4 FROM public.quote_service_labors WHERE team_resource_id IS NOT NULL),'preview does not mutate time');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.denied($q$SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,'forged')$q$,'supervisor cannot authorize shared coverage');
SELECT set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
SELECT pg_temp.denied($q$INSERT INTO public.quote_team_allocation_approvals(quote_id,fingerprint,approved_by,snapshot) VALUES('91000000-0000-0000-0000-000000000003','forged','10000000-0000-0000-0000-000000000001','{}')$q$,'even admin cannot forge approval through table writes');
UPDATE public.quote_service_labors SET team_resource_label='Supervisor revised' WHERE operational_role='Supervisor' AND team_resource_id IS NOT NULL;
SELECT pg_temp.denied($q$SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview))$q$,'stale preview rejected');
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT total_amount=22000 FROM public.quotes WHERE id='91000000-0000-0000-0000-000000000003'),'quote total updated atomically');
SELECT pg_temp.assert_true((SELECT sum(direct_cost)=22000 FROM public.quote_services WHERE quote_id='91000000-0000-0000-0000-000000000003'),'service prices match quote total');
SELECT pg_temp.assert_true((SELECT abs(sum(months_to_work*220*employees_quantity*hourly_rate)-22000)<0.000001 FROM public.quote_service_labors WHERE team_resource_id IS NOT NULL),'one resource time per responsibility');
-- Partial overlap: 16 distinct days, with 6 shared days, and 5 exclusive each.
UPDATE public.quote_service_labors SET team_start=current_date+45,team_end=current_date+55 WHERE id='94000000-0000-0000-0000-000000000002';
SELECT pg_temp.denied($q$SELECT public.validate_quote_team('91000000-0000-0000-0000-000000000003')$q$,'date change invalidates confirmed allocation');
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
SELECT pg_temp.assert_true((SELECT abs(sum(months_to_work)-16.0/11)<0.000001 FROM public.quote_service_labors WHERE operational_role='Supervisor' AND team_resource_id IS NOT NULL),'partial overlap retains exclusive time');
-- Cost service can bear the whole union; the other service retains coverage at zero cost.
UPDATE public.quote_service_labors SET team_cost_primary=true WHERE id='94000000-0000-0000-0000-000000000001';
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
SELECT pg_temp.assert_true((SELECT abs(months_to_work-16.0/11)<0.000001 FROM public.quote_service_labors WHERE id='94000000-0000-0000-0000-000000000001'),'primary cost service carries union time');
SELECT pg_temp.assert_true((SELECT months_to_work=0 FROM public.quote_service_labors WHERE id='94000000-0000-0000-0000-000000000002'),'other service still covered without duplicated time');
UPDATE public.quote_service_labors SET team_cost_primary=true WHERE id='94000000-0000-0000-0000-000000000002';
SELECT pg_temp.denied($q$SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003')$q$,'two primary cost services rejected');
UPDATE public.quote_service_labors SET team_cost_primary=false WHERE team_resource_id IS NOT NULL;
-- Consecutive services retain their complete budget.
UPDATE public.quote_service_labors SET team_start=current_date+51,team_end=current_date+61 WHERE id='94000000-0000-0000-0000-000000000002';
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
SELECT pg_temp.assert_true((SELECT abs(sum(months_to_work)-2)<0.000001 FROM public.quote_service_labors WHERE operational_role='Supervisor' AND team_resource_id IS NOT NULL),'consecutive services remain full-time');
-- Restore common coverage for the existing physical-resource and planning tests.
UPDATE public.quote_service_labors SET team_start=current_date+40,team_end=current_date+50 WHERE id='94000000-0000-0000-0000-000000000002';
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
-- Per diem, overhead and profit are repriced together, including each service total.
UPDATE public.quote_service_labors SET per_diem=10,months_to_work=1 WHERE team_resource_id IS NOT NULL;
UPDATE public.quote_services SET overhead_percentage=10,profit_percentage=20,direct_cost=34848 WHERE quote_id='91000000-0000-0000-0000-000000000003';
UPDATE public.quotes SET total_amount=69696 WHERE id='91000000-0000-0000-0000-000000000003';
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT pg_temp.assert_true((SELECT (payload->>'total')::numeric=34848 FROM preview),'preview includes per diem, overhead and profit');
UPDATE public.quote_services SET name='Service A revised' WHERE id='90000000-0000-0000-0000-000000000003';
SELECT pg_temp.denied($q$SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview))$q$,'service edits invalidate the price preview');
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
SELECT pg_temp.assert_true((SELECT total_amount=34848 FROM public.quotes WHERE id='91000000-0000-0000-0000-000000000003'),'approved price includes all labor components');
SELECT pg_temp.assert_true((SELECT sum(direct_cost)=34848 FROM public.quote_services WHERE quote_id='91000000-0000-0000-0000-000000000003'),'service amounts equal the approved quote');
-- Leave the fixture at its original rates for planning-only assertions.
UPDATE public.quote_service_labors SET per_diem=0,months_to_work=1 WHERE team_resource_id IS NOT NULL;
UPDATE public.quote_services SET overhead_percentage=0,profit_percentage=0,direct_cost=22000 WHERE quote_id='91000000-0000-0000-0000-000000000003';
UPDATE public.quotes SET total_amount=44000 WHERE id='91000000-0000-0000-0000-000000000003';
TRUNCATE preview;
INSERT INTO preview SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003');
SELECT public.prepare_quote_team_allocation('91000000-0000-0000-0000-000000000003',true,(SELECT payload->>'fingerprint' FROM preview));
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
