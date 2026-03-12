-- 1. Ensure all missing columns in quotes table
ALTER TABLE public.quotes 
ADD COLUMN IF NOT EXISTS client_name text,
ADD COLUMN IF NOT EXISTS total_amount numeric default 0,
ADD COLUMN IF NOT EXISTS quote_date date default current_date,
ADD COLUMN IF NOT EXISTS project_name text;

-- 2. Ensure all missing columns in quote_services table
ALTER TABLE public.quote_services 
ADD COLUMN IF NOT EXISTS fuel_price numeric default 0,
ADD COLUMN IF NOT EXISTS per_diem_cost numeric default 0,
ADD COLUMN IF NOT EXISTS labor_hours_per_month numeric default 0;

-- 3. Ensure all missing columns in quote_service_machineries table
ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS delivery_cost numeric default 0;

-- 4. Ensure all missing columns in quote_service_labors table
ALTER TABLE public.quote_service_labors 
ADD COLUMN IF NOT EXISTS role_name text;

-- Notify PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
