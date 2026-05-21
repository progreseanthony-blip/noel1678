-- Migration: Create Project Instruments Table
-- Description: Adds the project_instruments table to track tools and minor equipment allocated to a project.

-- 1. Create the project_instruments table
CREATE TABLE IF NOT EXISTS public.project_instruments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_instrument_id UUID REFERENCES public.quote_service_instruments(id) ON DELETE SET NULL,
    instrument_name TEXT NOT NULL,
    expected_quantity DECIMAL NOT NULL DEFAULT 1,
    received_quantity DECIMAL NOT NULL DEFAULT 0,
    is_unplanned BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Security: Enable RLS
ALTER TABLE public.project_instruments ENABLE ROW LEVEL SECURITY;

-- 3. Policies: Allow full access for authenticated users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for project_instruments'
    ) THEN
        CREATE POLICY "Enable all access for project_instruments" ON public.project_instruments
        FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
    END IF;
END
$$;

-- 4. Helper trigger for updated_at
DROP TRIGGER IF EXISTS update_project_instruments_modtime ON public.project_instruments;
CREATE TRIGGER update_project_instruments_modtime
    BEFORE UPDATE ON public.project_instruments
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

-- 5. Data Migration: Copy existing instruments from approved quotes to active projects
-- This ensures backward compatibility for projects already created.
INSERT INTO public.project_instruments (
    project_id, 
    quote_service_instrument_id, 
    instrument_name, 
    expected_quantity
)
SELECT 
    p.id,
    qsi.id,
    qsi.instrument_name,
    qsi.quantity
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id
JOIN public.quote_service_instruments qsi ON qs.id = qsi.quote_service_id
ON CONFLICT DO NOTHING;
