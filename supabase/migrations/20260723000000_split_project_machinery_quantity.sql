-- Split project_machinery rows where expected_quantity > 1 into individual rows
-- This ensures each physical machine gets its own row for proper per-machine tracking

DO $$
DECLARE
    rec RECORD;
    i INT;
BEGIN
    FOR rec IN
        SELECT *
        FROM public.project_machinery
        WHERE expected_quantity > 1
    LOOP
        -- Create (expected_quantity - 1) additional rows
        FOR i IN 1..(rec.expected_quantity - 1) LOOP
            INSERT INTO public.project_machinery (
                project_id,
                quote_service_machinery_id,
                quote_service_id,
                machinery_name,
                expected_quantity,
                received_quantity,
                is_principal,
                parent_machinery_id,
                is_unplanned,
                unplanned_cost,
                calculation_metadata,
                machinery_id,
                change_type,
                baseline_snapshot_id,
                source_co_id,
                start_date,
                end_date
            ) VALUES (
                rec.project_id,
                rec.quote_service_machinery_id,
                rec.quote_service_id,
                rec.machinery_name,
                1,
                rec.received_quantity,
                rec.is_principal,
                rec.parent_machinery_id,
                rec.is_unplanned,
                rec.unplanned_cost,
                rec.calculation_metadata,
                rec.machinery_id,
                rec.change_type,
                rec.baseline_snapshot_id,
                rec.source_co_id,
                rec.start_date,
                rec.end_date
            );
        END LOOP;

        -- Set the original row to expected_quantity = 1
        UPDATE public.project_machinery
        SET expected_quantity = 1
        WHERE id = rec.id;
    END LOOP;
END;
$$;
