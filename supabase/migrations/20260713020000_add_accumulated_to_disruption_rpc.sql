-- ============================================================
-- Migration: add accumulated actual hours to disruption RPC
-- Adds subqueries to get actual standby hours/waste from
-- daily report logs, so the UI can show Est vs Acum comparison.
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
-- RPC: get_disruption_accumulated_for_co
-- Returns per-detail accumulated actual values from daily reports
-- for a specific disruption CO. Used by CO detail page comparison.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_disruption_accumulated_for_co(
  p_co_id uuid
)
RETURNS jsonb LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_result jsonb := '[]'::jsonb;
  v_record record;
BEGIN
  FOR v_record IN
    SELECT
      cod.id as detail_id,
      cod.line_type,
      cod.service_name,
      cod.standby_hours,
      cod.standby_rate,
      cod.quantity_lost,
      cod.replacement_unit_cost,
      (SELECT COALESCE(SUM(rml.standby_hours), 0)
       FROM public.report_machinery_logs rml
       WHERE rml.change_order_detail_id = cod.id
         AND rml.report_id IN (
           SELECT dr.id FROM public.daily_reports dr
           WHERE dr.project_id = co.project_id AND dr.status NOT IN ('draft')
         )) AS accumulated_machinery_hours,
      (SELECT COALESCE(SUM(rll.standby_hours), 0)
       FROM public.report_labor_logs rll
       WHERE rll.change_order_detail_id = cod.id
         AND rll.report_id IN (
           SELECT dr.id FROM public.daily_reports dr
           WHERE dr.project_id = co.project_id AND dr.status NOT IN ('draft')
         )) AS accumulated_labor_hours,
      (SELECT COALESCE(SUM(rmu.quantity_lost), 0)
       FROM public.report_material_usage rmu
       WHERE rmu.change_order_detail_id = cod.id
         AND rmu.report_id IN (
           SELECT dr.id FROM public.daily_reports dr
           WHERE dr.project_id = co.project_id AND dr.status NOT IN ('draft')
         )) AS accumulated_material_qty
    FROM public.change_order_details cod
    JOIN public.change_orders co ON co.id = cod.change_order_id
    WHERE cod.change_order_id = p_co_id
      AND cod.line_type IN ('standby_labor','standby_machinery','standby_material')
  LOOP
    v_result := v_result || jsonb_build_object(
      'detail_id', v_record.detail_id,
      'line_type', v_record.line_type,
      'service_name', v_record.service_name,
      'standby_hours', v_record.standby_hours,
      'standby_rate', v_record.standby_rate,
      'quantity_lost', v_record.quantity_lost,
      'replacement_unit_cost', v_record.replacement_unit_cost,
      'accumulated_machinery_hours', v_record.accumulated_machinery_hours,
      'accumulated_labor_hours', v_record.accumulated_labor_hours,
      'accumulated_material_qty', v_record.accumulated_material_qty
    );
  END LOOP;

  RETURN v_result;
END;
$$;
