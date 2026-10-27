BEGIN;
-- Existing documents keep their interpretation until explicitly adopting sharing.
ALTER TABLE public.quotes ADD COLUMN team_sharing_enabled boolean NOT NULL DEFAULT false;
ALTER TABLE public.quotes ALTER COLUMN team_sharing_enabled SET DEFAULT true;
ALTER TABLE public.quote_service_labors
 ADD COLUMN team_resource_id uuid,
 ADD COLUMN team_resource_label text,
 ADD COLUMN team_dedication numeric NOT NULL DEFAULT 100 CHECK(team_dedication>=0 AND team_dedication<=100),
 ADD COLUMN team_service_months numeric CHECK(team_service_months>=0 AND team_service_months<1200),
 ADD COLUMN team_start date,
 ADD COLUMN team_end date,
 ADD CONSTRAINT shared_team_period CHECK(team_start IS NULL OR team_end IS NULL OR
  (isfinite(team_start) AND isfinite(team_end) AND team_end>=team_start AND team_end-team_start<=36600)),
 ADD CONSTRAINT shared_team_function CHECK(team_resource_id IS NULL OR operational_role IN ('Supervisor','Foreman'));
CREATE UNIQUE INDEX quote_team_resource_service ON public.quote_service_labors(quote_service_id,team_resource_id)
 WHERE team_resource_id IS NOT NULL;
ALTER TABLE public.project_labor ADD COLUMN team_resource_id uuid, ADD COLUMN team_resource_label text;

CREATE FUNCTION app_private.guard_shared_quote_line() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE q uuid; BEGIN
 IF TG_OP IN ('UPDATE','DELETE') AND OLD.team_resource_id IS NOT NULL AND
  EXISTS(SELECT 1 FROM public.project_labor WHERE team_resource_id=OLD.team_resource_id) THEN
  RAISE EXCEPTION 'El recurso ya tiene planificación. Conserva la cotización de origen y gestiona los cambios del proyecto por separado';
 END IF;
 IF TG_OP='DELETE' THEN RETURN OLD; END IF;
 IF NEW.team_resource_id IS NULL THEN RETURN NEW; END IF;
 PERFORM pg_advisory_xact_lock(1678,3);
 SELECT quote_id INTO STRICT q FROM public.quote_services WHERE id=NEW.quote_service_id;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE l.team_resource_id=NEW.team_resource_id AND s.quote_id<>q)
  THEN RAISE EXCEPTION 'El recurso compartido pertenece a otra cotización'; END IF;
 RETURN NEW;
END $$;
CREATE TRIGGER guard_shared_quote_line BEFORE INSERT OR UPDATE OR DELETE ON public.quote_service_labors
 FOR EACH ROW EXECUTE FUNCTION app_private.guard_shared_quote_line();

ALTER FUNCTION public.validate_quote_team(uuid) RENAME TO validate_quote_team_legacy;
REVOKE ALL ON FUNCTION public.validate_quote_team_legacy(uuid) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION public.validate_quote_team(p_quote uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE service record; function_name text; BEGIN
 IF NOT coalesce(app_private.quote_access(p_quote),false) THEN RAISE EXCEPTION 'Acceso denegado'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND team_sharing_enabled) THEN
  PERFORM public.validate_quote_team_legacy(p_quote); RETURN;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quote_services WHERE quote_id=p_quote) THEN RAISE EXCEPTION 'Agrega al menos un servicio'; END IF;
 FOR service IN SELECT id,name FROM public.quote_services WHERE quote_id=p_quote LOOP
  FOREACH function_name IN ARRAY ARRAY['Supervisor','Foreman'] LOOP
   IF NOT EXISTS(SELECT 1 FROM public.quote_service_labors WHERE quote_service_id=service.id
    AND operational_role=function_name AND team_resource_id IS NOT NULL) THEN
    RAISE EXCEPTION 'El servicio % requiere % propio o compartido',service.name,function_name;
   END IF;
  END LOOP;
 END LOOP;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL AND
   (nullif(trim(l.team_resource_label),'') IS NULL OR nullif(trim(l.role_name),'') IS NULL
    OR coalesce(l.employees_quantity,0)<1 OR l.employees_quantity<>trunc(l.employees_quantity)
    OR coalesce(l.hourly_rate,0)<=0 OR l.hourly_rate::text IN ('NaN','Infinity','-Infinity')
    OR coalesce(l.team_service_months,0)<=0 OR l.team_dedication<=0 OR l.team_start IS NULL OR l.team_end IS NULL
    OR abs(l.months_to_work-l.team_service_months*l.team_dedication/100)>0.000001))
  THEN RAISE EXCEPTION 'Revisa nombre, cargo, plazas, tarifa, meses, dedicación y fechas de los responsables'; END IF;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL GROUP BY l.team_resource_id
  HAVING count(DISTINCT (l.operational_role,l.role_name,l.employees_quantity,l.hourly_rate,l.per_diem,l.team_resource_label))>1)
  THEN RAISE EXCEPTION 'Las plazas compartidas deben conservar función, identificador, cargo, cantidad y tarifas'; END IF;
 -- The commitment changes only at a start or at the day after an end.
 IF EXISTS(WITH covered AS (
  SELECT l.* FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
   WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL
 ), points AS (SELECT team_resource_id,team_start AS day FROM covered UNION SELECT team_resource_id,team_end+1 FROM covered)
 SELECT 1 FROM points p JOIN covered c ON c.team_resource_id=p.team_resource_id
  AND p.day BETWEEN c.team_start AND c.team_end GROUP BY p.team_resource_id,p.day HAVING sum(c.team_dedication)>100.000001)
  THEN RAISE EXCEPTION 'Una plaza compartida supera el 100 %% de dedicación en fechas coincidentes. Ajusta la dedicación o crea otro recurso'; END IF;
END $$;

CREATE OR REPLACE FUNCTION app_private.copy_team_budget() RETURNS trigger LANGUAGE plpgsql SET search_path='' AS $$
DECLARE capacity numeric; BEGIN
 IF NEW.quote_service_labor_id IS NOT NULL THEN
  SELECT operational_role,coverage_scope,coalesce(NEW.quote_service_id,quote_service_id),team_resource_id,team_resource_label,employees_quantity
   INTO NEW.operational_role,NEW.coverage_scope,NEW.quote_service_id,NEW.team_resource_id,NEW.team_resource_label,capacity
   FROM public.quote_service_labors WHERE id=NEW.quote_service_labor_id;
  IF NEW.team_resource_id IS NOT NULL THEN
   PERFORM pg_advisory_xact_lock(1678,2);
   IF (SELECT count(*) FROM public.project_labor WHERE project_id=NEW.project_id AND team_resource_id=NEW.team_resource_id)>=capacity
    THEN RAISE EXCEPTION 'La plaza compartida ya está creada en este proyecto; reutiliza su planificación'; END IF;
  END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.save_labor_crew_plan_base(p_project uuid,p_service text,p_rows jsonb,
 p_crew uuid DEFAULT NULL,p_crew_name text DEFAULT NULL,p_foreman uuid DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb; a public.project_labor_assignments; labor_row public.project_labor; selected public.project_labor;
 s public.crew_service_assignments; cid uuid:=p_crew; mid uuid; rows_out jsonb:='[]';
 first_day date; last_day date; day_from date; day_until date; worker uuid; leader public.crew_leaders; BEGIN
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN RAISE EXCEPTION 'Access denied or project is read only'; END IF;
 -- All organization writes use the team lock before row locks/worker locks.
 PERFORM pg_advisory_xact_lock(1678,2);
 PERFORM 1 FROM public.projects WHERE id=p_project FOR UPDATE;
 IF jsonb_typeof(p_rows) IS DISTINCT FROM 'array' OR jsonb_array_length(p_rows)=0 OR jsonb_array_length(p_rows)>500
 THEN RAISE EXCEPTION 'Select between 1 and 500 worker periods'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.project_labor l WHERE l.project_id=p_project AND app_private.labor_service_key(l)=p_service)
 THEN RAISE EXCEPTION 'Select a planned service in this project'; END IF;
 IF cid IS NOT NULL AND nullif(trim(p_crew_name),'') IS NOT NULL THEN RAISE EXCEPTION 'Choose an existing crew or create a new one'; END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  IF jsonb_typeof(item)<>'object' THEN RAISE EXCEPTION 'Invalid worker row'; END IF;
  day_from:=(item->>'valid_from')::date; day_until:=(item->>'valid_until')::date;
  IF day_from IS NULL OR day_until IS NULL OR day_until<day_from THEN RAISE EXCEPTION 'Each worker needs a valid start and end date'; END IF;
  first_day:=least(first_day,day_from); last_day:=greatest(last_day,day_until);
 END LOOP;
 IF cid IS NULL AND nullif(trim(p_crew_name),'') IS NOT NULL THEN
  INSERT INTO public.project_crews(project_id,name) VALUES(p_project,trim(p_crew_name)) RETURNING id INTO cid;
 END IF;
 IF cid IS NOT NULL THEN
  IF NOT EXISTS(SELECT 1 FROM public.project_crews WHERE id=cid AND project_id=p_project AND active)
  THEN RAISE EXCEPTION 'Select an active crew in this project'; END IF;
  SELECT * INTO s FROM public.crew_service_assignments WHERE crew_id=cid AND service_key=p_service
   AND valid_from<=last_day+1 AND valid_until>=first_day-1 ORDER BY valid_from LIMIT 1;
  IF s.id IS NOT NULL AND (s.valid_from>first_day OR s.valid_until<last_day) THEN
   UPDATE public.crew_service_assignments SET valid_from=least(valid_from,first_day),valid_until=greatest(valid_until,last_day) WHERE id=s.id RETURNING * INTO s;
  END IF;
  IF s.id IS NULL THEN
   INSERT INTO public.crew_service_assignments(crew_id,project_id,service_key,valid_from,valid_until)
    VALUES(cid,p_project,p_service,first_day,last_day) RETURNING * INTO s;
  END IF;
  SELECT * INTO leader FROM public.crew_leaders WHERE crew_id=cid AND valid_from<=last_day
   AND (valid_until IS NULL OR valid_until>=first_day) ORDER BY valid_from LIMIT 1;
  IF leader.id IS NULL THEN
   IF p_foreman IS NULL THEN RAISE EXCEPTION 'Select an authorized Foreman covering all selected dates'; END IF;
   INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until) VALUES(cid,p_foreman,first_day,last_day);
  ELSE
   IF p_foreman IS NOT NULL AND p_foreman<>leader.profile_id THEN RAISE EXCEPTION 'End the current leadership period before choosing a different Foreman'; END IF;
   IF leader.valid_until<last_day THEN
    UPDATE public.crew_leaders SET valid_until=last_day WHERE id=leader.id;
   END IF;
   IF leader.valid_from>first_day THEN
    INSERT INTO public.crew_leaders(crew_id,profile_id,valid_from,valid_until) VALUES(cid,leader.profile_id,first_day,leader.valid_from-1);
   END IF;
  END IF;
 END IF;
 FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  day_from:=(item->>'valid_from')::date; day_until:=(item->>'valid_until')::date;
  worker:=(item->>'worker_id')::uuid;
  IF worker IS NULL THEN RAISE EXCEPTION 'Select a worker'; END IF;
  IF item->>'assignment_id' IS NOT NULL THEN
   SELECT * INTO STRICT a FROM public.project_labor_assignments WHERE id=(item->>'assignment_id')::uuid FOR UPDATE;
   SELECT * INTO STRICT labor_row FROM public.project_labor WHERE id=a.project_labor_id;
   IF a.worker_id<>worker OR labor_row.project_id<>p_project OR app_private.labor_service_key(labor_row)<>p_service
    OR a.start_date IS NULL OR a.end_date IS NULL OR day_from<a.start_date OR day_until>a.end_date
   THEN RAISE EXCEPTION 'Worker participation must fit its existing service assignment dates'; END IF;
  ELSE
   SELECT * INTO STRICT labor_row FROM public.project_labor WHERE id=(item->>'project_labor_id')::uuid;
   IF labor_row.project_id<>p_project OR app_private.labor_service_key(labor_row)<>p_service
   THEN RAISE EXCEPTION 'Labor role belongs to another service'; END IF;
   IF NOT EXISTS(SELECT 1 FROM public.workers WHERE id=worker AND status='Active')
   THEN RAISE EXCEPTION 'Select an active worker'; END IF;
   -- Reuse a physical planned slot for non-overlapping periods; retain history.
   IF EXISTS(SELECT 1 FROM public.project_labor_assignments pa JOIN public.project_labor x ON x.id=pa.project_labor_id
    WHERE pa.worker_id=worker AND daterange(pa.start_date,pa.end_date,'[]') && daterange(day_from,day_until,'[]'))
   THEN RAISE EXCEPTION 'Worker already has planning in this interval'; END IF;
   SELECT x.* INTO selected FROM public.project_labor x WHERE x.project_id=p_project
    AND app_private.labor_service_key(x)=p_service AND x.role_name IS NOT DISTINCT FROM labor_row.role_name AND x.operational_role=labor_row.operational_role AND x.coverage_scope=labor_row.coverage_scope AND x.team_resource_id IS NOT DISTINCT FROM labor_row.team_resource_id
    AND NOT EXISTS(SELECT 1 FROM public.project_labor_assignments pa WHERE pa.project_labor_id=x.id AND pa.worker_id=worker)
    AND NOT EXISTS(SELECT 1 FROM public.project_labor_assignments pa WHERE pa.project_labor_id=x.id
     AND daterange(pa.start_date,pa.end_date,'[]') && daterange(day_from,day_until,'[]'))
    ORDER BY x.id LIMIT 1;
   IF selected.id IS NULL THEN RAISE EXCEPTION 'No planned vacancy covers the full interval for role %',labor_row.role_name; END IF;
   INSERT INTO public.project_labor_assignments(project_labor_id,worker_id,start_date,end_date)
    VALUES(selected.id,worker,day_from,day_until) RETURNING * INTO a;
  END IF;
  IF cid IS NOT NULL THEN
   INSERT INTO public.crew_members(crew_id,worker_id,valid_from,valid_until,labor_assignment_id,crew_service_assignment_id)
    VALUES(cid,worker,day_from,day_until,a.id,s.id) RETURNING id INTO mid;
  ELSE mid:=NULL; END IF;
  rows_out:=rows_out||jsonb_build_array(jsonb_build_object('assignment_id',a.id,'membership_id',mid));
 END LOOP;
 RETURN jsonb_build_object('crew_id',cid,'period_id',s.id,'rows',rows_out);
END $$;

ALTER FUNCTION public.get_labor_crew_planning_responsibilities(uuid) RENAME TO get_labor_crew_planning_responsibilities_legacy;
REVOKE ALL ON FUNCTION public.get_labor_crew_planning_responsibilities_legacy(uuid) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION public.get_labor_crew_planning_responsibilities(p_project uuid) RETURNS jsonb
 LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; BEGIN
 result:=public.get_labor_crew_planning_responsibilities_legacy(p_project);
 result:=jsonb_set(result,'{labor}',coalesce((SELECT jsonb_agg(e.value||jsonb_build_object('team_resource_id',l.team_resource_id,
  'team_resource_label',l.team_resource_label)||CASE WHEN l.team_resource_id IS NULL THEN '{}'::jsonb ELSE jsonb_build_object(
  'reference_start',span.first_day,'reference_end',span.last_day,'reference_service_name',l.team_resource_label,
  'reference_source','shared_team','working_days',(SELECT sum((CASE extract(isodow FROM day) WHEN 7 THEN 0 WHEN 6 THEN 0.5 ELSE 1 END)*(1-coalesce(n.partial_ratio,0)))
   FROM generate_series(span.first_day,span.last_day,interval '1 day') day LEFT JOIN public.project_non_working_days n
    ON n.project_id=p_project AND n.date=day::date WHERE span.last_day-span.first_day<=36600)) END)
  FROM jsonb_array_elements(result->'labor') e JOIN public.project_labor l ON l.id=(e.value->>'id')::uuid
  LEFT JOIN LATERAL(SELECT min(q.team_start) first_day,max(q.team_end) last_day FROM public.quote_service_labors q
   JOIN public.quote_services s ON s.id=q.quote_service_id JOIN public.projects p ON p.quote_id=s.quote_id
   WHERE p.id=p_project AND q.team_resource_id=l.team_resource_id) span ON true),'[]'));
 RETURN result||jsonb_build_object('shared_team_resources',coalesce((SELECT jsonb_agg(r) FROM (
  SELECT l.team_resource_id AS resource_id,max(l.team_resource_label) AS label,max(l.operational_role) AS responsibility,
   min(app_private.labor_service_key(l)) AS owner_service_key,jsonb_agg(l.id ORDER BY l.id) AS slots,
   (SELECT jsonb_agg(jsonb_build_object('service_key','q:'||q.quote_service_id,'name',s.name,
    'start_date',q.team_start,'end_date',q.team_end,'dedication',q.team_dedication) ORDER BY s.name)
    FROM public.quote_service_labors q JOIN public.quote_services s ON s.id=q.quote_service_id JOIN public.projects p ON p.quote_id=s.quote_id
    WHERE p.id=p_project AND q.team_resource_id=l.team_resource_id) AS services
  FROM public.project_labor l WHERE l.project_id=p_project AND l.team_resource_id IS NOT NULL GROUP BY l.team_resource_id
 ) r),'[]'));
END $$;
REVOKE ALL ON FUNCTION public.validate_quote_team(uuid),public.get_labor_crew_planning_responsibilities(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.validate_quote_team(uuid),public.get_labor_crew_planning_responsibilities(uuid) TO authenticated;
REVOKE ALL ON FUNCTION app_private.guard_shared_quote_line() FROM PUBLIC,anon,authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
