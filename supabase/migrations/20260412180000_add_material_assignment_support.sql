-- Migration: Add material assignment support to quotes
-- Date: 2026-04-12
-- Branch: feat/agregar-material

-- 1. Create materials catalog table if not exists (Ensures remote DB compatibility)
CREATE TABLE IF NOT EXISTS public.materials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    description text NOT NULL DEFAULT '',
    unit text,
    yield_factor decimal DEFAULT 1.0,
    associated_service_ids uuid[] DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Enable RLS for materials
ALTER TABLE public.materials ENABLE ROW LEVEL SECURITY;

-- Policy for materials
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for materials'
    ) THEN
        CREATE POLICY "Enable all access for materials" ON public.materials
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$;

-- 2. Create the materials assignment table for quotes
CREATE TABLE IF NOT EXISTS public.quote_service_materials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_service_id uuid NOT NULL REFERENCES quote_services(id) ON DELETE CASCADE,
    material_id uuid REFERENCES materials(id) ON DELETE SET NULL,
    material_name text, -- Persist name for history
    unit_name text,     -- Persist unit for history
    quantity decimal NOT NULL DEFAULT 0,
    unit_price decimal NOT NULL DEFAULT 0,
    total_cost decimal GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 3. Security: Enable RLS
ALTER TABLE public.quote_service_materials ENABLE ROW LEVEL SECURITY;

-- 4. Policies: Allow full access
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for quote_service_materials'
    ) THEN
        CREATE POLICY "Enable all access for quote_service_materials" ON public.quote_service_materials
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$;

-- 5. Helper triggers for updated_at (Uses handle_updated_at from previous migrations)
CREATE OR REPLACE TRIGGER update_materials_modtime
    BEFORE UPDATE ON public.materials
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();

CREATE OR REPLACE TRIGGER update_quote_service_materials_modtime
    BEFORE UPDATE ON public.quote_service_materials
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();
