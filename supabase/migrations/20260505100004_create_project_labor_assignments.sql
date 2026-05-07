-- Create project_labor_assignments table
CREATE TABLE IF NOT EXISTS public.project_labor_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_labor_id UUID REFERENCES public.project_labor(id) ON DELETE CASCADE,
    worker_id UUID REFERENCES public.workers(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    UNIQUE(project_labor_id, worker_id)
);

-- Enable RLS
ALTER TABLE public.project_labor_assignments ENABLE ROW LEVEL SECURITY;

-- Create policy
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'allow_all_assignments') THEN
        CREATE POLICY "allow_all_assignments" ON public.project_labor_assignments
        FOR ALL TO authenticated USING (true);
    END IF;
END $$;
