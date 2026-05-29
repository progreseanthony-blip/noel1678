-- ============================================================================
-- Módulo de Operaciones en Campo: Reporte Diario
-- Tablas para captura de progreso diario (labor, maquinaria, materiales)
-- ============================================================================

-- 1. Catálogo de motivos de desviación
CREATE TABLE IF NOT EXISTS public.deviation_reasons (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    code text UNIQUE NOT NULL,
    description text NOT NULL,
    category text NOT NULL DEFAULT 'general' CHECK (category IN ('labor', 'machinery', 'material', 'general')),
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.deviation_reasons ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on deviation_reasons"
    ON public.deviation_reasons FOR ALL TO authenticated
    USING (true) WITH CHECK (true);

-- Seed: motivos de desviación predefinidos
INSERT INTO public.deviation_reasons (code, description, category) VALUES
    ('ABSENCE', 'Ausencia justificada del trabajador', 'labor'),
    ('SUBSTITUTION', 'Sustitución por enfermedad o emergencia', 'labor'),
    ('REINFORCEMENT', 'Refuerzo por retraso en la tarea', 'labor'),
    ('BREAKDOWN', 'Avería de máquina titular', 'machinery'),
    ('TERRAIN', 'Condición de terreno imprevista', 'machinery'),
    ('URGENCY', 'Urgencia solicitada por el cliente', 'general'),
    ('WEATHER', 'Condiciones climáticas adversas', 'general'),
    ('OTHER', 'Otro motivo (especificar en notas)', 'general')
ON CONFLICT (code) DO NOTHING;


-- 2. Cabecera del reporte diario
CREATE TABLE IF NOT EXISTS public.daily_reports (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    report_date date NOT NULL DEFAULT CURRENT_DATE,
    supervisor_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    weather_condition text,
    general_notes text,
    evidence_photos jsonb DEFAULT '[]'::jsonb,
    signature_data text,
    status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
    approved_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Índice compuesto: un solo reporte por proyecto y fecha
CREATE UNIQUE INDEX IF NOT EXISTS idx_daily_reports_project_date
    ON public.daily_reports(project_id, report_date);

ALTER TABLE public.daily_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on daily_reports"
    ON public.daily_reports FOR ALL TO authenticated
    USING (true) WITH CHECK (true);


-- 3. Registro de jornada laboral diaria
CREATE TABLE IF NOT EXISTS public.report_labor_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    worker_id uuid NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    project_labor_id uuid REFERENCES public.project_labor(id) ON DELETE SET NULL,
    project_task_id uuid REFERENCES public.project_tasks(id) ON DELETE SET NULL,
    check_in_time time NOT NULL,
    check_out_time time,
    regular_hours numeric NOT NULL DEFAULT 0,
    overtime_hours numeric NOT NULL DEFAULT 0,
    is_unplanned boolean NOT NULL DEFAULT false,
    deviation_reason_id uuid REFERENCES public.deviation_reasons(id) ON DELETE SET NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.report_labor_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on report_labor_logs"
    ON public.report_labor_logs FOR ALL TO authenticated
    USING (true) WITH CHECK (true);


-- 4. Registro de producción diaria de maquinaria
CREATE TABLE IF NOT EXISTS public.report_machinery_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    machinery_id uuid NOT NULL REFERENCES public.machinery(id) ON DELETE CASCADE,
    project_machinery_id uuid REFERENCES public.project_machinery(id) ON DELETE SET NULL,
    operator_id uuid NOT NULL REFERENCES public.workers(id) ON DELETE CASCADE,
    start_meter numeric NOT NULL DEFAULT 0,
    end_meter numeric,
    total_hours numeric NOT NULL DEFAULT 0,
    fuel_added numeric NOT NULL DEFAULT 0,
    is_unplanned boolean NOT NULL DEFAULT false,
    deviation_reason_id uuid REFERENCES public.deviation_reasons(id) ON DELETE SET NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.report_machinery_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on report_machinery_logs"
    ON public.report_machinery_logs FOR ALL TO authenticated
    USING (true) WITH CHECK (true);


-- 5. Registro de consumo diario de materiales
CREATE TABLE IF NOT EXISTS public.report_material_usage (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    daily_report_id uuid NOT NULL REFERENCES public.daily_reports(id) ON DELETE CASCADE,
    material_id uuid NOT NULL REFERENCES public.materials(id) ON DELETE CASCADE,
    project_material_id uuid REFERENCES public.project_materials(id) ON DELETE SET NULL,
    quantity_used numeric NOT NULL DEFAULT 0,
    area_installed numeric,
    unit text,
    notes text,
    created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.report_material_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on report_material_usage"
    ON public.report_material_usage FOR ALL TO authenticated
    USING (true) WITH CHECK (true);


-- ── Trigger: actualizar updated_at en daily_reports ──
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON public.daily_reports;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON public.daily_reports
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();


-- Notificar a PostgREST para recargar el esquema
NOTIFY pgrst, 'reload schema';
