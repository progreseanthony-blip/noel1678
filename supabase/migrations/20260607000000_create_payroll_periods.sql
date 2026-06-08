-- Create payroll_periods table for project labor cost tracking
CREATE TABLE IF NOT EXISTS public.payroll_periods (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  total_regular_hours NUMERIC NOT NULL DEFAULT 0,
  total_overtime_hours NUMERIC NOT NULL DEFAULT 0,
  total_workers INTEGER NOT NULL DEFAULT 0,
  total_cost NUMERIC NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'calculated',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT payroll_periods_dates_check CHECK (end_date >= start_date)
);

-- Trigger to auto-update updated_at
CREATE OR REPLACE FUNCTION handle_payroll_periods_update()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_payroll_periods_update ON public.payroll_periods;
CREATE TRIGGER trg_payroll_periods_update
  BEFORE UPDATE ON public.payroll_periods
  FOR EACH ROW EXECUTE FUNCTION handle_payroll_periods_update();

-- Index for fast lookup by project
CREATE INDEX IF NOT EXISTS idx_payroll_periods_project
  ON public.payroll_periods(project_id);

-- Enable RLS
ALTER TABLE public.payroll_periods ENABLE ROW LEVEL SECURITY;

-- RLS: authenticated users can read all
CREATE POLICY "Authenticated users can read payroll_periods"
  ON public.payroll_periods FOR SELECT
  TO authenticated
  USING (true);

-- RLS: authenticated users can insert
CREATE POLICY "Authenticated users can insert payroll_periods"
  ON public.payroll_periods FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- RLS: authenticated users can update
CREATE POLICY "Authenticated users can update payroll_periods"
  ON public.payroll_periods FOR UPDATE
  TO authenticated
  USING (true);

-- RLS: authenticated users can delete
CREATE POLICY "Authenticated users can delete payroll_periods"
  ON public.payroll_periods FOR DELETE
  TO authenticated
  USING (true);

NOTIFY pgrst, 'reload schema';
