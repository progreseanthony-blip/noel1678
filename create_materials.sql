CREATE TABLE public.project_materials (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id uuid NOT NULL REFERENCES public.projects(id) ON DELETE CASCADE,
    quote_service_material_id uuid REFERENCES public.quote_service_materials(id) ON DELETE SET NULL,
    material_name text NOT NULL,
    unit_name text,
    expected_quantity numeric NOT NULL DEFAULT 0,
    received_quantity numeric NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.project_materials ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on project_materials" ON public.project_materials FOR ALL TO authenticated USING (true) WITH CHECK (true);

CREATE TABLE public.material_receptions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    project_material_id uuid NOT NULL REFERENCES public.project_materials(id) ON DELETE CASCADE,
    received_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    invoice_number text,
    provider_name text,
    quantity_received numeric NOT NULL,
    condition_status text DEFAULT 'good' CHECK (condition_status IN ('good', 'damaged', 'incomplete')),
    observations text,
    evidence_photos jsonb DEFAULT '[]'::jsonb,
    received_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.material_receptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Enable all access for authenticated users on material_receptions" ON public.material_receptions FOR ALL TO authenticated USING (true) WITH CHECK (true);

-- Script to backfill project_materials for existing projects
INSERT INTO public.project_materials (project_id, quote_service_material_id, material_name, unit_name, expected_quantity, received_quantity)
SELECT 
    p.id as project_id,
    qsm.id as quote_service_material_id,
    qsm.material_name,
    qsm.unit_name,
    qsm.quantity as expected_quantity,
    0 as received_quantity
FROM public.projects p
JOIN public.quote_services qs ON qs.quote_id = p.quote_id
JOIN public.quote_service_materials qsm ON qsm.quote_service_id = qs.id
WHERE NOT EXISTS (
    SELECT 1 FROM public.project_materials pm WHERE pm.project_id = p.id
);

-- Tell PostgREST to reload schema cache
NOTIFY pgrst, 'reload schema';
