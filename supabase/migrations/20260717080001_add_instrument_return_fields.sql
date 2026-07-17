ALTER TABLE instrument_inspections
  ADD COLUMN returned_at timestamptz,
  ADD COLUMN return_condition_status text,
  ADD COLUMN return_observations text,
  ADD COLUMN return_evidence_photos jsonb default '[]'::jsonb,
  ADD COLUMN return_damages jsonb default '[]'::jsonb,
  ADD COLUMN return_cleanliness text,
  ADD COLUMN returned_by uuid references auth.users(id);
