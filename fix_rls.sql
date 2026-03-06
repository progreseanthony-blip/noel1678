DROP POLICY IF EXISTS "Allow all actions for authenticated users on quotes" ON public.quotes;
DROP POLICY IF EXISTS "Allow all actions for authenticated users on quote_services" ON public.quote_services;
DROP POLICY IF EXISTS "Allow all actions for authenticated users on quote_service_machineries" ON public.quote_service_machineries;
DROP POLICY IF EXISTS "Allow all actions for authenticated users on quote_service_labors" ON public.quote_service_labors;

CREATE POLICY quotes_all ON public.quotes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY quote_services_all ON public.quote_services FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY quote_service_machineries_all ON public.quote_service_machineries FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY quote_service_labors_all ON public.quote_service_labors FOR ALL TO authenticated USING (true) WITH CHECK (true);
