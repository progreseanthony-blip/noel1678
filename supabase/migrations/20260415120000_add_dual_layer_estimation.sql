-- Add support for dual-layer estimation (Earth + Gravel) for area-based services
-- The existing 'thickness_inches' column represents the Earth layer thickness
-- The new 'gravel_thickness_inches' column represents the Gravel layer thickness

ALTER TABLE public.quote_service_estimations 
ADD COLUMN IF NOT EXISTS gravel_thickness_inches numeric DEFAULT 0;

-- Add layer_type to materials so each material knows which calculation layer to use
ALTER TABLE public.quote_service_materials 
ADD COLUMN IF NOT EXISTS layer_type text DEFAULT 'earth';

COMMENT ON COLUMN public.quote_service_estimations.thickness_inches 
  IS 'Earth layer thickness in inches for SQFT-based calculations';
COMMENT ON COLUMN public.quote_service_estimations.gravel_thickness_inches 
  IS 'Gravel layer thickness in inches for SQFT-based calculations';
COMMENT ON COLUMN public.quote_service_materials.layer_type 
  IS 'Which calculation layer this material belongs to: earth or gravel';

NOTIFY pgrst, 'reload schema';
