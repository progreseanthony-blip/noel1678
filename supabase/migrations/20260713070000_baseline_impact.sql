-- ============================================================
-- Migration: Baseline Impact para Scope Change COs
-- source_co_id en recursos + tabla change_order_resource_plans
-- ============================================================

-- 1. source_co_id en tablas de recursos del proyecto
ALTER TABLE public.project_labor
  ADD COLUMN IF NOT EXISTS source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

ALTER TABLE public.project_machinery
  ADD COLUMN IF NOT EXISTS source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

ALTER TABLE public.project_materials
  ADD COLUMN IF NOT EXISTS source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

ALTER TABLE public.project_instruments
  ADD COLUMN IF NOT EXISTS source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

-- 2. source_co_id en quote_services (para servicios nuevos creados vía CO)
ALTER TABLE public.quote_services
  ADD COLUMN IF NOT EXISTS source_co_id UUID REFERENCES public.change_orders(id) ON DELETE SET NULL;

-- 3. Tabla de ajustes planeados (antes de aprobación)
CREATE TABLE IF NOT EXISTS public.change_order_resource_plans (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  change_order_detail_id uuid NOT NULL REFERENCES public.change_order_details(id) ON DELETE CASCADE,
  resource_type text NOT NULL CHECK (resource_type IN ('labor', 'machinery', 'material', 'instrument')),

  -- Para ajuste proporcional sobre servicio existente
  proportional_factor numeric,

  -- Para recursos explícitos (servicio nuevo o ajuste manual)
  catalog_id uuid,
  resource_name text NOT NULL DEFAULT '',
  quantity numeric NOT NULL DEFAULT 1,
  unit text,
  unit_cost numeric DEFAULT 0,
  monthly_cost numeric,
  is_principal boolean DEFAULT true,
  parent_resource_name text,
  hours_per_day numeric,
  fuel_gph numeric,
  fuel_price numeric,
  trips_per_day numeric,
  capacity_per_trip numeric,
  performance_per_day numeric,
  calculation_metadata jsonb,

  notes text,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.change_order_resource_plans ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Enable all access for authenticated users on change_order_resource_plans'
  ) THEN
    CREATE POLICY "Enable all access for authenticated users on change_order_resource_plans"
      ON public.change_order_resource_plans FOR ALL TO authenticated
      USING (true) WITH CHECK (true);
  END IF;
END
$$;
