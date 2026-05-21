-- Migration: Create Instrument Inspections Table
-- Description: Adds the instrument_inspections table for tracking individual instrument reception records

CREATE TABLE IF NOT EXISTS public.instrument_inspections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_instrument_id UUID NOT NULL REFERENCES public.project_instruments(id) ON DELETE CASCADE,
    internal_code TEXT,
    brand_model TEXT,
    ownership_type TEXT DEFAULT 'owned' CHECK (ownership_type IN ('owned', 'rented')),
    condition_status TEXT DEFAULT 'operational' CHECK (condition_status IN ('operational', 'needs_maintenance', 'damaged')),
    evidence_photos JSONB DEFAULT '[]'::jsonb,
    observations TEXT,
    quantity_received INTEGER NOT NULL DEFAULT 1,
    reception_date DATE NOT NULL DEFAULT CURRENT_DATE,
    received_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    received_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

-- RLS
ALTER TABLE public.instrument_inspections ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policy WHERE polname = 'Enable all access for instrument_inspections'
    ) THEN
        CREATE POLICY "Enable all access for instrument_inspections" ON public.instrument_inspections
        FOR ALL USING (auth.role() = 'authenticated') WITH CHECK (auth.role() = 'authenticated');
    END IF;
END
$$;
