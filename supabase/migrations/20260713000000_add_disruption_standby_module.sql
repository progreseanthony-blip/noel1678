-- ============================================================================
-- Migration: Add Disruption / Standby / Change Order Tracking Module
-- Soport para COs por interrupcion (Modalidad 2) y seguimiento de materiales
-- Dañados/Perdidos por eventos externos
-- ============================================================================

-- ============================================================
-- 1a. NUEVA COLUMNA en change_orders: co_type
--     scope_change = Modalidad 1 (cambio de alcance)
--     disruption   = Modalidad 2 (compensacion por interrupcion)
-- ============================================================
ALTER TABLE public.change_orders
  ADD COLUMN IF NOT EXISTS co_type text NOT NULL DEFAULT 'scope_change'
  CHECK (co_type IN ('scope_change', 'disruption'));

COMMENT ON COLUMN public.change_orders.co_type IS 'Tipo de CO: scope_change (cambio de alcance) o disruption (compensacion por interrupcion)';

-- ============================================================
-- 1b. EXTENSION: change_order_details
--    - Nuevos line_type para standby/disruption (reemplaza CHECK)
--    - total_change pasa de GENERATED a columna regular (calculada por trigger)
--    - Nuevas columnas para standby
-- ============================================================

-- i. Quitar GENERATED de total_change
ALTER TABLE public.change_order_details
  ALTER COLUMN total_change DROP EXPRESSION;

-- ii. Reemplazar CHECK constraint de line_type
ALTER TABLE public.change_order_details
  DROP CONSTRAINT IF EXISTS change_order_details_line_type_check;

ALTER TABLE public.change_order_details
  ADD CONSTRAINT change_order_details_line_type_check
  CHECK (line_type IN (
    'existing_service','new_service','deduction',
    'standby_labor','standby_machinery','standby_material'
  ));

-- iii. Nuevas columnas para soporte de standby / disruption
ALTER TABLE public.change_order_details
  ADD COLUMN IF NOT EXISTS standby_hours          numeric,
  ADD COLUMN IF NOT EXISTS standby_rate            numeric,
  ADD COLUMN IF NOT EXISTS material_id             uuid REFERENCES public.materials(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS quantity_lost           numeric,
  ADD COLUMN IF NOT EXISTS replacement_unit_cost   numeric,
  ADD COLUMN IF NOT EXISTS disruption_reason_id    uuid;

COMMENT ON COLUMN public.change_order_details.standby_hours         IS 'Horas en standby (para labor/machinery)';
COMMENT ON COLUMN public.change_order_details.standby_rate           IS 'Tasa horaria de compensacion por standby';
COMMENT ON COLUMN public.change_order_details.material_id            IS 'Material afectado (para standby_material)';
COMMENT ON COLUMN public.change_order_details.quantity_lost          IS 'Cantidad de material perdido/dañado';
COMMENT ON COLUMN public.change_order_details.replacement_unit_cost  IS 'Costo unitario de reemplazo del material';
COMMENT ON COLUMN public.change_order_details.disruption_reason_id   IS 'FK a disruption_reasons (causa de la interrupcion)';

-- iv. Trigger BEFORE: calcula total_change segun line_type
CREATE OR REPLACE FUNCTION public.compute_co_detail_total()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.total_change := CASE NEW.line_type
    WHEN 'standby_labor' THEN
      COALESCE(NEW.standby_hours, 0) * COALESCE(NEW.standby_rate, 0)
    WHEN 'standby_machinery' THEN
      COALESCE(NEW.standby_hours, 0) * COALESCE(NEW.standby_rate, 0)
    WHEN 'standby_material' THEN
      COALESCE(NEW.quantity_lost, 0) * COALESCE(NEW.replacement_unit_cost, COALESCE(NEW.unit_price, 0))
    ELSE
      COALESCE(NEW.quantity_change, 0) * COALESCE(NEW.unit_price, 0)
  END;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_compute_co_detail_total ON public.change_order_details;
CREATE TRIGGER trg_compute_co_detail_total
  BEFORE INSERT OR UPDATE ON public.change_order_details
  FOR EACH ROW
  EXECUTE FUNCTION public.compute_co_detail_total();


-- ============================================================
-- 2. CATALOGO: disruption_reasons
--    Causas de interrupcion que pueden afectar recursos
-- ============================================================
CREATE TABLE IF NOT EXISTS public.disruption_reasons (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text NOT NULL UNIQUE,
  description text NOT NULL,
  category    text NOT NULL DEFAULT 'general'
              CHECK (category IN ('permits','external','weather','owner','design','materials','general')),
  created_at  timestamptz DEFAULT now()
);

ALTER TABLE public.disruption_reasons ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_disruption_reasons ON public.disruption_reasons FOR SELECT USING (true);
CREATE POLICY insert_disruption_reasons ON public.disruption_reasons FOR INSERT WITH CHECK (true);

-- Seed data
INSERT INTO public.disruption_reasons (code, description, category) VALUES
  ('PENDING_PERMIT',    'Pending permit approval',                    'permits'),
  ('EXTERNAL_DEP',      'External dependency not completed',          'external'),
  ('OWNER_DELAY',       'Delay due to owner decision',                'owner'),
  ('WEATHER_RAIN',      'Rain preventing operation',                  'weather'),
  ('WEATHER_OTHER',     'Adverse weather condition',                  'weather'),
  ('DESIGN_CHANGE',     'Design change in progress',                  'design'),
  ('MATERIAL_DELAY',    'Material delivery delay',                    'materials'),
  ('MATERIAL_DAMAGE',   'Material damaged on site',                   'materials'),
  ('SITE_ACCESS',       'Site access restricted',                     'external'),
  ('UTILITY_LOCATE',    'Utility locate pending',                     'permits'),
  ('OTHER',             'Other (specify in notes)',                    'general')
ON CONFLICT (code) DO NOTHING;

-- FK desde change_order_details hacia disruption_reasons
ALTER TABLE public.change_order_details
  ADD CONSTRAINT fk_co_detail_disruption_reason
  FOREIGN KEY (disruption_reason_id) REFERENCES public.disruption_reasons(id)
  ON DELETE SET NULL;

-- ============================================================
-- 3. TABLA: change_order_disruptions
--    Periodo durante el cual una interrupcion afecto el proyecto
-- ============================================================
CREATE TABLE IF NOT EXISTS public.change_order_disruptions (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  change_order_id   uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  disruption_type   text NOT NULL CHECK (disruption_type IN (
    'PENDING_PERMIT','EXTERNAL_DEP','OWNER_DELAY',
    'WEATHER_RAIN','WEATHER_OTHER','DESIGN_CHANGE',
    'MATERIAL_DELAY','MATERIAL_DAMAGE','SITE_ACCESS',
    'UTILITY_LOCATE','OTHER'
  )),
  start_date        date NOT NULL,
  end_date          date,
  description       text,
  created_at        timestamptz DEFAULT now()
);

ALTER TABLE public.change_order_disruptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_cod ON public.change_order_disruptions FOR SELECT USING (true);
CREATE POLICY insert_cod ON public.change_order_disruptions FOR INSERT WITH CHECK (true);
CREATE POLICY update_cod ON public.change_order_disruptions FOR UPDATE USING (true);
CREATE POLICY delete_cod ON public.change_order_disruptions FOR DELETE USING (true);

-- ============================================================
-- 4. TABLA: quote_service_change_log
--    Historial de cambios en metas de servicios por COs aprobados
--    Permite a EVM / dashboards usar la meta ajustada
-- ============================================================
CREATE TABLE IF NOT EXISTS public.quote_service_change_log (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quote_service_id  uuid NOT NULL REFERENCES public.quote_services(id) ON DELETE CASCADE,
  change_order_id   uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  previous_quantity numeric NOT NULL,
  new_quantity      numeric NOT NULL,
  delta_quantity    numeric NOT NULL,
  created_at        timestamptz DEFAULT now()
);

ALTER TABLE public.quote_service_change_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY select_qscl ON public.quote_service_change_log FOR SELECT USING (true);
CREATE POLICY insert_qscl ON public.quote_service_change_log FOR INSERT WITH CHECK (true);

-- Trigger: al aprobar un CO con lineas de tipo existing_service o new_service,
-- registrar el cambio en quote_service_change_log
CREATE OR REPLACE FUNCTION public.log_quote_service_changes()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'approved' AND OLD.status = 'submitted' THEN
    INSERT INTO public.quote_service_change_log
      (quote_service_id, change_order_id, previous_quantity, new_quantity, delta_quantity)
    SELECT
      cod.quote_service_id,
      NEW.id,
      COALESCE(qs.quantity, 0),
      COALESCE(qs.quantity, 0) + cod.quantity_change,
      cod.quantity_change
    FROM public.change_order_details cod
    JOIN public.quote_services qs ON qs.id = cod.quote_service_id
    WHERE cod.change_order_id = NEW.id
      AND cod.line_type IN ('existing_service', 'new_service')
      AND cod.quote_service_id IS NOT NULL
      AND cod.quantity_change != 0;

    -- Actualizar la cantidad en quote_services directamente
    UPDATE public.quote_services qs
    SET quantity = qs.quantity + cod.quantity_change
    FROM public.change_order_details cod
    WHERE cod.change_order_id = NEW.id
      AND cod.quote_service_id = qs.id
      AND cod.line_type IN ('existing_service', 'new_service')
      AND cod.quantity_change != 0;
  END IF;
  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_log_quote_service_changes ON public.change_orders;
CREATE CONSTRAINT TRIGGER trg_log_quote_service_changes
  AFTER UPDATE ON public.change_orders
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW
  WHEN (NEW.status = 'approved' AND OLD.status = 'submitted')
  EXECUTE FUNCTION public.log_quote_service_changes();


-- ============================================================
-- 5. EXTENSION: report_machinery_logs
--    - is_standby: indica si la maquina estuvo en standby
--    - standby_hours: horas en standby (puede ser < total_hours)
--    - change_order_detail_id: vincula al CO de disrupcion
-- ============================================================
ALTER TABLE public.report_machinery_logs
  ADD COLUMN IF NOT EXISTS is_standby             boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS standby_hours           numeric,
  ADD COLUMN IF NOT EXISTS change_order_detail_id  uuid REFERENCES public.change_order_details(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.report_machinery_logs.is_standby              IS 'True = maquina en standby por disrupcion';
COMMENT ON COLUMN public.report_machinery_logs.standby_hours           IS 'Horas en standby (puede ser parcial)';
COMMENT ON COLUMN public.report_machinery_logs.change_order_detail_id  IS 'Vinculo al detalle del CO de disrupcion';

-- ============================================================
-- 6. EXTENSION: report_labor_logs
--    Misma logica que maquinaria
-- ============================================================
ALTER TABLE public.report_labor_logs
  ADD COLUMN IF NOT EXISTS is_standby             boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS standby_hours           numeric,
  ADD COLUMN IF NOT EXISTS change_order_detail_id  uuid REFERENCES public.change_order_details(id) ON DELETE SET NULL;

COMMENT ON COLUMN public.report_labor_logs.is_standby              IS 'True = trabajador en standby por disrupcion';
COMMENT ON COLUMN public.report_labor_logs.standby_hours           IS 'Horas en standby (puede ser parcial)';
COMMENT ON COLUMN public.report_labor_logs.change_order_detail_id  IS 'Vinculo al detalle del CO de disrupcion';

-- ============================================================
-- 7. EXTENSION: report_material_usage
--    - is_waste: material dañado/perdido (no instalado)
--    - waste_reason: causa del desperdicio
--    - change_order_detail_id: vinculo al CO de disrupcion
--    - replacement_cost: costo real de reposicion
-- ============================================================
ALTER TABLE public.report_material_usage
  ADD COLUMN IF NOT EXISTS is_waste               boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS waste_reason            text,
  ADD COLUMN IF NOT EXISTS change_order_detail_id  uuid REFERENCES public.change_order_details(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS replacement_cost        numeric;

COMMENT ON COLUMN public.report_material_usage.is_waste               IS 'True = material desperdiciado/dañado (no instalado)';
COMMENT ON COLUMN public.report_material_usage.waste_reason            IS 'Causa del desperdicio (ej: lluvia, manipulacion)';
COMMENT ON COLUMN public.report_material_usage.change_order_detail_id  IS 'Vinculo al detalle del CO de disrupcion';
COMMENT ON COLUMN public.report_material_usage.replacement_cost        IS 'Costo real de reposicion del material';

-- ============================================================
-- 8. ACTUALIZAR: Trigger recalc_change_order_total
--    El trigger existente suma total_change; ahora total_change
--    es calculado por trg_compute_co_detail_total BEFORE trigger
--    Por tanto el AFTER trigger existente funciona sin cambios.
-- ============================================================

-- ============================================================
-- 9. RPC: get_disruption_cos_for_project
--    Retorna COs de disrupcion aprobados activos para un proyecto
--    en un rango de fechas. Usado por daily reports.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_disruption_cos_for_project(
  p_project_id  uuid,
  p_date        date DEFAULT CURRENT_DATE
)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_result jsonb := '[]'::jsonb;
  v_co_record record;
BEGIN
  FOR v_co_record IN
    SELECT
      co.id,
      co.co_number,
      co.title,
      co.description,
      co.adjustment_amount,
      co.executed_date,
      cod.id as detail_id,
      cod.line_type,
      cod.service_name,
      cod.standby_hours,
      cod.standby_rate,
      cod.quantity_lost,
      cod.replacement_unit_cost,
      cod.total_change,
      cod.unit_of_measure,
      dr.code as disruption_reason_code,
      dr.description as disruption_reason_desc,
      m.description as material_name
    FROM public.change_orders co
    JOIN public.change_order_details cod ON cod.change_order_id = co.id
    LEFT JOIN public.disruption_reasons dr ON dr.id = cod.disruption_reason_id
    LEFT JOIN public.materials m ON m.id = cod.material_id
    WHERE co.project_id = p_project_id
      AND co.status = 'approved'
      AND cod.line_type IN ('standby_labor','standby_machinery','standby_material')
      AND (co.executed_date IS NULL OR co.executed_date <= p_date)
  LOOP
    v_result := v_result || jsonb_build_object(
      'co_id', v_co_record.id,
      'co_number', v_co_record.co_number,
      'co_title', v_co_record.title,
      'detail_id', v_co_record.detail_id,
      'line_type', v_co_record.line_type,
      'service_name', v_co_record.service_name,
      'standby_hours', v_co_record.standby_hours,
      'standby_rate', v_co_record.standby_rate,
      'quantity_lost', v_co_record.quantity_lost,
      'replacement_unit_cost', v_co_record.replacement_unit_cost,
      'total_change', v_co_record.total_change,
      'unit_of_measure', v_co_record.unit_of_measure,
      'disruption_reason_code', v_co_record.disruption_reason_code,
      'disruption_reason_desc', v_co_record.disruption_reason_desc,
      'material_name', v_co_record.material_name
    );
  END LOOP;

  RETURN v_result;
END;
$$;

-- ============================================================
-- 10. ACTUALIZAR: RPC get_pay_application_data
--     Agregar acumulado de horas standby y material desperdiciado
--     como lineas adicionales en el JSON de retorno
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_pay_application_data(
  p_project_id    uuid,
  p_period_start  date,
  p_period_end    date,
  p_exclude_inv_id uuid DEFAULT NULL
)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_quote_id          uuid;
  v_original_contract numeric := 0;
  v_approved_cos      numeric := 0;
  v_previous_total    numeric := 0;
  v_lines             jsonb := '[]'::jsonb;
  v_standby_lines     jsonb := '[]'::jsonb;
  v_line              record;
  v_prev_rec          record;
  v_accumulated_qty   numeric;
  v_earned            numeric;
  v_this_period_amt   numeric;
  v_standby_rec       record;
BEGIN
  -- Get project quote_id
  SELECT quote_id INTO v_quote_id FROM public.projects WHERE id = p_project_id;

  -- Calculate original contract sum
  SELECT COALESCE(SUM(COALESCE(qs.direct_cost, 0)), 0) INTO v_original_contract
  FROM public.quote_services qs
  WHERE qs.quote_id = v_quote_id;

  -- Sum approved change orders
  SELECT COALESCE(SUM(adjustment_amount), 0) INTO v_approved_cos
  FROM public.change_orders
  WHERE project_id = p_project_id AND status = 'approved';

  -- Sum previous billings (paid invoices)
  SELECT COALESCE(SUM(total_this_period), 0) INTO v_previous_total
  FROM public.invoices
  WHERE project_id = p_project_id AND status = 'paid';

  -- Build invoice lines from quote_services
  FOR v_line IN
    SELECT
      qs.id as quote_service_id,
      qs.name as service_name,
      qs.unit_of_measure,
      COALESCE(qs.direct_cost, 0) as scheduled_value,
      qs.quantity as contract_quantity
    FROM public.quote_services qs
    WHERE qs.quote_id = v_quote_id
    ORDER BY qs.created_at
  LOOP
    SELECT total_previous, total_previous_qty
    INTO v_prev_rec
    FROM public.get_previous_billing_totals(p_project_id, p_exclude_inv_id)
    WHERE quote_service_id = v_line.quote_service_id;

    SELECT COALESCE(SUM(rml.production_value), 0)
    INTO v_accumulated_qty
    FROM public.report_machinery_logs rml
    JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
    JOIN public.project_machinery pm ON pm.id = rml.project_machinery_id
    WHERE pm.quote_service_id = v_line.quote_service_id
      AND dr.project_id = p_project_id
      AND dr.report_date <= p_period_end
      AND dr.status IN ('submitted', 'approved')
      AND rml.is_standby = false;

    v_this_period_amt := 0;
    IF v_line.contract_quantity > 0 AND v_line.scheduled_value > 0 THEN
      v_earned := (v_accumulated_qty / v_line.contract_quantity) * v_line.scheduled_value;
      v_this_period_amt := GREATEST(0, v_earned - COALESCE(v_prev_rec.total_previous, 0));
    END IF;

    v_lines := v_lines || jsonb_build_object(
      'quote_service_id', v_line.quote_service_id,
      'service_name', v_line.service_name,
      'unit_of_measure', v_line.unit_of_measure,
      'line_type', 'service',
      'scheduled_value', v_line.scheduled_value,
      'previous_completed', COALESCE(v_prev_rec.total_previous, 0),
      'previous_qty', COALESCE(v_prev_rec.total_previous_qty, 0),
      'this_period_qty', v_accumulated_qty,
      'this_period_amount', v_this_period_amt,
      'equipment_present', 0
    );
  END LOOP;

  -- Accumulated standby hours from machinery logs (by CO detail)
  FOR v_standby_rec IN
    SELECT
      cod.id as co_detail_id,
      cod.service_name,
      cod.unit_of_measure,
      COALESCE(cod.standby_hours, 0) as estimated_hours,
      COALESCE(cod.standby_rate, 0) as standby_rate,
      cod.line_type,
      co.co_number,
      co.id as co_id,
      SUM(COALESCE(rml.standby_hours, 0)) as actual_hours,
      SUM(COALESCE(rml.standby_hours, 0) * COALESCE(cod.standby_rate, 0)) as calculated_amount
    FROM public.change_order_details cod
    JOIN public.change_orders co ON co.id = cod.change_order_id
    LEFT JOIN public.report_machinery_logs rml
      ON rml.change_order_detail_id = cod.id
      AND rml.is_standby = true
    LEFT JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
      AND dr.project_id = p_project_id
      AND dr.report_date BETWEEN p_period_start AND p_period_end
      AND dr.status IN ('submitted', 'approved')
    WHERE co.project_id = p_project_id
      AND co.status = 'approved'
      AND cod.line_type = 'standby_machinery'
    GROUP BY cod.id, cod.service_name, cod.unit_of_measure, cod.standby_hours,
             cod.standby_rate, cod.line_type, co.co_number, co.id
    HAVING SUM(COALESCE(rml.standby_hours, 0)) > 0
  LOOP
    v_standby_lines := v_standby_lines || jsonb_build_object(
      'co_id', v_standby_rec.co_id,
      'co_detail_id', v_standby_rec.co_detail_id,
      'co_number', v_standby_rec.co_number,
      'service_name', 'Standby: ' || v_standby_rec.service_name || ' (' || v_standby_rec.co_number || ')',
      'unit_of_measure', 'hrs',
      'line_type', 'standby_machinery',
      'estimated_hours', v_standby_rec.estimated_hours,
      'actual_hours', v_standby_rec.actual_hours,
      'standby_rate', v_standby_rec.standby_rate,
      'this_period_amount', v_standby_rec.calculated_amount,
      'scheduled_value', v_standby_rec.estimated_hours * v_standby_rec.standby_rate
    );
  END LOOP;

  -- Accumulated standby hours from labor logs (by CO detail)
  FOR v_standby_rec IN
    SELECT
      cod.id as co_detail_id,
      cod.service_name,
      cod.unit_of_measure,
      COALESCE(cod.standby_hours, 0) as estimated_hours,
      COALESCE(cod.standby_rate, 0) as standby_rate,
      cod.line_type,
      co.co_number,
      co.id as co_id,
      SUM(COALESCE(rll.standby_hours, 0)) as actual_hours,
      SUM(COALESCE(rll.standby_hours, 0) * COALESCE(cod.standby_rate, 0)) as calculated_amount
    FROM public.change_order_details cod
    JOIN public.change_orders co ON co.id = cod.change_order_id
    LEFT JOIN public.report_labor_logs rll
      ON rll.change_order_detail_id = cod.id
      AND rll.is_standby = true
    LEFT JOIN public.daily_reports dr ON dr.id = rll.daily_report_id
      AND dr.project_id = p_project_id
      AND dr.report_date BETWEEN p_period_start AND p_period_end
      AND dr.status IN ('submitted', 'approved')
    WHERE co.project_id = p_project_id
      AND co.status = 'approved'
      AND cod.line_type = 'standby_labor'
    GROUP BY cod.id, cod.service_name, cod.unit_of_measure, cod.standby_hours,
             cod.standby_rate, cod.line_type, co.co_number, co.id
    HAVING SUM(COALESCE(rll.standby_hours, 0)) > 0
  LOOP
    v_standby_lines := v_standby_lines || jsonb_build_object(
      'co_id', v_standby_rec.co_id,
      'co_detail_id', v_standby_rec.co_detail_id,
      'co_number', v_standby_rec.co_number,
      'service_name', 'Standby Labor: ' || v_standby_rec.service_name || ' (' || v_standby_rec.co_number || ')',
      'unit_of_measure', 'hrs',
      'line_type', 'standby_labor',
      'estimated_hours', v_standby_rec.estimated_hours,
      'actual_hours', v_standby_rec.actual_hours,
      'standby_rate', v_standby_rec.standby_rate,
      'this_period_amount', v_standby_rec.calculated_amount,
      'scheduled_value', v_standby_rec.estimated_hours * v_standby_rec.standby_rate
    );
  END LOOP;

  -- Accumulated material waste (by CO detail)
  FOR v_standby_rec IN
    SELECT
      cod.id as co_detail_id,
      cod.service_name,
      cod.unit_of_measure,
      COALESCE(cod.quantity_lost, 0) as estimated_lost,
      COALESCE(cod.replacement_unit_cost, 0) as replacement_cost,
      cod.line_type,
      co.co_number,
      co.id as co_id,
      SUM(COALESCE(rmu.quantity_used, 0)) as actual_lost,
      SUM(COALESCE(rmu.replacement_cost, 0)) as actual_replacement_cost
    FROM public.change_order_details cod
    JOIN public.change_orders co ON co.id = cod.change_order_id
    LEFT JOIN public.report_material_usage rmu
      ON rmu.change_order_detail_id = cod.id
      AND rmu.is_waste = true
    LEFT JOIN public.daily_reports dr ON dr.id = rmu.daily_report_id
      AND dr.project_id = p_project_id
      AND dr.report_date BETWEEN p_period_start AND p_period_end
      AND dr.status IN ('submitted', 'approved')
    WHERE co.project_id = p_project_id
      AND co.status = 'approved'
      AND cod.line_type = 'standby_material'
    GROUP BY cod.id, cod.service_name, cod.unit_of_measure, cod.quantity_lost,
             cod.replacement_unit_cost, cod.line_type, co.co_number, co.id
    HAVING SUM(COALESCE(rmu.quantity_used, 0)) > 0
  LOOP
    v_standby_lines := v_standby_lines || jsonb_build_object(
      'co_id', v_standby_rec.co_id,
      'co_detail_id', v_standby_rec.co_detail_id,
      'co_number', v_standby_rec.co_number,
      'service_name', 'Material Lost: ' || v_standby_rec.service_name || ' (' || v_standby_rec.co_number || ')',
      'unit_of_measure', v_standby_rec.unit_of_measure,
      'line_type', 'standby_material',
      'estimated_lost', v_standby_rec.estimated_lost,
      'actual_lost', v_standby_rec.actual_lost,
      'replacement_cost', v_standby_rec.replacement_cost,
      'actual_replacement_cost', v_standby_rec.actual_replacement_cost,
      'this_period_amount', COALESCE(v_standby_rec.actual_replacement_cost, 0),
      'scheduled_value', v_standby_rec.estimated_lost * v_standby_rec.replacement_cost
    );
  END LOOP;

  RETURN jsonb_build_object(
    'original_contract', v_original_contract,
    'approved_cos_total', v_approved_cos,
    'current_contract', v_original_contract + v_approved_cos,
    'previous_total', v_previous_total,
    'lines', v_lines,
    'standby_lines', v_standby_lines
  );
END;
$$;

-- ============================================================
-- 11. NOTIFY PostgREST
-- ============================================================
NOTIFY pgrst, 'reload schema';
