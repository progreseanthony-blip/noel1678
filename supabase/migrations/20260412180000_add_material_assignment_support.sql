-- Migration: Add material assignment support to quotes
-- Date: 2026-04-12
-- Branch: feat/agregar-material

-- 1. Extend materials catalog with yield tracking
ALTER TABLE materials ADD COLUMN IF NOT EXISTS yield_factor decimal DEFAULT 1.0;
COMMENT ON COLUMN materials.yield_factor IS 'Units of material per unit of estimated volume (CY) or Area (SQFT)';

-- 2. Create the materials assignment table for quotes
CREATE TABLE IF NOT EXISTS quote_service_materials (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_service_id uuid NOT NULL REFERENCES quote_services(id) ON DELETE CASCADE,
    material_id uuid REFERENCES materials(id) ON DELETE SET NULL,
    quantity decimal NOT NULL DEFAULT 0,
    unit_price decimal NOT NULL DEFAULT 0,
    total_cost decimal GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 3. Security: Enable RLS
ALTER TABLE quote_service_materials ENABLE ROW LEVEL SECURITY;

-- 4. Policies: Allow full access to authenticated users (consistent with other tables in this project)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for quote_service_materials'
    ) THEN
        CREATE POLICY "Enable all access for quote_service_materials" ON quote_service_materials
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$;

-- 5. Helper trigger for updated_at
CREATE OR REPLACE TRIGGER update_quote_service_materials_modtime
    BEFORE UPDATE ON quote_service_materials
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();
