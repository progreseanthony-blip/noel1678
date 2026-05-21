-- Migration: Add Planning Baseline Fields
-- Description: Adds fields to support execution baseline, principal machinery, and unplanned resources.

-- 1. Update projects table to inherit quote_type
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS project_type TEXT NOT NULL DEFAULT 'standard';

-- Propagate the type from quotes to existing projects
UPDATE public.projects p
SET project_type = q.quote_type
FROM public.quotes q
WHERE p.quote_id = q.id;

-- 2. Update project_machinery table for principal/support hierarchy and unplanned flag
ALTER TABLE public.project_machinery 
ADD COLUMN IF NOT EXISTS is_principal BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS parent_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false;

-- 3. Update project_labor table to link with machinery and track unplanned resources
ALTER TABLE public.project_labor 
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS linked_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE CASCADE;

-- 4. Automatic Operator Assignment Trigger
-- When a machinery is added (unplanned/replan), automatically create an operator placeholder in project_labor
CREATE OR REPLACE FUNCTION public.handle_machinery_operator_assignment()
RETURNS TRIGGER AS $$
DECLARE
    v_role_name TEXT;
BEGIN
    -- We only auto-generate for unplanned machinery added during execution/re-planning phase.
    -- (Planned machinery from quotes already has its labor inserted via ProjectService.convertQuoteToProject)
    IF NEW.is_unplanned = true THEN
        v_role_name := 'Operador de ' || NEW.machinery_name;

        INSERT INTO public.project_labor (
            project_id, 
            quote_service_id,
            role_name, 
            expected_employees, 
            is_unplanned, 
            linked_machinery_id
        ) VALUES (
            NEW.project_id,
            NEW.quote_service_id,
            v_role_name,
            NEW.expected_quantity, -- Match the number of operators to the number of machines
            true,
            NEW.id
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trigger_machinery_operator_assignment ON public.project_machinery;
CREATE TRIGGER trigger_machinery_operator_assignment
AFTER INSERT ON public.project_machinery
FOR EACH ROW
EXECUTE FUNCTION public.handle_machinery_operator_assignment();
