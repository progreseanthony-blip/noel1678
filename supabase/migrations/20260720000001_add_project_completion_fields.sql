-- Add project completion tracking fields
ALTER TABLE public.projects
ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS completed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS completion_notes TEXT;

-- Tell PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
