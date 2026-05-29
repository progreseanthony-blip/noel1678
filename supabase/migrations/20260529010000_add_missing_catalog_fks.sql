-- ============================================================================
-- Agrega FKs faltantes para que PostgREST pueda resolver relaciones embebidas
-- necesarias para el módulo de Daily Reports
-- ============================================================================

-- FK: project_labor.role_id → labor_roles.id
ALTER TABLE public.project_labor
  ADD CONSTRAINT project_labor_role_id_fkey
  FOREIGN KEY (role_id) REFERENCES public.labor_roles(id)
  ON DELETE SET NULL;

-- FK: project_machinery.machinery_id → machinery.id
ALTER TABLE public.project_machinery
  ADD CONSTRAINT project_machinery_machinery_id_fkey
  FOREIGN KEY (machinery_id) REFERENCES public.machinery(id)
  ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
