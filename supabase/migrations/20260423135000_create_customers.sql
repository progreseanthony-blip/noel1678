-- Create Customers Table
create table public.customers (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  ein text, -- Format: XX-XXXXXXX
  address text,
  phone text,
  email text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- Enable RLS
alter table public.customers enable row level security;

-- Policies
create policy "Allow all actions for authenticated users on customers"
  on public.customers for all to authenticated using (true);
