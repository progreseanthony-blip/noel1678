BEGIN;
CREATE FUNCTION public.save_machinery_planning(p_project uuid,p_rows jsonb)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path='' AS $$
DECLARE item jsonb; plan jsonb; m public.project_machinery%ROWTYPE;
 a public.project_machinery_assignments%ROWTYPE; original public.project_machinery_assignments%ROWTYPE;
 mode text; first_day date; last_day date; units int; planned int; total int;
 changed int:=0; added int:=0; before_rows jsonb; kept uuid[]; used uuid[];
BEGIN
 IF NOT coalesce(app_private.organize_project_team(p_project),false) THEN
  RAISE EXCEPTION 'Machinery planning requires an active project and authorized Administrator or Supervisor';
 END IF;
 PERFORM 1 FROM public.projects WHERE id=p_project AND status='active' FOR SHARE;
 IF NOT FOUND THEN RAISE EXCEPTION 'This project is read-only'; END IF;
 IF jsonb_typeof(p_rows) IS DISTINCT FROM 'array' OR jsonb_array_length(p_rows)=0 THEN
  RAISE EXCEPTION 'Select at least one machine'; END IF;
 IF (SELECT count(*)<>count(DISTINCT value->>'id') FROM jsonb_array_elements(p_rows)) THEN
  RAISE EXCEPTION 'A machine can occur only once in a planning request'; END IF;
 -- Lock deterministically; every request below belongs to this exact project.
 PERFORM id FROM public.project_machinery WHERE project_id=p_project
  AND id IN(SELECT (value->>'id')::uuid FROM jsonb_array_elements(p_rows)) ORDER BY id FOR UPDATE;
 FOR item IN SELECT value FROM jsonb_array_elements(p_rows) LOOP
  SELECT * INTO m FROM public.project_machinery WHERE id=(item->>'id')::uuid AND project_id=p_project;
  IF NOT FOUND THEN RAISE EXCEPTION 'Machine is missing or belongs to another project'; END IF;
  IF coalesce(m.expected_quantity,0)<1 OR m.expected_quantity<>trunc(m.expected_quantity) THEN
   RAISE EXCEPTION 'Check the expected unit quantity for %',m.machinery_name; END IF;
  IF (item->>'capacity')::int IS DISTINCT FROM m.expected_quantity THEN
   RAISE EXCEPTION 'Unit quantities changed. Refresh planning before saving'; END IF;
  PERFORM id FROM public.project_machinery_assignments WHERE project_machinery_id=m.id ORDER BY id FOR UPDATE;
  SELECT coalesce(jsonb_agg(jsonb_build_object('id',id,'start_date',start_date,'end_date',end_date,'quantity',quantity) ORDER BY id),'[]'::jsonb),coalesce(sum(quantity),0)
   INTO before_rows,planned FROM public.project_machinery_assignments WHERE project_machinery_id=m.id;
  IF item->'previous' IS DISTINCT FROM before_rows THEN
   RAISE EXCEPTION 'Planning changed for %. Refresh and review the current assignments',m.machinery_name; END IF;
  IF planned>m.expected_quantity THEN RAISE EXCEPTION 'Planned units exceed the expected quantity for %',m.machinery_name; END IF;
  IF EXISTS(SELECT 1 FROM public.project_machinery_assignments WHERE project_machinery_id=m.id AND quantity<1) THEN
   RAISE EXCEPTION 'Existing unit quantities are invalid for %',m.machinery_name; END IF;
  mode:=item->>'mode';
  IF mode IN ('pending','replace') THEN
   first_day:=(item->>'start_date')::date; last_day:=(item->>'end_date')::date;
   IF first_day IS NULL OR last_day IS NULL OR NOT isfinite(first_day) OR NOT isfinite(last_day) OR last_day<first_day THEN
    RAISE EXCEPTION 'Select valid start and end dates'; END IF;
   IF mode='replace' THEN
    -- Preserve IDs, quantities, statuses and actual execution dates.
    UPDATE public.project_machinery_assignments SET start_date=first_day,end_date=last_day WHERE project_machinery_id=m.id;
   END IF;
   units:=m.expected_quantity-planned;
   IF units>0 THEN
    INSERT INTO public.project_machinery_assignments(project_machinery_id,start_date,end_date,quantity)
     VALUES(m.id,first_day,last_day,units);
    added:=added+units;
   END IF;
   IF mode='replace' OR units>0 THEN changed:=changed+1; END IF;
  ELSIF mode='units' THEN
   IF jsonb_typeof(item->'plans') IS DISTINCT FROM 'array' OR jsonb_array_length(item->'plans')=0 THEN
    RAISE EXCEPTION 'Assign dates to at least one unit'; END IF;
   SELECT coalesce(sum((value->>'quantity')::int),0) INTO total FROM jsonb_array_elements(item->'plans');
   IF total>m.expected_quantity THEN RAISE EXCEPTION 'Planned units exceed the expected quantity'; END IF;
   kept:='{}'; used:='{}';
   FOR plan IN SELECT value FROM jsonb_array_elements(item->'plans') LOOP
    first_day:=(plan->>'start_date')::date;last_day:=(plan->>'end_date')::date;units:=(plan->>'quantity')::int;
    IF units IS NULL OR units<1 OR first_day IS NULL OR last_day IS NULL OR NOT isfinite(first_day) OR NOT isfinite(last_day) OR last_day<first_day THEN
     RAISE EXCEPTION 'Each unit plan needs a positive quantity and valid dates'; END IF;
    a:=NULL;
    IF plan->>'assignment_id' IS NOT NULL THEN
     SELECT * INTO original FROM public.project_machinery_assignments WHERE id=(plan->>'assignment_id')::uuid AND project_machinery_id=m.id;
     IF NOT FOUND THEN RAISE EXCEPTION 'Unit assignment changed. Refresh planning'; END IF;
     IF units<>original.quantity AND (original.actual_start_date IS NOT NULL OR original.actual_end_date IS NOT NULL OR coalesce(original.status,'scheduled')<>'scheduled') THEN
      RAISE EXCEPTION 'The quantity of a group with execution history cannot be changed'; END IF;
     IF original.id=ANY(used) THEN
      IF original.actual_start_date IS NOT NULL OR original.actual_end_date IS NOT NULL OR coalesce(original.status,'scheduled')<>'scheduled' THEN
       RAISE EXCEPTION 'Units with execution history cannot be split into new assignments'; END IF;
     ELSE
      used:=array_append(used,original.id);
      UPDATE public.project_machinery_assignments SET start_date=first_day,end_date=last_day,quantity=units WHERE id=original.id RETURNING * INTO a;
     END IF;
    END IF;
    IF a.id IS NULL THEN
     INSERT INTO public.project_machinery_assignments(project_machinery_id,start_date,end_date,quantity)
      VALUES(m.id,first_day,last_day,units) RETURNING * INTO a;
    END IF;
    kept:=array_append(kept,a.id);
   END LOOP;
   IF EXISTS(SELECT 1 FROM public.project_machinery_assignments WHERE project_machinery_id=m.id AND NOT(id=ANY(kept))
     AND (actual_start_date IS NOT NULL OR actual_end_date IS NOT NULL OR coalesce(status,'scheduled')<>'scheduled')) THEN
    RAISE EXCEPTION 'An assignment with execution history cannot be removed'; END IF;
   DELETE FROM public.project_machinery_assignments WHERE project_machinery_id=m.id AND NOT(id=ANY(kept));
   changed:=changed+1;
  ELSE RAISE EXCEPTION 'Unknown machinery planning action'; END IF;
  -- The summary covers all units, rather than the first arbitrary group.
  UPDATE public.project_machinery SET
   start_date=(SELECT min(start_date) FROM public.project_machinery_assignments WHERE project_machinery_id=m.id),
   end_date=(SELECT max(end_date) FROM public.project_machinery_assignments WHERE project_machinery_id=m.id)
   WHERE id=m.id;
 END LOOP;
 RETURN jsonb_build_object('machines',changed,'added_units',added);
END $$;
REVOKE ALL ON FUNCTION public.save_machinery_planning(uuid,jsonb) FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.save_machinery_planning(uuid,jsonb) TO authenticated;
NOTIFY pgrst,'reload schema';
COMMIT;
