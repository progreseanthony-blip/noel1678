-- Create Labor Roles Catalog
create table if not exists public.labor_roles (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  hourly_rate numeric not null default 0,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create Machinery Catalog
create table if not exists public.machinery (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  photo_url text,
  capacity text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create Services Catalog
create table if not exists public.services (
  id uuid primary key default uuid_generate_v4(),
  description text not null,
  unit text not null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.labor_roles enable row level security;
alter table public.machinery enable row level security;
alter table public.services enable row level security;

-- Policies (Allow all for authenticated users for now)
create policy "Allow all actions for authenticated users on labor_roles"
  on public.labor_roles for all to authenticated using (true);

create policy "Allow all actions for authenticated users on machinery"
  on public.machinery for all to authenticated using (true);

create policy "Allow all actions for authenticated users on services"
  on public.services for all to authenticated using (true);

-- Trigger for updated_at
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger labor_roles_updated_at
  before update on public.labor_roles
  for each row execute procedure public.handle_updated_at();

create trigger machinery_updated_at
  before update on public.machinery
  for each row execute procedure public.handle_updated_at();

create trigger services_updated_at
  before update on public.services
  for each row execute procedure public.handle_updated_at();
