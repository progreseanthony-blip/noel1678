-- Create projects table
CREATE TABLE IF NOT EXISTS public.projects (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_id UUID REFERENCES public.quotes(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    client_name TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'completed', 'on_hold', 'cancelled')),
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create project_machinery table (Expected inventory)
CREATE TABLE IF NOT EXISTS public.project_machinery (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_machinery_id UUID REFERENCES public.quote_service_machineries(id) ON DELETE SET NULL,
    machinery_name TEXT NOT NULL,
    expected_quantity INTEGER NOT NULL DEFAULT 1,
    received_quantity INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create machinery_inspections table (Individual machines received)
CREATE TABLE IF NOT EXISTS public.machinery_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_machinery_id UUID NOT NULL REFERENCES public.project_machinery(id) ON DELETE CASCADE,
    internal_code TEXT,
    brand_model TEXT,
    ownership_type TEXT DEFAULT 'owned' CHECK (ownership_type IN ('owned', 'rented')),
    provider_name TEXT,
    hour_meter_start NUMERIC,
    condition_status TEXT DEFAULT 'operational' CHECK (condition_status IN ('excellent', 'operational', 'needs_maintenance', 'damaged')),
    evidence_photos JSONB DEFAULT '[]'::jsonb,
    observations TEXT,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    received_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Create bucket for machinery photos if it doesn't exist
INSERT INTO storage.buckets (id, name, public) 
VALUES ('machinery_evidence', 'machinery_evidence', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for machinery evidence
CREATE POLICY "Public Access for machinery evidence" 
ON storage.objects FOR SELECT 
USING ( bucket_id = 'machinery_evidence' );

CREATE POLICY "Auth Insert for machinery evidence" 
ON storage.objects FOR INSERT 
WITH CHECK ( bucket_id = 'machinery_evidence' AND auth.role() = 'authenticated' );

-- RLS Policies for projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on projects"
    ON public.projects FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for project_machinery
ALTER TABLE public.project_machinery ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on project_machinery"
    ON public.project_machinery FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- RLS Policies for machinery_inspections
ALTER TABLE public.machinery_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on machinery_inspections"
    ON public.machinery_inspections FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');
