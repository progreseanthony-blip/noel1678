-- Trigger to update active_employees count in project_labor
CREATE OR REPLACE FUNCTION public.handle_labor_checkin_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.project_labor 
        SET active_employees = active_employees + 1
        WHERE id = NEW.project_labor_id;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF (OLD.status = 'active' AND NEW.status = 'completed') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = NEW.project_labor_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF (OLD.status = 'active') THEN
            UPDATE public.project_labor 
            SET active_employees = active_employees - 1
            WHERE id = OLD.project_labor_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_labor_checkin_change ON public.labor_checkins;
CREATE TRIGGER on_labor_checkin_change
AFTER INSERT OR UPDATE OR DELETE ON public.labor_checkins
FOR EACH ROW EXECUTE FUNCTION public.handle_labor_checkin_changes();
