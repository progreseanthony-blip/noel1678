-- Add estimation_metadata jsonb column to change_order_details
ALTER TABLE public.change_order_details
  ADD COLUMN IF NOT EXISTS estimation_metadata jsonb;
