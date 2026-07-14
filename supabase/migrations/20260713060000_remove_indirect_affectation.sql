-- Remove 'indirect' from affectation_type check constraint
ALTER TABLE public.change_order_disruption_services
  DROP CONSTRAINT IF EXISTS change_order_disruption_services_affectation_type_check;

UPDATE public.change_order_disruption_services
  SET affectation_type = 'partial'
  WHERE affectation_type = 'indirect';

ALTER TABLE public.change_order_disruption_services
  ADD CONSTRAINT change_order_disruption_services_affectation_type_check
  CHECK (affectation_type IN ('total_stop', 'partial'));
