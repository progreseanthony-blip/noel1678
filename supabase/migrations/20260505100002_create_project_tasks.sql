-- Create project_tasks table
CREATE TABLE IF NOT EXISTS public.project_tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_id UUID REFERENCES public.quote_services(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT NOT NULL DEFAULT 'pending', -- pending, in_progress, completed, blocked
    estimated_hours NUMERIC DEFAULT 0,
    actual_hours NUMERIC DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Add task_id to labor_checkins
ALTER TABLE public.labor_checkins ADD COLUMN IF NOT EXISTS project_task_id UUID REFERENCES public.project_tasks(id) ON DELETE SET NULL;

-- Enable RLS
ALTER TABLE public.project_tasks ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all actions for authenticated users on project_tasks') THEN
        CREATE POLICY "Allow all actions for authenticated users on project_tasks" ON public.project_tasks TO authenticated USING (true);
    END IF;
END $$;

-- Backfill tasks from existing quote_services for active projects
INSERT INTO public.project_tasks (project_id, quote_service_id, name, status)
SELECT 
    p.id as project_id,
    qs.id as quote_service_id,
    qs.name as name,
    'in_progress' as status
FROM public.projects p
JOIN public.quote_services qs ON p.quote_id = qs.quote_id;
