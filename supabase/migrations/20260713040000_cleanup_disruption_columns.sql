-- ============================================================
-- Migration: cleanup extra disruption columns from daily_reports
-- Keep only disruption_active; remove unused FK/reason columns
-- ============================================================

ALTER TABLE public.daily_reports
  DROP COLUMN IF EXISTS disruption_co_id,
  DROP COLUMN IF EXISTS disruption_reason_code,
  DROP COLUMN IF EXISTS disruption_description;
