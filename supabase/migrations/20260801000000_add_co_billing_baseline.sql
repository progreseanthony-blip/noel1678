-- Migration: Add CO billing segmentation and BAC baseline
-- Adds effective_date for temporal production segmentation
-- Adds baseline_budget for frozen original budget tracking

ALTER TABLE public.change_order_details
  ADD COLUMN IF NOT EXISTS effective_date DATE;

COMMENT ON COLUMN public.change_order_details.effective_date IS
  'Date from which the CO line item takes effect. Production before this date belongs to original scope; production after belongs to the CO increment. Defaults to change_order.approved_at.';

ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS baseline_budget NUMERIC DEFAULT 0;

COMMENT ON COLUMN public.projects.baseline_budget IS
  'Frozen original contract budget. Set at project creation and never updated by CO approvals. Current budget = baseline_budget + SUM(approved COs adjustment_amount).';
