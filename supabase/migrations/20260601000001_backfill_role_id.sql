-- Backfill: llenar role_id en project_labor por nombre (case-insensitive)
UPDATE public.project_labor pl
SET role_id = lr.id
FROM public.labor_roles lr
WHERE LOWER(pl.role_name) = LOWER(lr.description)
  AND pl.role_id IS NULL;

DO $$
BEGIN
  RAISE NOTICE 'Orphan role_id remaining: %',
    (SELECT COUNT(*) FROM project_labor WHERE role_id IS NULL);
END $$;

NOTIFY pgrst, 'reload schema';
