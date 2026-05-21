ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0;
ALTER TABLE project_labor ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0;
ALTER TABLE project_materials ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0;
ALTER TABLE project_instruments ADD COLUMN IF NOT EXISTS unplanned_cost numeric DEFAULT 0;
