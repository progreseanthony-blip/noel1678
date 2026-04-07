-- Migration: add_hierarchy_to_quote_machinery
-- Added on: April 5, 2026

alter table public.quote_service_machineries
add column if not exists parent_machinery_id uuid references public.quote_service_machineries(id) on delete cascade,
add column if not exists is_primary boolean not null default true;

-- Trigger schema reload
notify pgrst, 'reload schema';
