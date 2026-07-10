-- Migration: Add Machinery Rental Deductions for Billing
-- Allows deducting machinery rental costs from service line items in invoices

-- ============================================================
-- 1. INVOICE MACHINERY DEDUCTIONS TABLE
-- ============================================================
CREATE TABLE public.invoice_machinery_deductions (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id                  uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  quote_service_id            uuid NOT NULL REFERENCES public.quote_services(id) ON DELETE CASCADE,
  quote_service_machinery_id  uuid REFERENCES public.quote_service_machineries(id) ON DELETE SET NULL,
  machine_name                text NOT NULL,
  monthly_rent_cost           numeric NOT NULL DEFAULT 0,
  daily_rental_rate           numeric NOT NULL DEFAULT 0,
  days_in_period              numeric NOT NULL DEFAULT 0,
  deduction_amount            numeric NOT NULL DEFAULT 0,
  quantity                    numeric NOT NULL DEFAULT 1,
  selected                    boolean NOT NULL DEFAULT true,
  created_at                  timestamptz DEFAULT now(),
  UNIQUE(invoice_id, quote_service_id, quote_service_machinery_id)
);

-- ============================================================
-- 2. RPC: Get machinery for billing (by project)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_service_machinery_for_billing(p_project_id uuid)
RETURNS TABLE(
  quote_service_id uuid,
  quote_service_name text,
  quote_service_machinery_id uuid,
  machine_name text,
  monthly_rent_cost numeric,
  quantity numeric,
  daily_rental_rate numeric
) LANGUAGE sql STABLE AS $$
  SELECT
    qsm.quote_service_id,
    qs.name as quote_service_name,
    qsm.id as quote_service_machinery_id,
    qsm.machine_name,
    qsm.monthly_rent_cost,
    qsm.quantity,
    ROUND((qsm.monthly_rent_cost / 30.0)::numeric, 2) as daily_rental_rate
  FROM public.quote_service_machineries qsm
  JOIN public.quote_services qs ON qs.id = qsm.quote_service_id
  JOIN public.projects p ON p.quote_id = qs.quote_id
  WHERE p.id = p_project_id
    AND qsm.monthly_rent_cost > 0
  ORDER BY qs.name, qsm.machine_name;
$$;

-- ============================================================
-- 3. ROW LEVEL SECURITY
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
