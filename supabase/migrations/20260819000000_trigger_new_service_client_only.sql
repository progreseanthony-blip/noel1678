-- ============================================================
-- Migration: Single writer para new_service (el cliente)
-- El trigger YA NO crea project_services para line_type='new_service'.
-- El unico creador es applyBaselineImpact (packages/data BillingService),
-- que inserta servicio + recursos juntos. Esto elimina la doble
-- escritura que generaba servicios duplicados y filas huerfanas
-- (visibles en Timeline/Resource Planning como "General / Unassigned").
--
-- Se conserva intacta la rama 1 (existing_service/deduction mirror
-- + quote_service_change_log). El trigger sigue sin tocar quote_services.
-- ============================================================

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

    -- 2. new_service: INTENCIONALMENTE sin accion.
    -- El cliente (BillingService.applyBaselineImpact) es el unico escritor:
    -- crea el project_service con source_co_id y le asocia los recursos
    -- (project_labor/machinery/materials/instruments) en la misma operacion.
    -- Ver migracion 20260819000001 para limpieza de duplicados historicos.
  END IF;
  RETURN NULL;
END;
$$;
