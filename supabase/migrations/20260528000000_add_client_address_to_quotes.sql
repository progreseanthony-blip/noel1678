-- Add client_address column to quotes table
ALTER TABLE public.quotes ADD COLUMN IF NOT EXISTS client_address text;
