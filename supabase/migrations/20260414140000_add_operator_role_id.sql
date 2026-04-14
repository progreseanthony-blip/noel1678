ALTER TABLE public.machinery 
ADD COLUMN IF NOT EXISTS operator_role_id uuid REFERENCES public.labor_roles(id);

-- Force reload the schema cache for the API
NOTIFY pgrst, 'reload schema';
