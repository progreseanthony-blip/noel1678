ALTER TABLE public.quote_services 
  ADD COLUMN IF NOT EXISTS target_price numeric DEFAULT 0;
