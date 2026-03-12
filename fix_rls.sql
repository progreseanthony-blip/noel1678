-- Enable RLS
ALTER TABLE public.quote_service_estimations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quote_service_estimation_resources ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Allow all actions for authenticated users on quote_service_estimations" ON public.quote_service_estimations;
DROP POLICY IF EXISTS "Allow all actions for authenticated users on quote_service_estimation_resources" ON public.quote_service_estimation_resources;

-- Create new policies with WITH CHECK
CREATE POLICY "Allow all actions for authenticated users on quote_service_estimations"
ON public.quote_service_estimations
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);

CREATE POLICY "Allow all actions for authenticated users on quote_service_estimation_resources"
ON public.quote_service_estimation_resources
FOR ALL
TO authenticated
USING (true)
WITH CHECK (true);
