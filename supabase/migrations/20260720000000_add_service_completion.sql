ALTER TABLE quote_services
  ADD COLUMN completion_status TEXT DEFAULT 'pending'
    CHECK (completion_status IN ('pending', 'in_progress', 'completed')),
  ADD COLUMN completion_pct NUMERIC DEFAULT 0,
  ADD COLUMN completed_at TIMESTAMPTZ,
  ADD COLUMN completed_by UUID REFERENCES auth.users(id);
