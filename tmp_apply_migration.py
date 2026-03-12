import psycopg2
import sys

sql = """
-- Update machinery table to include default trips per day
alter table public.machinery add column if not exists default_trips_per_day numeric not null default 60;

-- Create service estimations table
create table if not exists public.quote_service_estimations (
  id uuid primary key default uuid_generate_v4(),
  quote_service_id uuid not null references public.quote_services(id) on delete cascade,
  topsoil_volume numeric not null default 0,
  compacted_volume numeric not null default 0,
  swell_factor numeric not null default 0.15,
  total_cy_loose numeric not null default 0,
  start_date timestamp with time zone not null default now(),
  end_date timestamp with time zone,
  total_working_days numeric,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Create estimation resources table (to store specific config for this estimation)
create table if not exists public.quote_service_estimation_resources (
  id uuid primary key default uuid_generate_v4(),
  estimation_id uuid not null references public.quote_service_estimations(id) on delete cascade,
  machine_id uuid not null references public.machinery(id),
  quantity numeric not null default 1,
  trips_per_day numeric not null default 60,
  capacity_per_trip numeric not null default 30,
  created_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.quote_service_estimations enable row level security;
alter table public.quote_service_estimation_resources enable row level security;

-- Policies (using DO blocks to avoid errors if policies exist)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all actions for authenticated users on quote_service_estimations') THEN
        create policy "Allow all actions for authenticated users on quote_service_estimations"
          on public.quote_service_estimations for all to authenticated using (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow all actions for authenticated users on quote_service_estimation_resources') THEN
        create policy "Allow all actions for authenticated users on quote_service_estimation_resources"
          on public.quote_service_estimation_resources for all to authenticated using (true);
    END IF;
END
$$;

-- Trigger for updated_at
DROP TRIGGER IF EXISTS quote_service_estimations_updated_at ON public.quote_service_estimations;
create trigger quote_service_estimations_updated_at
  before update on public.quote_service_estimations
  for each row execute procedure public.handle_updated_at();
"""

try:
    conn = psycopg2.connect(
        dbname="postgres",
        user="postgres",
        password="postgres",
        host="localhost",
        port="54422"
    )
    conn.autocommit = True
    cur = conn.cursor()
    cur.execute(sql)
    print("Migration applied successfully")
    cur.close()
    conn.close()
except Exception as e:
    print(f"Error: {e}")
    sys.exit(1)
