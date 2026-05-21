-- Add tracking fields for EVM (Planned vs Real) on Machinery
ALTER TABLE public.machinery_inspections
ADD COLUMN IF NOT EXISTS returned_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS hour_meter_end NUMERIC;

-- Ensure returned_at is not before received_at
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'check_inspection_dates') THEN
        ALTER TABLE public.machinery_inspections 
        ADD CONSTRAINT check_inspection_dates CHECK (returned_at >= received_at);
    END IF;
END $$;


-- Add tracking fields for EVM on Machinery Assignments
ALTER TABLE public.project_machinery_assignments
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_end_date DATE,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'delayed'));

-- Add tracking fields for EVM on Labor Assignments
ALTER TABLE public.project_labor_assignments
ADD COLUMN IF NOT EXISTS actual_start_date DATE,
ADD COLUMN IF NOT EXISTS actual_end_date DATE,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'delayed'));

-- Tell PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
