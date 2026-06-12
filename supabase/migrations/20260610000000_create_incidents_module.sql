-- Migration: Create Incidents Module
-- Description: Adds incident reporting with specific resource impact tracking

-- Add hourly_operating_cost to projects for automatic impact calculation
ALTER TABLE public.projects
ADD COLUMN IF NOT EXISTS hourly_operating_cost NUMERIC DEFAULT 0;

-- Create incident categories catalog (editable from app)
CREATE TABLE IF NOT EXISTS public.incident_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    icon TEXT DEFAULT 'warning_amber',
    color TEXT DEFAULT '#EF4444',
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.incident_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on incident_categories"
    ON public.incident_categories FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Seed default categories
INSERT INTO public.incident_categories (code, name, icon, color) VALUES
    ('MACHINERY_BREAKDOWN', 'Machinery Breakdown', 'engineering', '#EF4444'),
    ('INSTRUMENT_DAMAGE', 'Instrument Damage', 'build', '#F97316'),
    ('WORKER_ABSENCE', 'Worker Absence', 'person_off', '#EAB308'),
    ('WORKER_REPLACEMENT', 'Worker Replacement', 'swap_horiz', '#A855F7'),
    ('MATERIAL_SHORTAGE', 'Material Shortage', 'inventory_2', '#3B82F6'),
    ('MATERIAL_DAMAGE', 'Material Damage', 'broken_image', '#EF4444'),
    ('WEATHER', 'Weather Contingency', 'thunderstorm', '#06B6D4'),
    ('ACCIDENT', 'Accident', 'local_hospital', '#DC2626'),
    ('QUALITY_DEFECT', 'Quality Defect', 'report_problem', '#F97316'),
    ('OTHER', 'Other', 'warning_amber', '#64748B')
ON CONFLICT (code) DO NOTHING;

-- Main incidents table
CREATE TABLE IF NOT EXISTS public.incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    daily_report_id UUID REFERENCES public.daily_reports(id) ON DELETE SET NULL,
    category_id UUID REFERENCES public.incident_categories(id),
    title TEXT NOT NULL,
    description TEXT,
    priority TEXT NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    status TEXT NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    time_impact_hours NUMERIC GENERATED ALWAYS AS (
        CASE WHEN ended_at IS NOT NULL
             THEN EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600
             ELSE NULL END
    ) STORED,
    cost_impact NUMERIC,
    actual_expenses NUMERIC DEFAULT 0,
    resolution_notes TEXT,
    reported_by UUID REFERENCES auth.users(id),
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    evidence_photos JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.incidents ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on incidents"
    ON public.incidents FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Specific project resources affected by the incident
CREATE TABLE IF NOT EXISTS public.incident_affected_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    affected_type TEXT NOT NULL
        CHECK (affected_type IN ('material', 'machinery', 'labor', 'instrument')),
    project_material_id UUID REFERENCES public.project_materials(id) ON DELETE SET NULL,
    project_machinery_id UUID REFERENCES public.project_machinery(id) ON DELETE SET NULL,
    project_labor_id UUID REFERENCES public.project_labor(id) ON DELETE SET NULL,
    project_instrument_id UUID REFERENCES public.project_instruments(id) ON DELETE SET NULL,
    worker_id UUID REFERENCES public.workers(id) ON DELETE SET NULL,
    machinery_inspection_id UUID REFERENCES public.machinery_inspections(id) ON DELETE SET NULL,
    project_instrument_assignment_id UUID REFERENCES public.project_instrument_assignments(id) ON DELETE SET NULL,
    resource_name TEXT NOT NULL,
    quantity_affected NUMERIC NOT NULL DEFAULT 0,
    unit TEXT,
    estimated_cost NUMERIC DEFAULT 0,
    description TEXT,
    CONSTRAINT chk_single_resource CHECK (
        (CASE WHEN project_material_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_machinery_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_labor_id IS NOT NULL THEN 1 ELSE 0 END +
         CASE WHEN project_instrument_id IS NOT NULL THEN 1 ELSE 0 END) >= 1
    )
);

ALTER TABLE public.incident_affected_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on incident_affected_items"
    ON public.incident_affected_items FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Follow-up actions for each incident
CREATE TABLE IF NOT EXISTS public.incident_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    incident_id UUID NOT NULL REFERENCES public.incidents(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    assigned_to UUID REFERENCES auth.users(id),
    due_date DATE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed')),
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.incident_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on incident_actions"
    ON public.incident_actions FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Function to calculate cost_impact when ended_at is set
CREATE OR REPLACE FUNCTION public.calculate_incident_cost_impact()
RETURNS TRIGGER AS $$
DECLARE
    v_hourly_rate NUMERIC;
BEGIN
    IF NEW.ended_at IS NOT NULL AND OLD.ended_at IS DISTINCT FROM NEW.ended_at THEN
        SELECT hourly_operating_cost INTO v_hourly_rate
        FROM public.projects WHERE id = NEW.project_id;
        NEW.cost_impact := (EXTRACT(EPOCH FROM (NEW.ended_at - NEW.started_at)) / 3600) * COALESCE(v_hourly_rate, 0);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS calculate_incident_cost_impact ON public.incidents;
CREATE TRIGGER calculate_incident_cost_impact
    BEFORE INSERT OR UPDATE OF ended_at ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.calculate_incident_cost_impact();

-- Trigger to update updated_at on incidents
DROP TRIGGER IF EXISTS update_incidents_modtime ON public.incidents;
CREATE TRIGGER update_incidents_modtime
    BEFORE UPDATE ON public.incidents
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

NOTIFY pgrst, 'reload schema';
