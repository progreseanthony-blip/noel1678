-- Redistribute project_labor_assignments across sibling project_labor rows
-- After the labor split, all assignments pile on one row. Siblings are empty.
-- This moves one assignment from the "rich" row to each empty sibling.

DO $$
DECLARE
    empty_rec RECORD;
    rich_rec RECORD;
BEGIN
    FOR empty_rec IN
        SELECT pl.id, pl.project_id, pl.quote_service_id, pl.role_name
        FROM public.project_labor pl
        WHERE NOT EXISTS (
            SELECT 1 FROM public.project_labor_assignments pla
            WHERE pla.project_labor_id = pl.id
        )
    LOOP
        SELECT a.id as assignment_id
        INTO rich_rec
        FROM public.project_labor pl2
        JOIN public.project_labor_assignments a ON a.project_labor_id = pl2.id
        WHERE pl2.project_id = empty_rec.project_id
          AND pl2.quote_service_id IS NOT DISTINCT FROM empty_rec.quote_service_id
          AND pl2.role_name = empty_rec.role_name
          AND pl2.id != empty_rec.id
        LIMIT 1;

        IF FOUND THEN
            UPDATE public.project_labor_assignments
            SET project_labor_id = empty_rec.id
            WHERE id = rich_rec.assignment_id;
        END IF;
    END LOOP;
END;
$$;
