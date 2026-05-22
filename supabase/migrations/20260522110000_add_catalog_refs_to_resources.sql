-- Add catalog reference columns for unplanned resources
ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS role_id UUID REFERENCES labor_roles(id);
ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS material_id UUID REFERENCES materials(id);
ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS instrument_id UUID REFERENCES logistics_equipment(id);
