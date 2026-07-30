-- Add co_number column to invoice_details for proper CO grouping on load
ALTER TABLE public.invoice_details
  ADD COLUMN IF NOT EXISTS co_number TEXT;
