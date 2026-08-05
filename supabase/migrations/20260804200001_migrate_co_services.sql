-- ============================================================
-- Migration: Migrar datos CO existentes a project_services
-- 1. Copiar quote_services con source_co_id IS NOT NULL
-- 2. Poblar change_order_details.project_service_id para new_service
-- 3. Crear espejos project_services para existing_service con CO aprobado
-- ============================================================

-- 1. Copiar servicios CO nuevos (new_service) desde quote_services
INSERT INTO public.project_services
  (project_id, quote_service_id, name, unit_of_measure, quantity, direct_cost, target_price, source_co_id, created_at)
SELECT
  p.id,
  qs.id,
  qs.name,
  qs.unit_of_measure,
  qs.quantity,
  COALESCE(qs.direct_cost, 0),
  qs.target_price,
  qs.source_co_id,
  qs.created_at
FROM public.quote_services qs
JOIN public.quotes q ON q.id = qs.quote_id
JOIN public.projects p ON p.quote_id = q.id
WHERE qs.source_co_id IS NOT NULL;

-- 2. Actualizar change_order_details: poblar project_service_id para line_type='new_service'
UPDATE public.change_order_details cod
SET project_service_id = ps.id
FROM public.project_services ps
WHERE cod.quote_service_id = ps.quote_service_id
  AND cod.line_type = 'new_service'
  AND ps.quote_service_id IS NOT NULL;

-- 3. Para existing_service con CO aprobado, crear espejos en project_services
--    con la cantidad ajustada (quote.quantity + suma de quantity_change de COs aprobados)
INSERT INTO public.project_services
  (project_id, quote_service_id, name, unit_of_measure, quantity, direct_cost, target_price, source_co_id, created_at)
SELECT DISTINCT ON (qs.id)
  co.project_id,
  qs.id,
  qs.name,
  qs.unit_of_measure,
  qs.quantity + COALESCE(
    (SELECT SUM(cod2.quantity_change)
     FROM public.change_order_details cod2
     JOIN public.change_orders co2 ON co2.id = cod2.change_order_id
     WHERE cod2.quote_service_id = qs.id
       AND co2.status = 'approved'
       AND cod2.line_type IN ('existing_service', 'deduction')),
    0
  ),
  COALESCE(qs.direct_cost, 0),
  qs.target_price,
  NULL,
  now()
FROM public.change_order_details cod
JOIN public.change_orders co ON co.id = cod.change_order_id
JOIN public.quote_services qs ON qs.id = cod.quote_service_id
JOIN public.quotes q ON q.id = qs.quote_id
JOIN public.projects p ON p.quote_id = q.id AND p.id = co.project_id
WHERE cod.line_type = 'existing_service'
  AND co.status = 'approved'
  AND qs.id NOT IN (
    SELECT quote_service_id FROM public.project_services WHERE quote_service_id IS NOT NULL
  );

-- 4. Poblar project_service_id en tablas de recursos para CO resources
--    donde el resource.quote_service_id coincide con el project_service.quote_service_id
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'project_machinery' AND column_name = 'project_service_id') THEN
    UPDATE public.project_machinery pm
    SET project_service_id = ps.id
    FROM public.project_services ps
    WHERE pm.quote_service_id = ps.quote_service_id
      AND ps.quote_service_id IS NOT NULL
      AND pm.source_co_id IS NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'project_labor' AND column_name = 'project_service_id') THEN
    UPDATE public.project_labor pl
    SET project_service_id = ps.id
    FROM public.project_services ps
    WHERE pl.quote_service_id = ps.quote_service_id
      AND ps.quote_service_id IS NOT NULL
      AND pl.source_co_id IS NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'project_materials' AND column_name = 'project_service_id') THEN
    UPDATE public.project_materials pm2
    SET project_service_id = ps.id
    FROM public.project_services ps
    WHERE pm2.quote_service_id = ps.quote_service_id
      AND ps.quote_service_id IS NOT NULL
      AND pm2.source_co_id IS NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'project_instruments' AND column_name = 'project_service_id') THEN
    UPDATE public.project_instruments pi
    SET project_service_id = ps.id
    FROM public.project_services ps
    WHERE pi.quote_service_id = ps.quote_service_id
      AND ps.quote_service_id IS NOT NULL
      AND pi.source_co_id IS NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_name = 'project_tasks' AND column_name = 'project_service_id') THEN
    UPDATE public.project_tasks pt
    SET project_service_id = ps.id
    FROM public.project_services ps
    WHERE pt.quote_service_id = ps.quote_service_id
      AND ps.quote_service_id IS NOT NULL
      AND pt.quote_service_id IS NOT NULL;
  END IF;
END
$$;
