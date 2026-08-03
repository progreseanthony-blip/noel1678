-- Migration: Include owned machinery in billing deductions list
-- Previously only rented machinery was shown; now includes both rented and owned

CREATE OR REPLACE FUNCTION public.get_service_machinery_for_billing(p_project_id uuid)
RETURNS TABLE(
  quote_service_id uuid,
  quote_service_name text,
  machinery_inspection_id uuid,
  machine_name text,
  internal_code text,
  brand_model text,
  monthly_rent_cost numeric,
  daily_rental_rate numeric
) LANGUAGE sql STABLE AS $$
  SELECT
    COALESCE(pm.quote_service_id, qsm.quote_service_id) as quote_service_id,
    qs.name as quote_service_name,
    mi.id as machinery_inspection_id,
    COALESCE(mi.internal_code, mi.internal_id, mi.brand_model, pm.machinery_name, 'Machine') as machine_name,
    mi.internal_code,
    mi.brand_model,
    COALESCE(qsm.monthly_rent_cost, (pm.calculation_metadata->>'monthly_rent')::numeric, 0) as monthly_rent_cost,
    ROUND((COALESCE(qsm.monthly_rent_cost, (pm.calculation_metadata->>'monthly_rent')::numeric, 0) / 30.0)::numeric, 2) as daily_rental_rate
  FROM public.machinery_inspections mi
  JOIN public.project_machinery pm ON pm.id = mi.project_machinery_id
  LEFT JOIN public.quote_service_machineries qsm ON qsm.id = pm.quote_service_machinery_id
  LEFT JOIN public.quote_services qs ON qs.id = COALESCE(pm.quote_service_id, qsm.quote_service_id)
  WHERE pm.project_id = p_project_id
    AND mi.returned_at IS NULL
  ORDER BY qs.name, mi.internal_code, mi.brand_model;
$$;
