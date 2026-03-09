-- Allow all access to catalogs for anon users in local dev
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon;

-- Ensure RLS doesn't block local anon users for common tables
ALTER TABLE public.labor_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.machinery DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.services DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles DISABLE ROW LEVEL SECURITY;
