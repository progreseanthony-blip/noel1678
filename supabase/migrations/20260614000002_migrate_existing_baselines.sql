-- Migrate existing projects with baseline_frozen = true to the new versioned system

DO $$
DECLARE
    project_rec RECORD;
    snapshot_id UUID;
    v INT;
    meta JSONB;
BEGIN
    FOR project_rec IN
        SELECT id, calculation_metadata
        FROM public.projects
        WHERE calculation_metadata->>'baseline_frozen' = 'true'
          AND calculation_metadata->>'baseline_latest_snapshot_id' IS NULL
    LOOP
        -- Determine next version
        SELECT COALESCE(MAX(version), 0) + 1 INTO v
        FROM public.project_baseline_snapshots
        WHERE project_id = project_rec.id;

        -- Create snapshot
        meta := project_rec.calculation_metadata;
        meta := jsonb_set(meta, '{baseline_latest_version}', to_jsonb(v));

        INSERT INTO public.project_baseline_snapshots
            (project_id, version, label, frozen_at, calculation_metadata)
        VALUES
            (project_rec.id, v, 'v' || v, 
             COALESCE(
                 (project_rec.calculation_metadata->>'baseline_frozen_at')::timestamptz,
                 now()
             ),
             project_rec.calculation_metadata)
        RETURNING id INTO snapshot_id;

        -- Update calculation_metadata with snapshot reference
        meta := jsonb_set(meta, '{baseline_latest_snapshot_id}', to_jsonb(snapshot_id::text));
        meta := meta - 'baseline_frozen';

        UPDATE public.projects
        SET calculation_metadata = meta
        WHERE id = project_rec.id;

        -- Assign snapshot to all existing resources for this project
        UPDATE public.project_machinery
        SET baseline_snapshot_id = snapshot_id,
            change_type = 'planning'
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_labor
        SET baseline_snapshot_id = snapshot_id,
            change_type = 'planning'
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_materials
        SET baseline_snapshot_id = snapshot_id,
            change_type = 'planning'
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;

        UPDATE public.project_instruments
        SET baseline_snapshot_id = snapshot_id,
            change_type = 'planning'
        WHERE project_id = project_rec.id
          AND baseline_snapshot_id IS NULL;
    END LOOP;
END $$;
