-- Migration: Create Project Machinery Assignments Table
-- Description: Tracks operator assignments to machinery with scheduling dates

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

-- RLS
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
