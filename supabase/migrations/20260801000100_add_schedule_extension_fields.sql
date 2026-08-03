-- Migration: Add schedule/timeline extension fields for disruption change orders
-- Supports automatic schedule impact propagation on disruption CO approval

-- ============================================================
-- 1. projects — baseline schedule tracking
-- ============================================================
ALTER TABLE public.projects
  ADD COLUMN IF NOT EXISTS baseline_end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS schedule_extension_days INTEGER DEFAULT 0;

COMMENT ON COLUMN public.projects.baseline_end_date IS
  'Frozen original project end date. Set once at first disruption approval. SPI is calculated against this baseline, not the current end_date.';

COMMENT ON COLUMN public.projects.schedule_extension_days IS
  'Accumulated total days added via approved disruption change orders.';

-- ============================================================
-- 2. project_tasks — add planned dates for scheduling
-- ============================================================
ALTER TABLE public.project_tasks
  ADD COLUMN IF NOT EXISTS planned_start_date DATE,
  ADD COLUMN IF NOT EXISTS planned_end_date DATE;

COMMENT ON COLUMN public.project_tasks.planned_start_date IS
  'Planned start date of the task. Used by schedule impact propagation to shift resources.';

COMMENT ON COLUMN public.project_tasks.planned_end_date IS
  'Planned end date of the task. Extended by disruption delay_days on CO approval.';

-- ============================================================
-- 3. change_order_disruption_services — per-service delay tracking
-- ============================================================
ALTER TABLE public.change_order_disruption_services
  ADD COLUMN IF NOT EXISTS delay_days INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS original_end_date DATE,
  ADD COLUMN IF NOT EXISTS extended_end_date DATE;

COMMENT ON COLUMN public.change_order_disruption_services.delay_days IS
  'Working days of delay caused by the disruption for this specific service. Auto-calculated from disruption period, editable by PM.';

COMMENT ON COLUMN public.change_order_disruption_services.original_end_date IS
  'Service planned end date before the disruption was applied. Captured at CO approval time.';

COMMENT ON COLUMN public.change_order_disruption_services.extended_end_date IS
  'Service new planned end date after applying delay_days.';

-- ============================================================
-- 4. project_non_working_days — add source tracking
-- ============================================================
ALTER TABLE public.project_non_working_days
  ADD COLUMN IF NOT EXISTS source TEXT DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS source_id UUID;

COMMENT ON COLUMN public.project_non_working_days.source IS
  'Origin of the non-working day record: manual (daily report wizard) or disruption (auto-created from approved disruption CO).';

COMMENT ON COLUMN public.project_non_working_days.source_id IS
  'FK to the source record (e.g., change_orders.id for disruption source).';
