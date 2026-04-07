-- Add hierarchy columns to quote_service_machineries
ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS is_primary_mover BOOLEAN DEFAULT TRUE;

ALTER TABLE public.quote_service_machineries 
ADD COLUMN IF NOT EXISTS parent_machine_name VARCHAR;

-- Update foreign keys to CASCADE ON DELETE
ALTER TABLE quote_service_estimations DROP CONSTRAINT IF EXISTS quote_service_estimations_quote_service_id_fkey;
ALTER TABLE quote_service_estimations ADD CONSTRAINT quote_service_estimations_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE;

ALTER TABLE quote_service_machineries DROP CONSTRAINT IF EXISTS quote_service_machineries_quote_service_id_fkey;
ALTER TABLE quote_service_machineries ADD CONSTRAINT quote_service_machineries_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE;

ALTER TABLE quote_service_labors DROP CONSTRAINT IF EXISTS quote_service_labors_quote_service_id_fkey;
ALTER TABLE quote_service_labors ADD CONSTRAINT quote_service_labors_quote_service_id_fkey FOREIGN KEY (quote_service_id) REFERENCES quote_services(id) ON DELETE CASCADE;

ALTER TABLE quote_service_estimation_resources DROP CONSTRAINT IF EXISTS quote_service_estimation_resources_estimation_id_fkey;
ALTER TABLE quote_service_estimation_resources ADD CONSTRAINT quote_service_estimation_resources_estimation_id_fkey FOREIGN KEY (estimation_id) REFERENCES quote_service_estimations(id) ON DELETE CASCADE;

-- Trigger schema reload
NOTIFY pgrst, 'reload schema';
