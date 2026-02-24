-- Create roles table
create table if not exists public.roles (
  id uuid default gen_random_uuid() primary key,
  name text not null unique,
  description text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.roles enable row level security;

-- Everyone can read roles
create policy "Roles are viewable by everyone." on public.roles
  for select using (true);

-- Only authenticated users can manage roles
create policy "Authenticated users can insert roles." on public.roles
  for insert with check (auth.role() = 'authenticated');

create policy "Authenticated users can update roles." on public.roles
  for update using (auth.role() = 'authenticated');

create policy "Authenticated users can delete roles." on public.roles
  for delete using (auth.role() = 'authenticated');

-- Seed default roles
insert into public.roles (name, description) values
  ('Admin', 'Full access to all features'),
  ('Employee', 'Standard employee access')
on conflict (name) do nothing;

-- Remove the check constraint on profiles.role so it can accept any role
alter table public.profiles drop constraint if exists profiles_role_check;
