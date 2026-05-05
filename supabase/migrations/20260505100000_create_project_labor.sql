-- Create project_labor table
CREATE TABLE IF NOT EXISTS public.project_labor (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_labor_id UUID REFERENCES public.quote_service_labors(id) ON DELETE SET NULL,
    role_name TEXT NOT NULL,
    expected_employees INTEGER NOT NULL DEFAULT 1,
    active_employees INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create labor_checkins table (to track who is working where)
CREATE TABLE IF NOT EXISTS public.labor_checkins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    project_labor_id UUID NOT NULL REFERENCES public.project_labor(id) ON DELETE CASCADE,
    worker_id UUID NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    check_in TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    check_out TIMESTAMP WITH TIME ZONE,
    status TEXT NOT NULL DEFAULT 'active', -- active, completed
    observations TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.project_labor ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.labor_checkins ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all actions for authenticated users on project_labor') THEN
        CREATE POLICY "Allow all actions for authenticated users on project_labor" ON public.project_labor TO authenticated USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all actions for authenticated users on labor_checkins') THEN
        CREATE POLICY "Allow all actions for authenticated users on labor_checkins" ON public.labor_checkins TO authenticated USING (true);
    END IF;
END $$;

-- Populate project_labor for existing projects
INSERT INTO public.project_labor (project_id, quote_service_labor_id, role_name, expected_employees)
SELECT 
    p.id as project_id,
    qsl.id as quote_service_labor_id,
    qsl.role_name as role_name,
    qsl.employees_quantity as expected_employees
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id
JOIN public.quote_service_labors qsl ON qs.id = qsl.quote_service_id
ON CONFLICT DO NOTHING;
