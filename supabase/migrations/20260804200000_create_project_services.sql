-- ============================================================
-- Migration: Separar servicios de CO de quote_services
-- Tabla project_services — servicios al nivel del proyecto
-- quote_services = estimación baseline (read-only, nunca se modifica por COs)
-- project_services = versión viva del proyecto (creada/modificada por COs)
-- ============================================================

-- 1. Crear tabla project_services
CREATE TABLE IF NOT EXISTS public.project_services (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id       uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
  quote_service_id uuid REFERENCES public.quote_services(id) ON DELETE SET NULL,
  name             text NOT NULL,
  unit_of_measure  text NOT NULL DEFAULT 'und',
  quantity         numeric NOT NULL DEFAULT 0,
  direct_cost      numeric NOT NULL DEFAULT 0,
  target_price     numeric DEFAULT 0,
  source_co_id     uuid REFERENCES public.change_orders(id) ON DELETE SET NULL,
  created_at       timestamptz DEFAULT now()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_project_services_project ON public.project_services(project_id);
CREATE INDEX IF NOT EXISTS idx_project_services_quote ON public.project_services(quote_service_id);
CREATE INDEX IF NOT EXISTS idx_project_services_co ON public.project_services(source_co_id);

-- RLS
ALTER TABLE public.project_services ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated full access" ON public.project_services
  FOR ALL TO authenticated
  USING (true)
  WITH CHECK (true);

-- 2. Nueva columna project_service_id en tablas de recursos
ALTER TABLE public.project_labor
  ADD COLUMN IF NOT EXISTS project_service_id uuid REFERENCES public.project_services(id) ON DELETE SET NULL;

ALTER TABLE public.project_machinery
  ADD COLUMN IF NOT EXISTS project_service_id uuid REFERENCES public.project_services(id) ON DELETE SET NULL;

ALTER TABLE public.project_materials
  ADD COLUMN IF NOT EXISTS project_service_id uuid REFERENCES public.project_services(id) ON DELETE SET NULL;

ALTER TABLE public.project_instruments
  ADD COLUMN IF NOT EXISTS project_service_id uuid REFERENCES public.project_services(id) ON DELETE SET NULL;

ALTER TABLE public.project_tasks
  ADD COLUMN IF NOT EXISTS project_service_id uuid REFERENCES public.project_services(id) ON DELETE SET NULL;

-- 3. Nueva columna en change_order_details
ALTER TABLE public.change_order_details
  ADD COLUMN IF NOT EXISTS project_service_id uuid
  REFERENCES public.project_services(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_co_details_project_service ON public.change_order_details(project_service_id);
