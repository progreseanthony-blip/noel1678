-- Add quantity_received to instrument_inspections (batch reception support)
ALTER TABLE instrument_inspections
ADD COLUMN IF NOT EXISTS quantity_received INTEGER NOT NULL DEFAULT 1;

-- Add quantity field to material_receptions for consistency
ALTER TABLE material_receptions
ADD COLUMN IF NOT EXISTS quantity_received INTEGER NOT NULL DEFAULT 1;
