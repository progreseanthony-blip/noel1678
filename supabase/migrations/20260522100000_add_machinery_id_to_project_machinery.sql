-- Add catalog machinery reference to project_machinery for unplanned resources
ALTER TABLE project_machinery ADD COLUMN IF NOT EXISTS machinery_id UUID REFERENCES machinery(id);
