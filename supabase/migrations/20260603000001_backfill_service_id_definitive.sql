-- Backfill definitivo: llena quote_service_id usando todas las fuentes disponibles
-- Labor (vía quote_service_labor_id)
UPDATE public.project_labor pl
SET quote_service_id = qsl.quote_service_id
FROM public.quote_service_labors qsl
WHERE pl.quote_service_labor_id = qsl.id AND pl.quote_service_id IS NULL;

-- Labor (vía calculation_metadata.service_id para extras sin qsl_id)
UPDATE public.project_labor pl
SET quote_service_id = (pl.calculation_metadata->>'service_id')::uuid
WHERE pl.calculation_metadata->>'service_id' IS NOT NULL AND pl.quote_service_id IS NULL;

-- Machinery (vía quote_service_machinery_id)
UPDATE public.project_machinery pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_machineries qsm
WHERE pm.quote_service_machinery_id = qsm.id AND pm.quote_service_id IS NULL;

-- Machinery (vía calculation_metadata)
UPDATE public.project_machinery pm
SET quote_service_id = (pm.calculation_metadata->>'service_id')::uuid
WHERE pm.calculation_metadata->>'service_id' IS NOT NULL AND pm.quote_service_id IS NULL;

-- Materials (vía quote_service_material_id)
UPDATE public.project_materials pm
SET quote_service_id = qsm.quote_service_id
FROM public.quote_service_materials qsm
WHERE pm.quote_service_material_id = qsm.id AND pm.quote_service_id IS NULL;

-- Materials (vía calculation_metadata)
UPDATE public.project_materials pm
SET quote_service_id = (pm.calculation_metadata->>'service_id')::uuid
WHERE pm.calculation_metadata->>'service_id' IS NOT NULL AND pm.quote_service_id IS NULL;

-- Instruments (vía quote_service_instrument_id)
UPDATE public.project_instruments pi
SET quote_service_id = qsi.quote_service_id
FROM public.quote_service_instruments qsi
WHERE pi.quote_service_instrument_id = qsi.id AND pi.quote_service_id IS NULL;

-- Instruments (vía calculation_metadata)
UPDATE public.project_instruments pi
SET quote_service_id = (pi.calculation_metadata->>'service_id')::uuid
WHERE pi.calculation_metadata->>'service_id' IS NOT NULL AND pi.quote_service_id IS NULL;

DO $$
BEGIN
  RAISE NOTICE 'Orphans remaining: labor=%, machinery=%, materials=%, instruments=%',
    (SELECT COUNT(*) FROM project_labor WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_machinery WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_materials WHERE quote_service_id IS NULL),
    (SELECT COUNT(*) FROM project_instruments WHERE quote_service_id IS NULL);
END $$;

NOTIFY pgrst, 'reload schema';
