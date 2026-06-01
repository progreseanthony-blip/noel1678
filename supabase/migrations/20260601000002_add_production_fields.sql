-- Agrega campos de producción a reportes de maquinaria
ALTER TABLE public.report_machinery_logs
  ADD COLUMN IF NOT EXISTS production_value numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS production_unit text;

NOTIFY pgrst, 'reload schema';
