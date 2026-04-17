-- Add days column to quote_service_instruments
ALTER TABLE public.quote_service_instruments 
ADD COLUMN days decimal NOT NULL DEFAULT 1;

-- Update generated column calculation
ALTER TABLE public.quote_service_instruments 
DROP COLUMN total_cost;

ALTER TABLE public.quote_service_instruments 
ADD COLUMN total_cost decimal GENERATED ALWAYS AS (quantity * unit_price * days) STORED;
