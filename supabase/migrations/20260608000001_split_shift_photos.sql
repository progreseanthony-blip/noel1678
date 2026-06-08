ALTER TABLE public.report_machinery_logs 
  RENAME COLUMN evidence_photos TO start_shift_photos;

ALTER TABLE public.report_machinery_logs 
  ADD COLUMN IF NOT EXISTS end_shift_photos jsonb DEFAULT '[]'::jsonb NOT NULL;

NOTIFY pgrst, 'reload schema';
