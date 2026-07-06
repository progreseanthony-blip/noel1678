-- Migration: Weekly inspections & progress comparison
-- Adds drone/GPS inspection tracking, deviation detection, and reconciliation workflow

-- 1. Weekly inspections header
CREATE TABLE IF NOT EXISTS public.weekly_inspections (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    inspection_date date NOT NULL,
    inspector_id uuid REFERENCES public.profiles(id),
    method text NOT NULL DEFAULT 'drone' CHECK (method IN ('drone', 'gps', 'total_station', 'other')),
    general_notes text,
    evidence_files jsonb DEFAULT '[]'::jsonb,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'reconciled')),
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (project_id, inspection_date)
);

-- 2. Per-service measurements from each inspection
CREATE TABLE IF NOT EXISTS public.weekly_inspection_details (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    inspection_id uuid NOT NULL REFERENCES public.weekly_inspections(id) ON DELETE CASCADE,
    quote_service_id uuid NOT NULL REFERENCES public.quote_services(id) ON DELETE CASCADE,
    measured_quantity numeric NOT NULL DEFAULT 0,
    unit text,
    total_planned_quantity numeric NOT NULL DEFAULT 0,
    percentage_completion numeric NOT NULL DEFAULT 0,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE (inspection_id, quote_service_id)
);

-- 3. Configurable thresholds per catalog service
CREATE TABLE IF NOT EXISTS public.service_inspection_thresholds (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    service_id uuid NOT NULL REFERENCES public.services(id) ON DELETE CASCADE,
    threshold_percentage numeric NOT NULL DEFAULT 5.0,
    active boolean NOT NULL DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (service_id)
);

-- 4. Deviation comparison results
CREATE TABLE IF NOT EXISTS public.progress_comparisons (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    inspection_id uuid NOT NULL REFERENCES public.weekly_inspections(id) ON DELETE CASCADE,
    inspection_detail_id uuid NOT NULL REFERENCES public.weekly_inspection_details(id) ON DELETE CASCADE,
    quote_service_id uuid NOT NULL REFERENCES public.quote_services(id) ON DELETE CASCADE,
    period_start date,
    period_end date,
    accumulated_daily_quantity numeric NOT NULL DEFAULT 0,
    inspection_measured_quantity numeric NOT NULL DEFAULT 0,
    deviation_absolute numeric NOT NULL DEFAULT 0,
    deviation_percentage numeric NOT NULL DEFAULT 0,
    threshold_configured numeric NOT NULL DEFAULT 5.0,
    exceeds_threshold boolean NOT NULL DEFAULT false,
    status text NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'comparison_done', 'exceeds_threshold', 'pending_approval', 'reconciled')),
    reconciliation_notes text,
    proposed_by uuid REFERENCES public.profiles(id),
    proposed_at timestamp with time zone,
    approved_by uuid REFERENCES public.profiles(id),
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE (inspection_detail_id)
);

-- 5. Individual adjustments audit trail
CREATE TABLE IF NOT EXISTS public.progress_adjustments (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    comparison_id uuid NOT NULL REFERENCES public.progress_comparisons(id) ON DELETE CASCADE,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    resource_type text NOT NULL CHECK (resource_type IN ('labor', 'machinery', 'material')),
    log_id uuid NOT NULL,
    field_name text NOT NULL DEFAULT 'production_value',
    original_value numeric NOT NULL DEFAULT 0,
    adjusted_value numeric NOT NULL DEFAULT 0,
    adjustment_reason text,
    adjusted_by uuid REFERENCES public.profiles(id),
    adjusted_at timestamp with time zone DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_weekly_inspections_project ON public.weekly_inspections(project_id, inspection_date);
CREATE INDEX IF NOT EXISTS idx_wi_details_inspection ON public.weekly_inspection_details(inspection_id);
CREATE INDEX IF NOT EXISTS idx_progress_comparisons_inspection ON public.progress_comparisons(inspection_id);
CREATE INDEX IF NOT EXISTS idx_progress_comparisons_status ON public.progress_comparisons(status);
CREATE INDEX IF NOT EXISTS idx_progress_comparisons_service ON public.progress_comparisons(quote_service_id);
CREATE INDEX IF NOT EXISTS idx_progress_adjustments_comparison ON public.progress_adjustments(comparison_id);

-- RLS Policies
ALTER TABLE public.weekly_inspections ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on weekly_inspections"
    ON public.weekly_inspections FOR ALL TO authenticated USING (true);

ALTER TABLE public.weekly_inspection_details ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on weekly_inspection_details"
    ON public.weekly_inspection_details FOR ALL TO authenticated USING (true);

ALTER TABLE public.service_inspection_thresholds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on service_inspection_thresholds"
    ON public.service_inspection_thresholds FOR ALL TO authenticated USING (true);

ALTER TABLE public.progress_comparisons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on progress_comparisons"
    ON public.progress_comparisons FOR ALL TO authenticated USING (true);

ALTER TABLE public.progress_adjustments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for authenticated users on progress_adjustments"
    ON public.progress_adjustments FOR ALL TO authenticated USING (true);

-- Trigger: auto-calculate percentage completion on inspection detail insert
CREATE OR REPLACE FUNCTION public.calc_inspection_percentage()
RETURNS trigger AS $$
BEGIN
    IF NEW.total_planned_quantity > 0 THEN
        NEW.percentage_completion := ROUND((NEW.measured_quantity / NEW.total_planned_quantity) * 100, 2);
    ELSE
        NEW.percentage_completion := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_calc_inspection_percentage ON public.weekly_inspection_details;
CREATE TRIGGER trg_calc_inspection_percentage
    BEFORE INSERT OR UPDATE OF measured_quantity, total_planned_quantity
    ON public.weekly_inspection_details
    FOR EACH ROW EXECUTE FUNCTION public.calc_inspection_percentage();

-- Trigger: update updated_at on threshold changes
CREATE OR REPLACE FUNCTION public.update_inspection_updated_at()
RETURNS trigger AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_weekly_inspections_updated_at ON public.weekly_inspections;
CREATE TRIGGER trg_weekly_inspections_updated_at
    BEFORE UPDATE ON public.weekly_inspections
    FOR EACH ROW EXECUTE FUNCTION public.update_inspection_updated_at();

DROP TRIGGER IF EXISTS trg_thresholds_updated_at ON public.service_inspection_thresholds;
CREATE TRIGGER trg_thresholds_updated_at
    BEFORE UPDATE ON public.service_inspection_thresholds
    FOR EACH ROW EXECUTE FUNCTION public.update_inspection_updated_at();

DROP TRIGGER IF EXISTS trg_comparisons_updated_at ON public.progress_comparisons;
CREATE TRIGGER trg_comparisons_updated_at
    BEFORE UPDATE ON public.progress_comparisons
    FOR EACH ROW EXECUTE FUNCTION public.update_inspection_updated_at();
