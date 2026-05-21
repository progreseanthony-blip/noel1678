-- Migration: Create Instrument Assignments + Scheduling Columns
-- Note: This table may also be created by 20260522000000 (IF NOT EXISTS makes it safe)

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

ALTER TABLE public.project_instruments
ADD COLUMN IF NOT EXISTS start_date DATE,
ADD COLUMN IF NOT EXISTS end_date DATE;
