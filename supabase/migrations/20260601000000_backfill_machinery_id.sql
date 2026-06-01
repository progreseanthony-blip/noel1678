-- Backfill: llenar machinery_id en project_machinery por nombre
UPDATE public.project_machinery pm
SET machinery_id = m.id
FROM public.machinery m
WHERE pm.machinery_name = m.description
  AND pm.machinery_id IS NULL;

DO $$
BEGIN
  RAISE NOTICE 'Orphan machinery_id remaining: %',
    (SELECT COUNT(*) FROM project_machinery WHERE machinery_id IS NULL);
END $$;

NOTIFY pgrst, 'reload schema';
