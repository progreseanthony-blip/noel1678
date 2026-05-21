-- Migration to add scheduling dates to project_labor
ALTER TABLE public.project_labor 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;

-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_labor_scheduling_dates') THEN
        ALTER TABLE public.project_labor 
        ADD CONSTRAINT check_labor_scheduling_dates CHECK (end_date >= start_date);
    END IF;
END $$;
