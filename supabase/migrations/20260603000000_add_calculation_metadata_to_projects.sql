-- Agrega calculation_metadata a projects para guardar baseline y otra metadata
ALTER TABLE public.projects ADD COLUMN IF NOT EXISTS calculation_metadata JSONB;

NOTIFY pgrst, 'reload schema';
