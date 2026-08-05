-- Split project_labor rows where expected_employees > 1 into individual rows
-- Each row now represents exactly 1 worker slot (expected_employees = 1)
-- Mirrors machinery split in 20260723000000_split_project_machinery_quantity.sql

DO $$
DECLARE
    rec RECORD;
    i INT;
BEGIN
    FOR rec IN
        SELECT * FROM public.project_labor WHERE expected_employees > 1
    LOOP
        FOR i IN 1..(rec.expected_employees - 1) LOOP
            INSERT INTO public.project_labor (
                project_id, quote_service_labor_id, quote_service_id,
                role_name, expected_employees, active_employees,
                is_unplanned, linked_machinery_id, unplanned_cost,
                calculation_metadata, role_id, start_date, end_date,
                change_type, baseline_snapshot_id, source_co_id,
                project_service_id
            ) VALUES (
                rec.project_id, rec.quote_service_labor_id, rec.quote_service_id,
                rec.role_name, 1, 0,
                rec.is_unplanned, rec.linked_machinery_id, rec.unplanned_cost,
                rec.calculation_metadata, rec.role_id, rec.start_date, rec.end_date,
                rec.change_type, rec.baseline_snapshot_id, rec.source_co_id,
                rec.project_service_id
            );
        END LOOP;

        UPDATE public.project_labor
        SET expected_employees = 1,
            active_employees = CASE WHEN active_employees > 1 THEN 1 ELSE active_employees END
        WHERE id = rec.id;
    END LOOP;
END;
$$;
