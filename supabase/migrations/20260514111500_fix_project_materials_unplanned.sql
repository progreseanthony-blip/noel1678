-- Migration: Add unplanned flag to project materials
-- Description: Ensures project_materials also has the is_unplanned column for consistent baseline analysis.

ALTER TABLE public.project_materials 
ADD COLUMN IF NOT EXISTS is_unplanned BOOLEAN NOT NULL DEFAULT false;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
