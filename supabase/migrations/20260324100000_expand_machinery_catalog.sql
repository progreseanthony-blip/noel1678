-- Migration: expand_machinery_catalog
-- Added on: March 24, 2026 (local timing)

-- Add new columns to machinery table
alter table public.machinery 
add column if not exists fuel_gallons numeric default 0,
add column if not exists capacity_yards numeric default 0,
add column if not exists trips_per_day numeric default 0,
add column if not exists yards_per_day numeric default 0,
add column if not exists machinery_type text default 'hauling',
add column if not exists associated_service_ids uuid[] default '{}',
add column if not exists applications text[] default '{}';

-- Optional: Create a table for managing known applications if we want to suggest them later
create table if not exists public.machinery_applications (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamp with time zone default now()
);

-- Policy for machinery_applications
alter table public.machinery_applications enable row level security;
do $$
begin
  if not exists (select 1 from pg_policies where policyname = 'Allow all actions for authenticated users on machinery_applications') then
    create policy "Allow all actions for authenticated users on machinery_applications"
      on public.machinery_applications for all to authenticated using (true);
  end if;
end $$;
