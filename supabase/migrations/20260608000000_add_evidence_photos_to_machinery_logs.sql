ALTER TABLE public.report_machinery_logs
  ADD COLUMN IF NOT EXISTS evidence_photos jsonb DEFAULT '[]'::jsonb NOT NULL;

NOTIFY pgrst, 'reload schema';
