-- Fix: align disruption_type CHECK constraint with disruption_reasons.code values
DO $$
BEGIN
  ALTER TABLE public.change_order_disruptions
    DROP CONSTRAINT IF EXISTS change_order_disruptions_disruption_type_check;

  ALTER TABLE public.change_order_disruptions
    ADD CONSTRAINT change_order_disruptions_disruption_type_check
    CHECK (disruption_type IN (
      'PENDING_PERMIT','EXTERNAL_DEP','OWNER_DELAY',
      'WEATHER_RAIN','WEATHER_OTHER','DESIGN_CHANGE',
      'MATERIAL_DELAY','MATERIAL_DAMAGE','SITE_ACCESS',
      'UTILITY_LOCATE','OTHER'
    ));
END $$;
