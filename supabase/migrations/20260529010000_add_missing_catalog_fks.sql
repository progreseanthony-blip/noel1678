-- ============================================================================
-- Agrega FKs faltantes para que PostgREST pueda resolver relaciones embebidas
-- necesarias para el módulo de Daily Reports
-- ============================================================================

-- FK: project_labor.role_id → labor_roles.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'project_labor_role_id_fkey'
  ) THEN
    ALTER TABLE public.project_labor
      ADD CONSTRAINT project_labor_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.labor_roles(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- FK: project_machinery.machinery_id → machinery.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'project_machinery_machinery_id_fkey'
  ) THEN
    ALTER TABLE public.project_machinery
      ADD CONSTRAINT project_machinery_machinery_id_fkey
      FOREIGN KEY (machinery_id) REFERENCES public.machinery(id)
      ON DELETE SET NULL;
  END IF;
END $$;

NOTIFY pgrst, 'reload schema';
