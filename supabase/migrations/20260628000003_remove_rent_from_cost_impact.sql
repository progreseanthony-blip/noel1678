-- Migration: Remove downtime_rent_cost from cost_impact calculation
-- Downtime rent is compensated by the contracting company, so only time-based cost applies

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

DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents;
CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact();
