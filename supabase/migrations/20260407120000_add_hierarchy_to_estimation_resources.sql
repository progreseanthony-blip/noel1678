-- Add hierarchy support to estimation resources
-- is_primary_mover: true = primary mover (counts in calculation & calendar)
-- parent_resource_id: UUID of primary machine this support belongs to

ALTER TABLE quote_service_estimation_resources
  ADD COLUMN IF NOT EXISTS is_primary_mover BOOLEAN NOT NULL DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS parent_resource_id UUID REFERENCES quote_service_estimation_resources(id) ON DELETE SET NULL;
