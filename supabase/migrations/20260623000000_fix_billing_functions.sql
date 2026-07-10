-- ============================================================
-- FIX: Replace billing RPC functions with corrected versions
-- ============================================================

-- 1. get_previous_billing_totals: include 'submitted' invoices
CREATE OR REPLACE FUNCTION public.get_previous_billing_totals(
  p_project_id uuid,
  p_exclude_invoice_id uuid DEFAULT NULL
)
RETURNS TABLE(quote_service_id uuid, total_previous numeric, total_previous_qty numeric)
LANGUAGE sql STABLE AS $$
  SELECT
    id.quote_service_id,
    COALESCE(SUM(id.this_period_amount), 0)::numeric as total_previous,
    COALESCE(SUM(id.this_period_qty), 0)::numeric as total_previous_qty
  FROM public.invoice_details id
  JOIN public.invoices i ON i.id = id.invoice_id
  WHERE i.project_id = p_project_id
    AND i.status IN ('submitted', 'paid')
    AND (p_exclude_invoice_id IS NULL OR i.id != p_exclude_invoice_id)
  GROUP BY id.quote_service_id;
$$;

-- 2. get_pay_application_data: all accumulated fixes
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
  v_line              record;
  v_prev_rec          record;
  v_accumulated_qty   numeric;
  v_earned            numeric;
  v_this_period_amt   numeric;
BEGIN
  -- Get project quote_id
  SELECT quote_id INTO v_quote_id FROM public.projects WHERE id = p_project_id;

  -- Calculate original contract sum (direct_cost already holds totalSaleV2)
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
    -- Get previous billing for this service
    SELECT total_previous, total_previous_qty
    INTO v_prev_rec
    FROM public.get_previous_billing_totals(p_project_id, p_exclude_inv_id)
    WHERE quote_service_id = v_line.quote_service_id;

    -- Get accumulated production from daily reports for this service
    -- NOTE: For volume-based units (cy, ft2, sqft, sf), multiply by machinery capacity_yards
    -- to convert from trips to actual yards (matching the monitoring dashboard logic).
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
      AND dr.status IN ('submitted', 'approved');

    -- Calculate this period amount based on % progress
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

  RETURN jsonb_build_object(
    'original_contract', v_original_contract,
    'approved_cos_total', v_approved_cos,
    'current_contract', v_original_contract + v_approved_cos,
    'previous_total', v_previous_total,
    'lines', v_lines
  );
END;
$$;
