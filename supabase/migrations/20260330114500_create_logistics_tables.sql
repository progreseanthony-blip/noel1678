-- Migration: create_logistics_tables
-- Added on: March 30, 2026

-- 1. Create table for logistics equipment
create table if not exists public.logistics_equipment (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  photo_url text,
  associated_service_ids uuid[] default '{}',
  applications text[] default '{}',
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. Create table for logistics applications
create table if not exists public.logistics_applications (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamp with time zone default now()
);

-- 3. Enable RLS
alter table public.logistics_equipment enable row level security;
alter table public.logistics_applications enable row level security;

-- 4. Create Policies
do $$
begin
  -- Policies for logistics_equipment
  if not exists (select 1 from pg_policies where policyname = 'Allow all actions for authenticated users on logistics_equipment') then
    create policy "Allow all actions for authenticated users on logistics_equipment"
      on public.logistics_equipment for all to authenticated using (true);
  end if;

  -- Policies for logistics_applications
  if not exists (select 1 from pg_policies where policyname = 'Allow all actions for authenticated users on logistics_applications') then
    create policy "Allow all actions for authenticated users on logistics_applications"
      on public.logistics_applications for all to authenticated using (true);
  end if;
end $$;

-- 5. Notify schema reload
notify pgrst, 'reload schema';
