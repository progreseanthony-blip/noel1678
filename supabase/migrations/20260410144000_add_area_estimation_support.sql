-- Add support for Area-based (FT) estimation
ALTER TABLE public.quote_service_estimations 
ADD COLUMN IF NOT EXISTS thickness_inches numeric DEFAULT 0;

ALTER TABLE public.quote_service_estimation_resources
ADD COLUMN IF NOT EXISTS performance_per_day numeric DEFAULT 0;

-- Optional: Add a comment to explain the columns
COMMENT ON COLUMN public.quote_service_estimations.thickness_inches IS 'Thickness in inches for SQFT based calculations';
COMMENT ON COLUMN public.quote_service_estimation_resources.performance_per_day IS 'Machine performance in Units/Day (e.g. SQFT/Day if unit is FT)';
