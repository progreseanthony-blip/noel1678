-- Migration: Add schedule impact tracking for idempotency
-- Prevents double-applying schedule shifts via Re-apply button

ALTER TABLE public.change_order_disruptions
  ADD COLUMN IF NOT EXISTS schedule_impact_applied_at TIMESTAMPTZ;

COMMENT ON COLUMN public.change_order_disruptions.schedule_impact_applied_at IS
  'Timestamp when applyScheduleImpact was last executed. NULL if never applied. Used to prevent duplicate shifts.';
