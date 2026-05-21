-- Migration: Create missing assignment/inspection tables
-- These tables are referenced by app code and later migrations but were never created

-- 1. Create project_machinery_assignments (for scheduling dialog + EVM fields)
CREATE TABLE IF NOT EXISTS public.project_machinery_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_machinery_id UUID NOT NULL REFERENCES public.project_machinery(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    actual_start_date DATE,
    actual_end_date DATE,
    status TEXT DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'delayed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.project_machinery_assignments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for machinery_assignments'
    ) THEN
        CREATE POLICY "Enable all access for machinery_assignments" ON public.project_machinery_assignments
        FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
    END IF;
END
$$;

-- 2. Create project_instrument_assignments (for instrument scheduling dialog)
CREATE TABLE IF NOT EXISTS public.project_instrument_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_instrument_id UUID NOT NULL REFERENCES public.project_instruments(id) ON DELETE CASCADE,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.project_instrument_assignments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for instrument_assignments'
    ) THEN
        CREATE POLICY "Enable all access for instrument_assignments" ON public.project_instrument_assignments
        FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
    END IF;
END
$$;

-- 3. Add scheduling date columns to project_instruments
ALTER TABLE public.project_instruments
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;
