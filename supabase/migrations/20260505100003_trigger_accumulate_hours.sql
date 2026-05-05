-- Trigger to update actual_hours in project_tasks when a check-in is completed
CREATE OR REPLACE FUNCTION public.handle_checkin_completion()
RETURNS TRIGGER AS $$
DECLARE
    duration_hours NUMERIC;
BEGIN
    IF NEW.status = 'completed' AND OLD.status = 'active' AND NEW.check_out IS NOT NULL THEN
        -- Calculate hours
        duration_hours := EXTRACT(EPOCH FROM (NEW.check_out - NEW.check_in)) / 3600;
        
        -- Update task
        IF NEW.project_task_id IS NOT NULL THEN
            UPDATE public.project_tasks
            SET actual_hours = actual_hours + duration_hours
            WHERE id = NEW.project_task_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_checkin_completion ON public.labor_checkins;
CREATE TRIGGER on_checkin_completion
AFTER UPDATE ON public.labor_checkins
FOR EACH ROW
EXECUTE FUNCTION public.handle_checkin_completion();
