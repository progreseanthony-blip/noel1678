-- Migration to add scheduling dates to labor assignments
ALTER TABLE public.project_labor_assignments 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;

-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_assignment_dates') THEN
        ALTER TABLE public.project_labor_assignments 
        ADD CONSTRAINT check_assignment_dates CHECK (end_date >= start_date);
    END IF;
END $$;
