-- Restore capacity_yards multiplier in get_pay_application_data
-- The 20260713 migration added standby support but removed the volume-unit capacity multiplier
-- that was introduced in 20260623. This restores it while keeping standby support intact.
-- For CY / FT2 / SQFT / SF services: production_value (trips) × machinery.capacity_yards

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

    SELECT COALESCE(SUM(
      CASE WHEN LOWER(v_line.unit_of_measure) IN ('cy', 'ft2', 'sqft', 'sf')
           THEN rml.production_value * COALESCE(m.capacity_yards, 1)
           ELSE rml.production_value
      END
    ), 0)
    INTO v_accumulated_qty
    FROM public.report_machinery_logs rml
    JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
    JOIN public.project_machinery pm ON pm.id = rml.project_machinery_id
    LEFT JOIN public.machinery m ON m.id = pm.machinery_id
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
