-- Migration: Add daily rate and days affected for machinery downtime cost tracking
-- Supports monetary compensation for rented machinery unavailability

-- 1. Add columns to incident_affected_items
ALTER TABLE public.incident_affected_items
  ADD COLUMN IF NOT EXISTS daily_rate NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS days_affected NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS downtime_rent_cost NUMERIC 
    GENERATED ALWAYS AS (daily_rate * days_affected) STORED;

-- 2. Update trigger to include downtime_rent_cost in cost_impact
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ended_at IS NOT NULL THEN
        NEW.cost_impact := (NEW.time_impact_hours * COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        )) + COALESCE(
            (SELECT SUM(downtime_rent_cost) FROM public.incident_affected_items WHERE incident_id = NEW.id),
            0
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Re-create trigger
DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents;
CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact();
