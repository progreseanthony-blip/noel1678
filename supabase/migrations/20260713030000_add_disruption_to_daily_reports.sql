-- ============================================================
-- Migration: add disruption tracking columns to daily_reports
-- Allows marking a day as disrupted with optional CO or reason
-- ============================================================

ALTER TABLE public.daily_reports
  ADD COLUMN IF NOT EXISTS disruption_active boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS disruption_co_id uuid REFERENCES public.change_orders(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS disruption_reason_code text,
  ADD COLUMN IF NOT EXISTS disruption_description text;
