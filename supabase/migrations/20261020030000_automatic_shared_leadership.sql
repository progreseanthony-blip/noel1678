BEGIN;
-- Existing approved budgets retain their allocation until explicitly reviewed.
ALTER TABLE public.quotes ADD COLUMN team_allocation_automatic boolean NOT NULL DEFAULT false;
ALTER TABLE public.quote_service_labors ADD COLUMN team_cost_primary boolean NOT NULL DEFAULT false;
CREATE TABLE public.quote_team_allocation_approvals (
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
 quote_id uuid NOT NULL REFERENCES public.quotes(id) ON DELETE CASCADE,
 fingerprint text NOT NULL,
 approved_by uuid NOT NULL REFERENCES public.profiles(id),
 approved_at timestamptz NOT NULL DEFAULT now(),
 snapshot jsonb NOT NULL
);
ALTER TABLE public.quote_team_allocation_approvals ENABLE ROW LEVEL SECURITY;
CREATE POLICY read_admin ON public.quote_team_allocation_approvals FOR SELECT TO authenticated USING(app_private.is_admin());
REVOKE ALL ON public.quote_team_allocation_approvals FROM PUBLIC,anon,authenticated;
GRANT SELECT ON public.quote_team_allocation_approvals TO authenticated;
CREATE INDEX quote_team_allocation_approval_lookup ON public.quote_team_allocation_approvals(quote_id,fingerprint);
ALTER FUNCTION public.validate_quote_team(uuid) RENAME TO validate_quote_team_manual;
REVOKE ALL ON FUNCTION public.validate_quote_team_manual(uuid) FROM PUBLIC,anon,authenticated;
CREATE FUNCTION app_private.validate_quote_team_structure(p_quote uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE service record; function_name text; BEGIN
 IF NOT coalesce(app_private.quote_access(p_quote),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND team_sharing_enabled) THEN
  PERFORM public.validate_quote_team_legacy(p_quote); RETURN;
 END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quote_services WHERE quote_id=p_quote) THEN RAISE EXCEPTION 'Add at least one service'; END IF;
 FOR service IN SELECT id,name FROM public.quote_services WHERE quote_id=p_quote LOOP
  FOREACH function_name IN ARRAY ARRAY['Supervisor','Foreman'] LOOP
   IF NOT EXISTS(SELECT 1 FROM public.quote_service_labors WHERE quote_service_id=service.id
    AND operational_role=function_name AND team_resource_id IS NOT NULL) THEN
    RAISE EXCEPTION 'Service % requires a dedicated or shared %',service.name,function_name;
   END IF;
  END LOOP;
 END LOOP;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL AND
   (nullif(trim(l.team_resource_label),'') IS NULL OR nullif(trim(l.role_name),'') IS NULL
    OR coalesce(l.employees_quantity,0)<1 OR l.employees_quantity<>trunc(l.employees_quantity)
    OR coalesce(l.hourly_rate,0)<=0 OR l.hourly_rate::text IN ('NaN','Infinity','-Infinity')
    OR coalesce(l.team_service_months,0)<=0 OR l.team_dedication<0 OR l.team_start IS NULL OR l.team_end IS NULL
    OR l.months_to_work IS NULL OR l.months_to_work<0 OR l.months_to_work::text IN ('NaN','Infinity','-Infinity') OR l.team_service_months::text IN ('NaN','Infinity','-Infinity') OR coalesce(l.per_diem,0)<0 OR coalesce(l.per_diem,0)::text IN ('NaN','Infinity','-Infinity')))
  THEN RAISE EXCEPTION 'Check leadership names, roles, positions, rates, months and dates'; END IF;
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL GROUP BY l.team_resource_id
  HAVING count(DISTINCT (l.operational_role,l.role_name,l.employees_quantity,l.hourly_rate,l.per_diem,l.team_resource_label))>1)
  THEN RAISE EXCEPTION 'Shared positions must have matching responsibilities, names, roles, quantities and rates'; END IF;
END $$;

-- A finite date segment is counted once for a resource, regardless of coverage.
-- Density preserves the estimate's calendar-month/220-hour basis. When durations
-- differ, the largest active daily budget is shared in proportion to each line.
CREATE FUNCTION app_private.quote_team_allocation(p_quote uuid)
 RETURNS TABLE(line_id uuid, allocated_months numeric, overlapping boolean)
 LANGUAGE sql STABLE SET search_path='' AS $$
 WITH rows AS (
  SELECT l.*,l.team_service_months/(l.team_end-l.team_start+1) AS density
  FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL
   AND l.team_start IS NOT NULL AND l.team_end>=l.team_start AND l.team_service_months>0
 ), points AS (
  SELECT team_resource_id,team_start AS day FROM rows
  UNION SELECT team_resource_id,team_end+1 FROM rows
 ), segments AS (
  SELECT team_resource_id,day,lead(day) OVER(PARTITION BY team_resource_id ORDER BY day) AS until FROM points
 ), capacity AS (
  SELECT p.team_resource_id,p.day,p.until,max(r.density) AS density,sum(r.density) AS weight,count(*) AS active
  FROM segments p JOIN rows r ON r.team_resource_id=p.team_resource_id AND p.day BETWEEN r.team_start AND r.team_end
  WHERE p.until IS NOT NULL GROUP BY p.team_resource_id,p.day,p.until
 ), parts AS (
  SELECT r.id,sum((c.until-c.day)*c.density*
   CASE WHEN EXISTS(SELECT 1 FROM rows x WHERE x.team_resource_id=r.team_resource_id AND x.team_cost_primary)
     THEN CASE WHEN r.team_cost_primary THEN 1 ELSE 0 END
     ELSE CASE WHEN c.day BETWEEN r.team_start AND r.team_end THEN r.density/c.weight ELSE 0 END END) AS months,
   bool_or(c.active>1) AS overlap
  FROM rows r JOIN capacity c ON c.team_resource_id=r.team_resource_id GROUP BY r.id
 ) SELECT id,months,overlap FROM parts
$$;
CREATE FUNCTION app_private.quote_team_fingerprint(p_quote uuid) RETURNS text LANGUAGE sql STABLE SET search_path='' AS $$
 SELECT md5(jsonb_build_object('lines',coalesce(jsonb_agg(jsonb_build_array(l.id,l.quote_service_id,l.team_resource_id,l.team_resource_label,
  l.operational_role,l.role_name,l.employees_quantity,l.hourly_rate,l.per_diem,l.team_service_months,
  l.team_start,l.team_end,l.team_cost_primary,l.months_to_work) ORDER BY l.id)::text,''),
  'quote',(SELECT jsonb_build_array(q.title,q.total_amount,q.quote_type) FROM public.quotes q WHERE q.id=p_quote),
  'services',(SELECT jsonb_agg(jsonb_build_array(x.id,x.name,x.direct_cost,x.overhead_percentage,x.profit_percentage,x.unit_of_measure,x.quantity) ORDER BY x.id) FROM public.quote_services x WHERE x.quote_id=p_quote))::text)
 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
 WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL
$$;
CREATE FUNCTION public.validate_quote_team(p_quote uuid) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
BEGIN
 IF NOT coalesce(app_private.quote_access(p_quote),false) THEN RAISE EXCEPTION 'Access denied'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND team_sharing_enabled AND team_allocation_automatic) THEN
  PERFORM public.validate_quote_team_manual(p_quote); RETURN;
 END IF;
 PERFORM app_private.validate_quote_team_structure(p_quote);
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL GROUP BY l.team_resource_id HAVING count(*) FILTER(WHERE l.team_cost_primary)>1)
 THEN RAISE EXCEPTION 'Choose only one cost service for each shared resource'; END IF;
 IF EXISTS(SELECT 1 FROM app_private.quote_team_allocation(p_quote) a JOIN public.quote_service_labors l ON l.id=a.line_id
  WHERE abs(l.months_to_work-a.allocated_months)>0.000001)
 THEN RAISE EXCEPTION 'Review and apply automatic shared-resource allocation before approval'; END IF;
 IF EXISTS(SELECT 1 FROM app_private.quote_team_allocation(p_quote) WHERE overlapping)
  AND NOT EXISTS(SELECT 1 FROM public.quote_team_allocation_approvals WHERE quote_id=p_quote AND fingerprint=app_private.quote_team_fingerprint(p_quote))
 THEN RAISE EXCEPTION 'An administrator must confirm shared coverage on overlapping dates'; END IF;
END $$;

CREATE FUNCTION public.prepare_quote_team_allocation(p_quote uuid,p_confirm boolean DEFAULT false,p_fingerprint text DEFAULT NULL)
 RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE result jsonb; signature text; changes jsonb; warnings jsonb; total_delta numeric;
BEGIN
 IF NOT coalesce(app_private.is_admin(),false) THEN RAISE EXCEPTION 'Only administrators can confirm shared coverage'; END IF;
 PERFORM pg_advisory_xact_lock(1678,3);
 PERFORM 1 FROM public.quotes WHERE id=p_quote FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Estimate not found'; END IF;
 IF NOT EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND team_sharing_enabled) THEN
  RETURN jsonb_build_object('enabled',false,'resources','[]'::jsonb);
 END IF;
 IF EXISTS(SELECT 1 FROM public.projects WHERE quote_id=p_quote) THEN RAISE EXCEPTION 'Manage planned resources from the project'; END IF;
 PERFORM app_private.validate_quote_team_structure(p_quote);
 IF EXISTS(SELECT 1 FROM public.quote_service_labors l JOIN public.quote_services s ON s.id=l.quote_service_id
  WHERE s.quote_id=p_quote AND l.team_resource_id IS NOT NULL GROUP BY l.team_resource_id HAVING count(*) FILTER(WHERE l.team_cost_primary)>1)
 THEN RAISE EXCEPTION 'Choose only one cost service for each shared resource'; END IF;
 signature:=app_private.quote_team_fingerprint(p_quote);
 SELECT coalesce(jsonb_agg(jsonb_build_object('service_id',s.id,'name',s.name,'before',s.direct_cost,'delta',round(d.delta,2)) ORDER BY s.id),'[]'::jsonb),coalesce(sum(round(d.delta,2)),0)
 INTO changes,total_delta
 FROM public.quote_services s CROSS JOIN LATERAL (
  SELECT CASE WHEN lower(s.unit_of_measure)='ls' OR EXISTS(SELECT 1 FROM public.quotes WHERE id=p_quote AND quote_type='staffing') THEN 0
  ELSE coalesce(sum((a.allocated_months-l.months_to_work)*220*l.employees_quantity*(l.hourly_rate+coalesce(l.per_diem,0))),0)
   *(1+coalesce(s.overhead_percentage,0)/100)*(1+coalesce(s.profit_percentage,0)/100) END AS delta
  FROM app_private.quote_team_allocation(p_quote) a JOIN public.quote_service_labors l ON l.id=a.line_id WHERE l.quote_service_id=s.id
 ) d WHERE s.quote_id=p_quote;
 SELECT coalesce(jsonb_agg(resource ORDER BY resource->>'label'),'[]'::jsonb) INTO warnings FROM (
  SELECT jsonb_build_object('label',min(l.team_resource_label),'services',string_agg(s.name,', ' ORDER BY s.name),
   'start',min(l.team_start),'end',max(l.team_end),
   'method',CASE WHEN bool_or(l.team_cost_primary) THEN 'Selected cost service' ELSE 'Automatic distribution' END) AS resource
  FROM app_private.quote_team_allocation(p_quote) a JOIN public.quote_service_labors l ON l.id=a.line_id
  JOIN public.quote_services s ON s.id=l.quote_service_id WHERE a.overlapping GROUP BY l.team_resource_id
 ) x;
 SELECT jsonb_build_object('enabled',true,'fingerprint',signature,'resources',warnings,'services',changes,
  'previous_total',coalesce(total_amount,0),'total',coalesce(total_amount,0)+total_delta) INTO result FROM public.quotes WHERE id=p_quote;
 IF NOT p_confirm THEN RETURN result; END IF;
 IF p_fingerprint IS DISTINCT FROM signature THEN RAISE EXCEPTION 'The estimate changed. Review the updated allocation before confirming'; END IF;
 UPDATE public.quote_service_labors l SET months_to_work=a.allocated_months,
  team_dedication=least(100,greatest(0,a.allocated_months/l.team_service_months*100))
 FROM app_private.quote_team_allocation(p_quote) a WHERE a.line_id=l.id;
 UPDATE public.quote_services s SET direct_cost=s.direct_cost+(c->>'delta')::numeric
 FROM jsonb_array_elements(changes) c WHERE s.id=(c->>'service_id')::uuid;
 UPDATE public.quotes SET team_allocation_automatic=true,total_amount=coalesce(total_amount,0)+total_delta WHERE id=p_quote;
 -- The saved signature describes the final budget, so later changes invalidate it.
 INSERT INTO public.quote_team_allocation_approvals(quote_id,fingerprint,approved_by,snapshot)
 VALUES(p_quote,app_private.quote_team_fingerprint(p_quote),auth.uid(),result);
 PERFORM public.validate_quote_team(p_quote);
 RETURN result;
END $$;
REVOKE ALL ON FUNCTION app_private.quote_team_allocation(uuid),app_private.quote_team_fingerprint(uuid),app_private.validate_quote_team_structure(uuid) FROM PUBLIC,anon,authenticated;
REVOKE ALL ON FUNCTION public.prepare_quote_team_allocation(uuid,boolean,text),public.validate_quote_team(uuid) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.prepare_quote_team_allocation(uuid,boolean,text),public.validate_quote_team(uuid) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
