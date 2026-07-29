ALTER TABLE public.change_order_resource_plans
  ADD COLUMN IF NOT EXISTS unit_price numeric DEFAULT 0;
