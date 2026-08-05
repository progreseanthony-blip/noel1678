-- ============================================================
-- Migration: Actualizar trigger log_quote_service_changes
-- Ahora usa project_services en vez de modificar quote_services
-- quote_services = estimación baseline (nunca se modifica)
-- project_services = versión viva del proyecto
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
      -- Buscar project_service mirror existente
      SELECT id INTO v_project_service_id
      FROM public.project_services
      WHERE project_id = v_project_id
        AND quote_service_id = v_line.quote_service_id;

      IF v_project_service_id IS NULL THEN
        -- Crear mirror copiando del quote original
        INSERT INTO public.project_services
          (project_id, quote_service_id, name, unit_of_measure, quantity, direct_cost, target_price)
        VALUES
          (v_project_id, v_line.quote_service_id, v_line.name,
           COALESCE(v_line.unit_of_measure, 'und'), v_line.quantity,
           v_line.direct_cost, v_line.target_price)
        RETURNING id INTO v_project_service_id;
      END IF;

      -- Guardar cantidad anterior para el log
      SELECT quantity INTO v_existing_qty FROM public.project_services WHERE id = v_project_service_id;

      -- Actualizar project_service (NO quote_services)
      UPDATE public.project_services
      SET quantity = quantity + v_line.quantity_change
      WHERE id = v_project_service_id;

      -- Registrar cambio en log (referencia a quote_service original)
      INSERT INTO public.quote_service_change_log
        (quote_service_id, change_order_id, previous_quantity, new_quantity, delta_quantity)
      VALUES
        (v_line.quote_service_id, NEW.id, COALESCE(v_existing_qty, 0),
         COALESCE(v_existing_qty, 0) + v_line.quantity_change, v_line.quantity_change);
    END LOOP;

    -- 2. new_service: crear project_service directamente (sin tocar quote_services)
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
      INSERT INTO public.project_services
        (project_id, name, unit_of_measure, quantity, direct_cost, target_price, source_co_id)
      VALUES
        (v_project_id, v_line.service_name,
         COALESCE(v_line.unit_of_measure, 'und'), v_line.quantity_change,
         0, COALESCE(v_line.unit_price, 0), NEW.id)
      RETURNING id INTO v_project_service_id;

      -- Vincular change_order_details → project_services
      UPDATE public.change_order_details
      SET project_service_id = v_project_service_id
      WHERE id = v_line.detail_id;
    END LOOP;
  END IF;
  RETURN NULL;
END;
$$;

-- Re-crear el trigger (misma definición, nueva función)
DROP TRIGGER IF EXISTS trg_log_quote_service_changes ON public.change_orders;
CREATE CONSTRAINT TRIGGER trg_log_quote_service_changes
  AFTER UPDATE ON public.change_orders
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (NEW.status = 'approved' AND OLD.status = 'submitted')
  EXECUTE FUNCTION public.log_quote_service_changes();
