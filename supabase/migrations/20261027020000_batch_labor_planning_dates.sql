BEGIN;

-- Keep the existing history/overlap protections and apply the selection in one
-- transaction: any rejected worker rolls back the entire batch.
CREATE OR REPLACE FUNCTION public.update_labor_crew_dates_batch(
 p_project uuid,p_assignments uuid[],p_from date,p_until date)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE assignment record;
BEGIN
 PERFORM pg_advisory_xact_lock(1678,2);
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN
  RAISE EXCEPTION 'Access denied or project is read only';
 END IF;
 IF p_from IS NULL OR p_until IS NULL OR NOT isfinite(p_from) OR NOT isfinite(p_until) OR p_until<p_from THEN
  RAISE EXCEPTION 'Select valid planning dates';
 END IF;
 IF coalesce(cardinality(p_assignments),0) NOT BETWEEN 1 AND 500
  OR EXISTS(SELECT 1 FROM unnest(p_assignments) AS chosen(id) GROUP BY chosen.id HAVING count(*)>1)
  OR EXISTS(SELECT 1 FROM unnest(p_assignments) AS chosen(id) LEFT JOIN public.project_labor_assignments a ON a.id=chosen.id
   LEFT JOIN public.project_labor l ON l.id=a.project_labor_id WHERE a.id IS NULL OR l.project_id<>p_project) THEN
  RAISE EXCEPTION 'Select between 1 and 500 distinct worker periods in this project';
 END IF;
 FOR assignment IN
  SELECT a.id,w.full_name FROM public.project_labor_assignments a
   JOIN public.workers w ON w.id=a.worker_id WHERE a.id=ANY(p_assignments) ORDER BY a.id
 LOOP
  BEGIN
   PERFORM public.update_labor_crew_dates(assignment.id,p_from,p_until);
  EXCEPTION WHEN OTHERS THEN
   RAISE EXCEPTION USING ERRCODE=SQLSTATE,
    MESSAGE=format('No se pudieron actualizar las fechas de %s: %s',assignment.full_name,SQLERRM);
  END;
 END LOOP;
END $$;
REVOKE ALL ON FUNCTION public.update_labor_crew_dates_batch(uuid,uuid[],date,date) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.update_labor_crew_dates_batch(uuid,uuid[],date,date) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
