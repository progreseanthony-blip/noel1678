-- Add missing columns to quotes table
alter table public.quotes 
add column if not exists client_name text,
add column if not exists total_amount numeric default 0,
add column if not exists quote_date date default current_date;

-- Add delivery_cost to quote_service_machineries
alter table public.quote_service_machineries 
add column if not exists delivery_cost numeric default 0;
