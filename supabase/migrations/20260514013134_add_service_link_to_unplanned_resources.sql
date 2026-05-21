-- Add service link to unplanned resources
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id);
ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id);
ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id);
ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS quote_service_id UUID REFERENCES quote_services(id);

-- Add metadata for complex cost calculations
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS calculation_metadata JSONB;
ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS calculation_metadata JSONB;
ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS calculation_metadata JSONB;
ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS calculation_metadata JSONB;
