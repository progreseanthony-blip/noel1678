-- Backfill: llenar quote_service_id en project_machinery y project_materials
-- Project Machinery (via quote_service_machinery_id)
UPDATE public.project_machinery pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_machineries qsm
WHERE pm.quote_service_machinery_id = qsm.id
  AND pm.quote_service_id IS NULL;

-- Project Materials (via quote_service_material_id)
UPDATE public.project_materials pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_materials qsm
WHERE pm.quote_service_material_id = qsm.id
  AND pm.quote_service_id IS NULL;

DO $$
BEGIN
  RAISE NOTICE 'Orphans remaining: machinery=%, materials=%',
    (SELECT COUNT(*) FROM project_machinery WHERE quote_service_id IS NULL AND quote_service_machinery_id IS NOT NULL),
    (SELECT COUNT(*) FROM project_materials WHERE quote_service_id IS NULL AND quote_service_material_id IS NOT NULL);
END $$;

NOTIFY pgrst, 'reload schema';
