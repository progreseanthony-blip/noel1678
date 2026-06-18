-- Migration: Refactor incident cost calculation to use resource-specific hourly rates
-- Replaces project-level hourly_operating_cost with per-resource hourly_cost_rate

-- 1. Add hourly_cost_rate to incident_affected_items (suggested, user-editable)
ALTER TABLE public.incident_affected_items
ADD COLUMN IF NOT EXISTS hourly_cost_rate NUMERIC DEFAULT 0;

-- 2. Remove estimated_cost (confusing with actual_expenses)
ALTER TABLE public.incident_affected_items
DROP COLUMN IF EXISTS estimated_cost;

-- 3. Modify trigger to use SUM of resource hourly rates instead of project.hourly_operating_cost
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.cost_impact := NEW.time_impact_hours * COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Ensure trigger is properly set
DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents;
CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact();

NOTIFY pgrst, 'reload schema';
