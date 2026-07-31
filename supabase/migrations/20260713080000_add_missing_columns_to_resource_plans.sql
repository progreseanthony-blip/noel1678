-- Add columns missing from change_order_resource_plans that the code inserts

ALTER TABLE public.change_order_resource_plans
  ADD COLUMN IF NOT EXISTS monthly_rent_cost numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS delivery_cost numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS months_to_use numeric DEFAULT 1,
  ADD COLUMN IF NOT EXISTS months_to_work numeric DEFAULT 1,
  ADD COLUMN IF NOT EXISTS hourly_rate numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS per_diem numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS employees_quantity numeric DEFAULT 1,
  ADD COLUMN IF NOT EXISTS days numeric DEFAULT 1,
  ADD COLUMN IF NOT EXISTS daily_rate numeric DEFAULT 0;
