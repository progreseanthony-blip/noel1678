-- Baseline versioning: support for multiple baseline snapshots and change orders

-- 1. Baseline Snapshots table
CREATE TABLE IF NOT EXISTS public.project_baseline_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES public.projects(id) ON DELETE CASCADE NOT NULL,
    version INT NOT NULL CHECK (version >= 1),
    label TEXT,
    reason TEXT,
    frozen_at TIMESTAMPTZ DEFAULT now(),
    frozen_by UUID REFERENCES auth.users(id),
    calculation_metadata JSONB NOT NULL DEFAULT '{}',
    UNIQUE(project_id, version)
);

ALTER TABLE public.project_baseline_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view baselines for their projects"
    ON public.project_baseline_snapshots FOR SELECT
    USING (auth.role() = 'authenticated');

CREATE POLICY "Users can insert baselines"
    ON public.project_baseline_snapshots FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 2. change_type columns on resource tables
ALTER TABLE public.project_machinery
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT 'planning'
        CHECK (change_type IN ('planning', 'change_order')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id);

ALTER TABLE public.project_labor
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT 'planning'
        CHECK (change_type IN ('planning', 'change_order')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id);

ALTER TABLE public.project_materials
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT 'planning'
        CHECK (change_type IN ('planning', 'change_order')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id);

ALTER TABLE public.project_instruments
    ADD COLUMN IF NOT EXISTS change_type TEXT NOT NULL DEFAULT 'planning'
        CHECK (change_type IN ('planning', 'change_order')),
    ADD COLUMN IF NOT EXISTS baseline_snapshot_id UUID
        REFERENCES public.project_baseline_snapshots(id);

-- 3. Index for faster queries
CREATE INDEX IF NOT EXISTS idx_baseline_snapshots_project
    ON public.project_baseline_snapshots(project_id, version DESC);

CREATE INDEX IF NOT EXISTS idx_machinery_baseline_snapshot
    ON public.project_machinery(baseline_snapshot_id);

CREATE INDEX IF NOT EXISTS idx_labor_baseline_snapshot
    ON public.project_labor(baseline_snapshot_id);

CREATE INDEX IF NOT EXISTS idx_materials_baseline_snapshot
    ON public.project_materials(baseline_snapshot_id);

CREATE INDEX IF NOT EXISTS idx_instruments_baseline_snapshot
    ON public.project_instruments(baseline_snapshot_id);
