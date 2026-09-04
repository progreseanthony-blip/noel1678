-- ============================================================
-- Migration: Trigger de operador consciente de COs (single-writer safe)
-- Contexto: handle_machinery_operator_assignment() creaba el operador
-- 'Operador de <maquina>' copiando solo quote_service_id. Para maquinaria
-- de change orders (quote_service_id NULL, project_service_id SET) el
-- operador quedaba sin vinculos y con change_type='planning', visible en
-- Timeline/Resource Planning como "General / Unassigned".
--
-- Cambios:
-- 1. Propaga NEW.project_service_id, NEW.source_co_id y NEW.change_type
--    al operador, para que caiga bajo el servicio correcto.
-- 2. Guarda anti-duplicado (doble ejecucion de la aprobacion): si ya
--    existe un labor con ese linked_machinery_id, no inserta.
-- 3. Si la maquinaria viene de un CO cuyos planes ya incluyen labor para
--    ese mismo servicio, no inserta: BillingService.applyBaselineImpact
--    ya crea esos operadores desde los planes (evita doble operador).
--    Si el CO no trae planes de labor, crea el operador como respaldo.
-- 4. Mantiene el comportamiento original para maquinaria planificada
--    de quotes (quote_service_id, change_type='planning').
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_machinery_operator_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_role_name         TEXT;
    v_existing          uuid;
    v_service_name      TEXT;
    v_has_planned_labor boolean;
BEGIN
    -- We only auto-generate for unplanned machinery added during execution/re-planning phase.
    -- (Planned machinery from quotes already has its labor inserted via
    --  ProjectService.convertQuoteToProject)
    IF NEW.is_unplanned = true THEN
        -- Anti-duplicado por reintentos de aprobacion.
        SELECT id INTO v_existing
        FROM public.project_labor
        WHERE linked_machinery_id = NEW.id
        LIMIT 1;

        IF v_existing IS NOT NULL THEN
            RETURN NEW;
        END IF;

        -- Si el CO ya planifico labor para este mismo servicio, la app crea
        -- esos operadores; el trigger no debe sumar uno extra.
        v_has_planned_labor := false;
        IF NEW.source_co_id IS NOT NULL AND NEW.project_service_id IS NOT NULL THEN
            SELECT name INTO v_service_name
            FROM public.project_services
            WHERE id = NEW.project_service_id;

            IF v_service_name IS NOT NULL THEN
                SELECT true INTO v_has_planned_labor
                FROM public.change_order_details cod
                JOIN public.change_order_resource_plans p
                  ON p.change_order_detail_id = cod.id
                WHERE cod.change_order_id = NEW.source_co_id
                  AND cod.service_name = v_service_name
                  AND p.resource_type = 'labor'
                LIMIT 1;
            END IF;
        END IF;

        IF COALESCE(v_has_planned_labor, false) = false THEN
            v_role_name := 'Operador de ' || NEW.machinery_name;

            INSERT INTO public.project_labor (
                project_id,
                quote_service_id,
                project_service_id,
                source_co_id,
                change_type,
                role_name,
                expected_employees,
                is_unplanned,
                linked_machinery_id
            ) VALUES (
                NEW.project_id,
                NEW.quote_service_id,
                NEW.project_service_id,
                NEW.source_co_id,
                NEW.change_type,
                v_role_name,
                NEW.expected_quantity, -- Match the number of operators to the number of machines
                true,
                NEW.id
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
