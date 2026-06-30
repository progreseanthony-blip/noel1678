-- Migration: Fix cost_impact recalculation when affected items change after resolution
-- Previously cost_impact was only recalculated when ended_at changed.
-- Now it also recalculates when affected items are added, removed, or updated.

CREATE OR REPLACE FUNCTION public.recalculate_incident_cost_after_items_change()
RETURNS TRIGGER AS $$
DECLARE
    v_incident_id UUID;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_incident_id := OLD.incident_id;
    ELSE
        v_incident_id := NEW.incident_id;
    END IF;

    UPDATE public.incidents
    SET cost_impact = (
        SELECT COALESCE(
            (SELECT SUM(hourly_cost_rate) FROM public.incident_affected_items WHERE incident_id = v_incident_id),
            0
        ) * COALESCE(
            (SELECT EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600 FROM public.incidents WHERE id = v_incident_id),
            0
        ) + COALESCE(
            (SELECT SUM(downtime_rent_cost) FROM public.incident_affected_items WHERE incident_id = v_incident_id),
            0
        )
    )
    WHERE id = v_incident_id
      AND ended_at IS NOT NULL;

    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS recalculate_incident_cost_after_items_change ON public.incident_affected_items;
CREATE TRIGGER recalculate_incident_cost_after_items_change
    AFTER INSERT OR UPDATE OR DELETE ON public.incident_affected_items
    FOR EACH ROW
    EXECUTE FUNCTION public.recalculate_incident_cost_after_items_change();

NOTIFY pgrst, 'reload schema';
