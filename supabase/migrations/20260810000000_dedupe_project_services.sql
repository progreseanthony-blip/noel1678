-- ============================================================
-- Migration: Deduplicar project_services y trigger idempotente
-- 1. Fusionar project_services duplicados (mismo source_co_id + project_id)
--    conservando el que posee recursos; reasignar change_order_details
-- 2. Hacer idempotente la creación de new_service en log_quote_service_changes
-- ============================================================

-- 1. Fusionar duplicados existentes
DO $$
DECLARE
  v_co    record;
  v_dup   record;
  v_keep  uuid;
  v_count int;
BEGIN
  FOR v_co IN
    SELECT source_co_id, project_id
    FROM public.project_services
    WHERE source_co_id IS NOT NULL
    GROUP BY source_co_id, project_id
    HAVING COUNT(*) > 1
  LOOP
    -- Conservar el project_service con más recursos (el creado por applyBaselineImpact)
    SELECT ps.id INTO v_keep
    FROM public.project_services ps
    WHERE ps.source_co_id = v_co.source_co_id
      AND ps.project_id = v_co.project_id
    ORDER BY
      ((SELECT COUNT(*) FROM public.project_machinery m WHERE m.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_labor l WHERE l.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_materials ma WHERE ma.project_service_id = ps.id)
     + (SELECT COUNT(*) FROM public.project_instruments i WHERE i.project_service_id = ps.id)) DESC,
      ps.created_at ASC
    LIMIT 1;

    IF v_keep IS NULL THEN
      CONTINUE;
    END IF;

    -- Reasignar recursos al conservado
    UPDATE public.project_machinery
    SET project_service_id = v_keep
    WHERE source_co_id = v_co.source_co_id
      AND project_service_id IS DISTINCT FROM v_keep;
    UPDATE public.project_labor
    SET project_service_id = v_keep
    WHERE source_co_id = v_co.source_co_id
      AND project_service_id IS DISTINCT FROM v_keep;
    UPDATE public.project_materials
    SET project_service_id = v_keep
    WHERE source_co_id = v_co.source_co_id
      AND project_service_id IS DISTINCT FROM v_keep;
    UPDATE public.project_instruments
    SET project_service_id = v_keep
    WHERE source_co_id = v_co.source_co_id
      AND project_service_id IS DISTINCT FROM v_keep;

    -- Reasignar change_order_details al conservado
    UPDATE public.change_order_details
    SET project_service_id = v_keep
    WHERE change_order_id = v_co.source_co_id
      AND project_service_id IS DISTINCT FROM v_keep;

    -- Borrar huérfanos que ya no referencian nada
    FOR v_dup IN
      SELECT id
      FROM public.project_services
      WHERE source_co_id = v_co.source_co_id
        AND project_id = v_co.project_id
        AND id <> v_keep
    LOOP
      SELECT COUNT(*) INTO v_count
      FROM public.change_order_details
      WHERE project_service_id = v_dup.id;
      IF v_count = 0 THEN
        DELETE FROM public.project_services WHERE id = v_dup.id;
      END IF;
    END LOOP;
  END LOOP;
END
$$;

-- 2. Trigger idempotente: no duplicar new_service si ya existe
CREATE OR REPLACE FUNCTION public.log_quote_service_changes()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_project_id          uuid;
  v_project_service_id  uuid;
  v_line                record;
  v_existing_qty        numeric;
BEGIN
  IF NEW.status = 'approved' AND OLD.status = 'submitted' THEN
    SELECT project_id INTO v_project_id FROM public.change_orders WHERE id = NEW.id;

    -- 1. existing_service / deduction: crear o actualizar project_service mirror
    FOR v_line IN
      SELECT
        cod.quote_service_id,
        cod.quantity_change,
        qs.name,
        qs.unit_of_measure,
        qs.quantity,
        COALESCE(qs.direct_cost, 0) as direct_cost,
        qs.target_price
      FROM public.change_order_details cod
      JOIN public.quote_services qs ON qs.id = cod.quote_service_id
      WHERE cod.change_order_id = NEW.id
        AND cod.line_type IN ('existing_service', 'deduction')
        AND cod.quote_service_id IS NOT NULL
        AND cod.quantity_change != 0
    LOOP
      SELECT id INTO v_project_service_id
      FROM public.project_services
      WHERE project_id = v_project_id
        AND quote_service_id = v_line.quote_service_id;

      IF v_project_service_id IS NULL THEN
        INSERT INTO public.project_services
          (project_id, quote_service_id, name, unit_of_measure, quantity, direct_cost, target_price)
        VALUES
          (v_project_id, v_line.quote_service_id, v_line.name,
           COALESCE(v_line.unit_of_measure, 'und'), v_line.quantity,
           v_line.direct_cost, v_line.target_price)
        RETURNING id INTO v_project_service_id;
      END IF;

      SELECT quantity INTO v_existing_qty FROM public.project_services WHERE id = v_project_service_id;

      UPDATE public.project_services
      SET quantity = quantity + v_line.quantity_change
      WHERE id = v_project_service_id;

      INSERT INTO public.quote_service_change_log
        (quote_service_id, change_order_id, previous_quantity, new_quantity, delta_quantity)
      VALUES
        (v_line.quote_service_id, NEW.id, COALESCE(v_existing_qty, 0),
         COALESCE(v_existing_qty, 0) + v_line.quantity_change, v_line.quantity_change);
    END LOOP;

    -- 2. new_service: crear project_service solo si no existe para esta CO
    FOR v_line IN
      SELECT
        cod.id as detail_id,
        cod.service_name,
        cod.unit_of_measure,
        cod.quantity_change,
        cod.unit_price
      FROM public.change_order_details cod
      WHERE cod.change_order_id = NEW.id
        AND cod.line_type = 'new_service'
        AND cod.quantity_change > 0
    LOOP
      SELECT id INTO v_project_service_id
      FROM public.project_services
      WHERE project_id = v_project_id
        AND source_co_id = NEW.id
        AND name = v_line.service_name
      LIMIT 1;

      IF v_project_service_id IS NULL THEN
        INSERT INTO public.project_services
          (project_id, name, unit_of_measure, quantity, direct_cost, target_price, source_co_id)
        VALUES
          (v_project_id, v_line.service_name,
           COALESCE(v_line.unit_of_measure, 'und'), v_line.quantity_change,
           0, COALESCE(v_line.unit_price, 0), NEW.id)
        RETURNING id INTO v_project_service_id;
      END IF;

      UPDATE public.change_order_details
      SET project_service_id = v_project_service_id
      WHERE id = v_line.detail_id;
    END LOOP;
  END IF;
  RETURN NULL;
END;
$$;
