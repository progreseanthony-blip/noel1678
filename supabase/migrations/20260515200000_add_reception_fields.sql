-- Add new fields to machinery_inspections
ALTER TABLE machinery_inspections
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE,
  ADD COLUMN IF NOT EXISTS internal_id TEXT,
  ADD COLUMN IF NOT EXISTS odometer_unit TEXT NOT NULL DEFAULT 'hours'; -- 'hours' or 'miles'

-- Add reception_date to material_receptions
ALTER TABLE material_receptions
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE;

-- Add reception_date to instrument_inspections
ALTER TABLE instrument_inspections
  ADD COLUMN IF NOT EXISTS reception_date DATE NOT NULL DEFAULT CURRENT_DATE;
