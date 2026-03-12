-- Add role_name column to quote_service_labors
alter table public.quote_service_labors 
add column if not exists role_name text;
