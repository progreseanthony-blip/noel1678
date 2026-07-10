-- Migration: Fix machinery deductions — use individual inspections, not quote groups
-- Only show machines where ownership_type = 'rented' and not returned

-- ============================================================
-- 1. DROP OLD TABLE AND RECREATE WITH CORRECT SCHEMA
-- ============================================================
DROP TABLE IF EXISTS public.invoice_machinery_deductions;

CREATE TABLE public.invoice_machinery_deductions (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id                  uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  quote_service_id            uuid NOT NULL REFERENCES public.quote_services(id) ON DELETE CASCADE,
  machinery_inspection_id     uuid NOT NULL REFERENCES public.machinery_inspections(id) ON DELETE CASCADE,
  machine_name                text NOT NULL,
  internal_code               text,
  brand_model                 text,
  monthly_rent_cost           numeric NOT NULL DEFAULT 0,
  daily_rental_rate           numeric NOT NULL DEFAULT 0,
  days_in_period              numeric NOT NULL DEFAULT 0,
  deduction_amount            numeric NOT NULL DEFAULT 0,
  selected                    boolean NOT NULL DEFAULT true,
  created_at                  timestamptz DEFAULT now(),
  UNIQUE(invoice_id, quote_service_id, machinery_inspection_id)
);

-- ============================================================
-- 2. DROP OLD FUNCTION AND RECREATE
-- ============================================================
DROP FUNCTION IF EXISTS public.get_service_machinery_for_billing(uuid);

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
    AND mi.ownership_type = 'rented'
    AND mi.returned_at IS NULL
  ORDER BY qs.name, mi.internal_code, mi.brand_model;
$$;

-- ============================================================
-- 3. ROW LEVEL SECURITY (re-create after drop)
-- ============================================================
ALTER TABLE public.invoice_machinery_deductions ENABLE ROW LEVEL SECURITY;

CREATE POLICY select_invoice_machinery_deductions ON public.invoice_machinery_deductions
  FOR SELECT USING (true);

CREATE POLICY insert_invoice_machinery_deductions ON public.invoice_machinery_deductions
  FOR INSERT WITH CHECK (true);

CREATE POLICY update_invoice_machinery_deductions ON public.invoice_machinery_deductions
  FOR UPDATE USING (true);

CREATE POLICY delete_invoice_machinery_deductions ON public.invoice_machinery_deductions
  FOR DELETE USING (true);

NOTIFY pgrst, 'reload schema';
