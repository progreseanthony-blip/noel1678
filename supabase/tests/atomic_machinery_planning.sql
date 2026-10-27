\set ON_ERROR_STOP on
BEGIN;
GRANT USAGE ON SCHEMA public,auth TO authenticated;
GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION auth.uid() TO authenticated;
CREATE FUNCTION pg_temp.ok(value boolean,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN IF value IS DISTINCT FROM true THEN RAISE EXCEPTION 'FAIL: %',label; END IF; END $$;
CREATE FUNCTION pg_temp.denied(command text,label text) RETURNS void LANGUAGE plpgsql AS $$
BEGIN BEGIN EXECUTE command; EXCEPTION WHEN OTHERS THEN RAISE NOTICE 'PASS denied: %',label; RETURN; END;
 RAISE EXCEPTION 'FAIL allowed: %',label; END $$;
INSERT INTO auth.users(id,email,raw_user_meta_data) VALUES
 ('11000000-0000-0000-0000-000000000001','admin-machinery@test.local','{}'),
 ('11000000-0000-0000-0000-000000000002','supervisor-machinery@test.local','{}'),
 ('11000000-0000-0000-0000-000000000003','foreman-machinery@test.local','{}');
UPDATE public.profiles SET role=CASE right(id::text,1) WHEN '1' THEN 'Admin' WHEN '2' THEN 'Supervisor' ELSE 'Foreman' END,access_status='active'
 WHERE id::text LIKE '11000000-%';
SELECT set_config('request.jwt.claim.sub','11000000-0000-0000-0000-000000000001',true);
INSERT INTO public.projects(id,title,status) VALUES
 ('21000000-0000-0000-0000-000000000001','Planning','active'),
 ('21000000-0000-0000-0000-000000000002','Other','active');
INSERT INTO public.project_members(project_id,profile_id,responsibility,valid_from) VALUES
 ('21000000-0000-0000-0000-000000000001','11000000-0000-0000-0000-000000000002','Supervisor',current_date-1);
INSERT INTO public.project_machinery(id,project_id,machinery_name,expected_quantity) VALUES
 ('71000000-0000-0000-0000-000000000001','21000000-0000-0000-0000-000000000001','Three units',3),
 ('71000000-0000-0000-0000-000000000002','21000000-0000-0000-0000-000000000001','Two units',2),
 ('71000000-0000-0000-0000-000000000003','21000000-0000-0000-0000-000000000002','Other project',1);
INSERT INTO public.project_machinery_assignments(id,project_machinery_id,start_date,end_date,quantity,actual_start_date,status) VALUES
 ('81000000-0000-0000-0000-000000000001','71000000-0000-0000-0000-000000000001','2026-10-01','2026-10-05',2,'2026-10-02','in_progress');
CREATE FUNCTION pg_temp.request(n int,mode text,first_day text DEFAULT '2026-11-02',last_day text DEFAULT '2026-11-19') RETURNS jsonb LANGUAGE sql AS $$
 SELECT jsonb_build_object('id',m.id,'capacity',m.expected_quantity,'mode',mode,'start_date',first_day,'end_date',last_day,
 'previous',coalesce((SELECT jsonb_agg(jsonb_build_object('id',a.id,'start_date',a.start_date,'end_date',a.end_date,'quantity',a.quantity) ORDER BY a.id)
 FROM public.project_machinery_assignments a WHERE a.project_machinery_id=m.id),'[]'::jsonb))
 FROM public.project_machinery m WHERE right(m.id::text,1)=n::text
$$;
CREATE FUNCTION pg_temp.save(rows jsonb) RETURNS jsonb LANGUAGE sql AS $$
 SELECT public.save_machinery_planning('21000000-0000-0000-0000-000000000001',rows)
$$;
CREATE TEMP TABLE original(payload jsonb);
GRANT ALL ON original TO authenticated;
SET LOCAL ROLE authenticated;
SELECT pg_temp.ok((pg_temp.save(jsonb_build_array(pg_temp.request(1,'pending'),pg_temp.request(2,'pending')))->>'added_units')::int=3,'pending fills missing units across machines');
SELECT pg_temp.ok((SELECT sum(quantity)=3 FROM public.project_machinery_assignments WHERE project_machinery_id='71000000-0000-0000-0000-000000000001'),'three units retained');
SELECT pg_temp.ok((SELECT start_date='2026-10-01' FROM public.project_machinery_assignments WHERE id='81000000-0000-0000-0000-000000000001'),'pending preserves original dates');
SELECT pg_temp.ok((SELECT count(*)=0 FROM public.project_machinery_assignments WHERE project_machinery_id='71000000-0000-0000-0000-000000000003'),'unshown project remains unchanged');
SELECT pg_temp.ok((pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace')))->>'machines')::int=1,'replacement updates already scheduled machine');
SELECT pg_temp.ok((SELECT bool_and(start_date='2026-11-02' AND end_date='2026-11-19') AND sum(quantity)=3 FROM public.project_machinery_assignments WHERE project_machinery_id='71000000-0000-0000-0000-000000000001'),'all three units receive new dates');
SELECT pg_temp.ok((SELECT actual_start_date='2026-10-02' AND status='in_progress' AND quantity=2 FROM public.project_machinery_assignments WHERE id='81000000-0000-0000-0000-000000000001'),'IDs, real execution and quantities preserved');
SELECT pg_temp.ok((pg_temp.save(jsonb_build_array(pg_temp.request(1,'pending')))->>'machines')::int=0,'no false update count for fully planned machinery');
INSERT INTO original SELECT pg_temp.request(1,'replace');
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace','2026-12-01','2026-12-31'),pg_temp.request(3,'replace')))$q$,'batch cannot target another project; first change rolls back');
SELECT pg_temp.ok((SELECT pg_temp.request(1,'replace')=payload FROM original),'batch failure leaves first machine untouched');
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace')||' {"previous":[]}'::jsonb))$q$,'stale snapshot rejected');
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace','2026-11-20','2026-11-01')))$q$,'invalid period rejected');
-- Normal view: independent groups retain their identity and planned quantity.
SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'units')||jsonb_build_object('plans',
 (SELECT jsonb_agg(jsonb_build_object('assignment_id',id,'start_date','2026-11-03','end_date',CASE WHEN id='81000000-0000-0000-0000-000000000001' THEN '2026-11-10' ELSE '2026-11-25' END,'quantity',quantity))
 FROM public.project_machinery_assignments WHERE project_machinery_id='71000000-0000-0000-0000-000000000001'))));
SELECT pg_temp.ok((SELECT start_date='2026-11-03' AND end_date='2026-11-25' FROM public.project_machinery WHERE id='71000000-0000-0000-0000-000000000001'),'summary spans all unit groups');
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'units')||'{"plans":[{"start_date":"2026-11-03","end_date":"2026-11-05","quantity":4}]}'::jsonb))$q$,'cannot exceed unit capacity');
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'units')||'{"plans":[{"start_date":"2026-11-03","end_date":"2026-11-05","quantity":1}]}'::jsonb))$q$,'cannot delete an execution-bearing group');
SELECT set_config('request.jwt.claim.sub','11000000-0000-0000-0000-000000000003',true);
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace')))$q$,'Foreman cannot schedule machinery');
SELECT set_config('request.jwt.claim.sub','11000000-0000-0000-0000-000000000002',true);
SELECT pg_temp.ok((pg_temp.save(jsonb_build_array(pg_temp.request(2,'replace')))->>'machines')::int=1,'authorized supervisor can correct dates');
SELECT pg_temp.denied($q$SELECT public.save_machinery_planning('21000000-0000-0000-0000-000000000002',jsonb_build_array(pg_temp.request(3,'replace')))$q$,'supervisor cannot schedule another project');
SELECT set_config('request.jwt.claim.sub','11000000-0000-0000-0000-000000000001',true);
UPDATE public.projects SET status='completed' WHERE id='21000000-0000-0000-0000-000000000001';
SELECT pg_temp.denied($q$SELECT pg_temp.save(jsonb_build_array(pg_temp.request(1,'replace')))$q$,'completed project remains read-only');
ROLLBACK;
