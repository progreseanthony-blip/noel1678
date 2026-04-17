-- Migration: Add instruments assignment support to quotes
-- Date: 2026-04-15
-- Description: Creates the quote_service_instruments table to store manually added instruments/tools from the logistics catalog.

-- 1. Create the instruments assignment table for quotes
CREATE TABLE IF NOT EXISTS public.quote_service_instruments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    quote_service_id uuid NOT NULL REFERENCES quote_services(id) ON DELETE CASCADE,
    instrument_id uuid REFERENCES logistics_equipment(id) ON DELETE SET NULL,
    instrument_name text, -- Persist name for history
    quantity decimal NOT NULL DEFAULT 1,
    unit_price decimal NOT NULL DEFAULT 0,
    total_cost decimal GENERATED ALWAYS AS (quantity * unit_price) STORED,
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- 2. Security: Enable RLS
ALTER TABLE public.quote_service_instruments ENABLE ROW LEVEL SECURITY;

-- 3. Policies: Allow full access for authenticated users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for quote_service_instruments'
    ) THEN
        CREATE POLICY "Enable all access for quote_service_instruments" ON public.quote_service_instruments
        FOR ALL USING (true) WITH CHECK (true);
    END IF;
END
$$;

-- 4. Helper trigger for updated_at
DROP TRIGGER IF EXISTS update_quote_service_instruments_modtime ON public.quote_service_instruments;
CREATE TRIGGER update_quote_service_instruments_modtime
    BEFORE UPDATE ON public.quote_service_instruments
    FOR EACH ROW
    EXECUTE FUNCTION handle_updated_at();
