-- Migration: Add day_type (working/non_working/partial) to daily reports
-- Enables marking a report as a rain day, half-day, etc.

-- 1. Add columns to daily_reports
ALTER TABLE public.daily_reports 
  ADD COLUMN IF NOT EXISTS day_type text NOT NULL DEFAULT 'working'
    CHECK (day_type IN ('working', 'non_working', 'partial'));
ALTER TABLE public.daily_reports 
  ADD COLUMN IF NOT EXISTS non_working_reason text;
ALTER TABLE public.daily_reports
  ADD COLUMN IF NOT EXISTS stopped_at time;

-- 2. Create project_non_working_days table (used by progress/SPI tracking)
CREATE TABLE IF NOT EXISTS public.project_non_working_days (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    date date NOT NULL,
    reason text,
    partial_ratio numeric NOT NULL DEFAULT 0,  -- 0 = full non-working, 0.5 = half day, etc.
    daily_report_id uuid REFERENCES public.daily_reports(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(project_id, date)
);

ALTER TABLE public.project_non_working_days ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on project_non_working_days"
  ON public.project_non_working_days FOR ALL TO authenticated USING (true);
