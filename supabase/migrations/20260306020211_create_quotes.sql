-- 1. Create Quotes Table
create table public.quotes (
  id uuid primary key default uuid_generate_v4(),
  company_id uuid, -- Assuming some company reference might be needed later
  title text not null default 'Nueva Cotización',
  status text not null default 'draft', -- draft, sent, accepted, rejected
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. Create Quote Services Table (The items in the quote)
create table public.quote_services (
  id uuid primary key default uuid_generate_v4(),
  quote_id uuid not null references public.quotes(id) on delete cascade,
  service_number text,
  name text not null default '',
  unit_of_measure text not null default 'und',
  quantity numeric not null default 1,
  overhead_percentage numeric not null default 0,
  profit_percentage numeric not null default 0,
  created_at timestamp with time zone default now()
);

-- 3. Create Quote Service Machineries (The machines for a service)
create table public.quote_service_machineries (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  machine_name text not null default '',
  months_to_use numeric not null default 0,
  monthly_rent_cost numeric not null default 0,
  quantity numeric not null default 1,
  gallons_per_hour numeric not null default 0,
  gallon_cost numeric not null default 0,
  created_at timestamp with time zone default now()
);

-- 4. Create Quote Service Labors (The labor for a service)
create table public.quote_service_labors (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  role_id uuid references public.roles(id), -- Nullable in case they want a free text option later
  months_to_work numeric not null default 0,
  employees_quantity numeric not null default 1,
  hourly_rate numeric not null default 0,
  per_diem numeric not null default 0,
  created_at timestamp with time zone default now()
);

-- Enforce Row Level Security (RLS)
alter table public.quotes enable row level security;
alter table public.quote_services enable row level security;
alter table public.quote_service_machineries enable row level security;
alter table public.quote_service_labors enable row level security;

-- Policies for Authenticated Users (Admins usually handle this)
-- For now, allow authenticated users to do everything (you can restrict later)
create policy "Allow all actions for authenticated users on quotes"
  on public.quotes for all to authenticated using (true);
  
create policy "Allow all actions for authenticated users on quote_services"
  on public.quote_services for all to authenticated using (true);
  
create policy "Allow all actions for authenticated users on quote_service_machineries"
  on public.quote_service_machineries for all to authenticated using (true);
  
create policy "Allow all actions for authenticated users on quote_service_labors"
  on public.quote_service_labors for all to authenticated using (true);
