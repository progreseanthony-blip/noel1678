-- Migration: enable_work_groups
-- Added on: April 5, 2026

-- Add category to machinery catalog
alter table public.machinery 
add column if not exists machinery_category text not null default 'support' 
check (machinery_category in ('transport', 'support', 'dual'));

-- Update existing hauling machines to transport for consistency
update public.machinery set machinery_category = 'transport' where machinery_type = 'hauling';
update public.machinery set machinery_category = 'support' where machinery_type = 'support';
update public.machinery set machinery_category = 'dual' where machinery_type = 'production';

-- Add group relationship to estimation resources
alter table public.quote_service_estimation_resources
add column if not exists parent_resource_id uuid references public.quote_service_estimation_resources(id) on delete cascade,
add column if not exists is_primary_mover boolean not null default false;

-- Trigger schema reload
notify pgrst, 'reload schema';
