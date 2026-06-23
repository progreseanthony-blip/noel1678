-- Migration: Create Billing & Change Orders Module
-- Pay Application (G702/G703) + Change Orders (AIA G701)

-- ============================================================
-- 1. INVOICE SEQUENCES (auto-incremental global numbering)
-- ============================================================
CREATE TABLE public.invoice_sequences (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  prefix      text NOT NULL,
  year        integer NOT NULL DEFAULT extract(year from now()),
  last_number integer NOT NULL DEFAULT 0,
  UNIQUE(prefix, year)
);

CREATE OR REPLACE FUNCTION public.next_invoice_number(p_prefix text)
RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  v_year integer := extract(year from now());
  v_next integer;
BEGIN
  INSERT INTO public.invoice_sequences (prefix, year, last_number)
  VALUES (p_prefix, v_year, 1)
  ON CONFLICT (prefix, year) DO UPDATE SET last_number = invoice_sequences.last_number + 1
  RETURNING last_number INTO v_next;
  RETURN p_prefix || '-' || v_year::text || '-' || LPAD(v_next::text, 4, '0');
END;
$$;

-- ============================================================
-- 2. CHANGE ORDERS
-- ============================================================
CREATE TABLE public.change_orders (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id        uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  co_number         text NOT NULL UNIQUE DEFAULT public.next_invoice_number('CO'),
  title             text NOT NULL,
  status            text NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft','submitted','approved','rejected')),
  description       text,
  executed_date     date,
  original_contract_amount  numeric NOT NULL DEFAULT 0,
  adjustment_amount         numeric NOT NULL DEFAULT 0,
  new_contract_amount       numeric GENERATED ALWAYS AS (original_contract_amount + adjustment_amount) STORED,
  schedule_days_change      integer NOT NULL DEFAULT 0,
  created_by        uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_by       uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  approved_at       timestamptz,
  rejected_at       timestamptz,
  rejection_reason  text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);

CREATE TABLE public.change_order_details (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  change_order_id   uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  line_type         text NOT NULL DEFAULT 'existing_service'
                    CHECK (line_type IN ('existing_service','new_service','deduction')),
  quote_service_id  uuid REFERENCES public.quote_services(id) ON DELETE SET NULL,
  catalog_service_id uuid REFERENCES public.services(id) ON DELETE SET NULL,
  service_name      text NOT NULL,
  unit_of_measure   text NOT NULL,
  quantity_change   numeric NOT NULL,
  unit_price        numeric NOT NULL,
  total_change      numeric GENERATED ALWAYS AS (quantity_change * unit_price) STORED,
  notes             text,
  created_at        timestamptz DEFAULT now()
);

-- Trigger: recalculate adjustment_amount on change_orders when details change
CREATE OR REPLACE FUNCTION public.recalc_change_order_total()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  UPDATE public.change_orders
  SET adjustment_amount = (
    SELECT COALESCE(SUM(total_change), 0)
    FROM public.change_order_details
    WHERE change_order_id = COALESCE(NEW.change_order_id, OLD.change_order_id)
  )
  WHERE id = COALESCE(NEW.change_order_id, OLD.change_order_id);
  RETURN NULL;
END;
$$;

CREATE CONSTRAINT TRIGGER trg_recalc_co_total
AFTER INSERT OR UPDATE OR DELETE ON public.change_order_details
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION public.recalc_change_order_total();

-- Trigger: auto update updated_at
CREATE TRIGGER trg_change_orders_updated_at
  BEFORE UPDATE ON public.change_orders
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 3. INVOICES (Pay Application Header / G702)
-- ============================================================
CREATE TABLE public.invoices (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id            uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  invoice_number        text NOT NULL UNIQUE DEFAULT public.next_invoice_number('INV'),
  application_date      date NOT NULL DEFAULT CURRENT_DATE,
  period_start          date NOT NULL,
  period_end            date NOT NULL,
  status                text NOT NULL DEFAULT 'draft'
                        CHECK (status IN ('draft','submitted','paid','cancelled')),
  retainage_rate        numeric NOT NULL DEFAULT 5.0,
  original_contract     numeric NOT NULL DEFAULT 0,
  approved_cos_total    numeric NOT NULL DEFAULT 0,
  current_contract      numeric GENERATED ALWAYS AS (original_contract + approved_cos_total) STORED,
  total_previous_billed numeric NOT NULL DEFAULT 0,
  total_this_period     numeric NOT NULL DEFAULT 0,
  total_completed       numeric GENERATED ALWAYS AS (total_previous_billed + total_this_period) STORED,
  total_retainage       numeric NOT NULL DEFAULT 0,
  total_due             numeric GENERATED ALWAYS AS (total_this_period - total_retainage) STORED,
  balance_to_finish     numeric GENERATED ALWAYS AS ((original_contract + approved_cos_total) - (total_previous_billed + total_this_period)) STORED,
  notes                 text,
  created_by            uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at            timestamptz DEFAULT now(),
  updated_at            timestamptz DEFAULT now(),
  CHECK (period_end >= period_start)
);

CREATE TRIGGER trg_invoices_updated_at
  BEFORE UPDATE ON public.invoices
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- ============================================================
-- 4. INVOICE DETAILS (Pay Application Line Items / G703)
-- ============================================================
CREATE TABLE public.invoice_details (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id            uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  quote_service_id      uuid REFERENCES public.quote_services(id) ON DELETE SET NULL,
  change_order_id       uuid REFERENCES public.change_orders(id) ON DELETE SET NULL,
  line_type             text NOT NULL DEFAULT 'service'
                        CHECK (line_type IN ('service','equipment','co_adjustment')),
  sort_order            integer NOT NULL DEFAULT 0,
  service_name          text NOT NULL,
  unit_of_measure       text NOT NULL,
  scheduled_value       numeric NOT NULL,
  previous_completed    numeric NOT NULL DEFAULT 0,
  this_period_qty       numeric NOT NULL DEFAULT 0,
  this_period_amount    numeric NOT NULL DEFAULT 0,
  equipment_present     numeric NOT NULL DEFAULT 0,
  retainage_rate        numeric NOT NULL DEFAULT 5.0,
  notes                 text,
  created_at            timestamptz DEFAULT now()
);

-- ============================================================
-- 5. INVOICE ↔ CHANGE ORDER LINK
-- ============================================================
CREATE TABLE public.invoice_change_order_links (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id      uuid NOT NULL REFERENCES public.invoices(id) ON DELETE CASCADE,
  change_order_id uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  UNIQUE(invoice_id, change_order_id)
);

-- ============================================================
-- 6. HELPER FUNCTION: Get previous billing totals per service
-- ============================================================
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

-- ============================================================
-- 7. HELPER FUNCTION: Get Pay Application data for a project
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
  v_line              record;
  v_prev_rec          record;
  v_accumulated_qty   numeric;
  v_earned            numeric;
  v_this_period_amt   numeric;
BEGIN
  -- Get project quote_id
  SELECT quote_id INTO v_quote_id FROM public.projects WHERE id = p_project_id;

  -- Calculate original contract sum (scheduled value from quote services)
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
    SELECT COALESCE(SUM(rml.production_value), 0)
    INTO v_accumulated_qty
    FROM public.report_machinery_logs rml
    JOIN public.daily_reports dr ON dr.id = rml.daily_report_id
    JOIN public.project_machinery pm ON pm.id = rml.project_machinery_id
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

-- ============================================================
-- 8. ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE public.invoice_sequences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.change_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.change_order_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_details ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.invoice_change_order_links ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users access (matching existing project policies style)
CREATE POLICY select_all ON public.invoice_sequences FOR SELECT USING (true);
CREATE POLICY all_all ON public.invoice_sequences FOR ALL USING (true);

CREATE POLICY select_change_orders ON public.change_orders FOR SELECT USING (true);
CREATE POLICY insert_change_orders ON public.change_orders FOR INSERT WITH CHECK (true);
CREATE POLICY update_change_orders ON public.change_orders FOR UPDATE USING (true);
CREATE POLICY delete_change_orders ON public.change_orders FOR DELETE USING (true);

CREATE POLICY select_change_order_details ON public.change_order_details FOR SELECT USING (true);
CREATE POLICY insert_change_order_details ON public.change_order_details FOR INSERT WITH CHECK (true);
CREATE POLICY update_change_order_details ON public.change_order_details FOR UPDATE USING (true);
CREATE POLICY delete_change_order_details ON public.change_order_details FOR DELETE USING (true);

CREATE POLICY select_invoices ON public.invoices FOR SELECT USING (true);
CREATE POLICY insert_invoices ON public.invoices FOR INSERT WITH CHECK (true);
CREATE POLICY update_invoices ON public.invoices FOR UPDATE USING (true);
CREATE POLICY delete_invoices ON public.invoices FOR DELETE USING (true);

CREATE POLICY select_invoice_details ON public.invoice_details FOR SELECT USING (true);
CREATE POLICY insert_invoice_details ON public.invoice_details FOR INSERT WITH CHECK (true);
CREATE POLICY update_invoice_details ON public.invoice_details FOR UPDATE USING (true);
CREATE POLICY delete_invoice_details ON public.invoice_details FOR DELETE USING (true);

CREATE POLICY select_links ON public.invoice_change_order_links FOR SELECT USING (true);
CREATE POLICY insert_links ON public.invoice_change_order_links FOR INSERT WITH CHECK (true);
CREATE POLICY delete_links ON public.invoice_change_order_links FOR DELETE USING (true);

NOTIFY pgrst, 'reload schema';
