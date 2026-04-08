-- Create Workers Table
create table if not exists public.workers (
  id uuid primary key default uuid_generate_v4(),
  id_number text unique, -- Cédula/ID
  full_name text not null,
  hire_date date,
  phone text,
  email text,
  status text not null default 'Active', -- Active / Inactive
  role_id uuid references public.labor_roles(id) on delete set null,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create Worker Role History Table
create table if not exists public.worker_role_history (
  id uuid primary key default uuid_generate_v4(),
  worker_id uuid references public.workers(id) on delete cascade not null,
  previous_role_id uuid references public.labor_roles(id) on delete set null,
  new_role_id uuid references public.labor_roles(id) on delete set null,
  previous_hourly_rate numeric,
  changed_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.workers enable row level security;
alter table public.worker_role_history enable row level security;

-- Policies
create policy "Allow all actions for authenticated users on workers"
  on public.workers for all to authenticated using (true);

create policy "Allow all actions for authenticated users on worker_role_history"
  on public.worker_role_history for all to authenticated using (true);

-- Updated_at trigger for workers
create trigger workers_updated_at
  before update on public.workers
  for each row execute procedure public.handle_updated_at();

-- Trigger to automatically track role changes
create or replace function public.handle_worker_role_change()
returns trigger as $$
declare
  prev_rate numeric;
begin
  if (TG_OP = 'UPDATE' and old.role_id is distinct from new.role_id) then
    -- Get previous hourly rate
    select hourly_rate into prev_rate from public.labor_roles where id = old.role_id;
    
    insert into public.worker_role_history (worker_id, previous_role_id, new_role_id, previous_hourly_rate)
    values (new.id, old.role_id, new.role_id, prev_rate);
  end if;
  return new;
end;
$$ language plpgsql;

create trigger track_worker_role_changes
  after update on public.workers
  for each row execute procedure public.handle_worker_role_change();
