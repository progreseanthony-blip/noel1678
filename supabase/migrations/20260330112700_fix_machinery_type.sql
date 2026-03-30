-- Final fix for missing machinery columns
-- This ensures the column exists even if the previous migration was skipped or marked as completed

alter table public.machinery 
add column if not exists machinery_type text default 'hauling';

-- Trigger schema reload just in case
notify pgrst, 'reload schema';
