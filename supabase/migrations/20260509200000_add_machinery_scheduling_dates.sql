-- Migration to add scheduling dates to project machinery
ALTER TABLE public.project_machinery 
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;

-- Ensure end_date is not before start_date
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_machinery_scheduling_dates') THEN
        ALTER TABLE public.project_machinery 
        ADD CONSTRAINT check_machinery_scheduling_dates CHECK (end_date >= start_date);
    END IF;
END $$;

-- Tell PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
