-- Verificación de FKs faltantes para PostgREST en producción
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'project_machinery_machinery_id_fkey') THEN
    ALTER TABLE public.project_machinery
      ADD CONSTRAINT project_machinery_machinery_id_fkey
      FOREIGN KEY (machinery_id) REFERENCES public.machinery(id)
      ON DELETE SET NULL;
    RAISE NOTICE 'Created project_machinery_machinery_id_fkey';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'project_labor_role_id_fkey') THEN
    ALTER TABLE public.project_labor
      ADD CONSTRAINT project_labor_role_id_fkey
      FOREIGN KEY (role_id) REFERENCES public.labor_roles(id)
      ON DELETE SET NULL;
    RAISE NOTICE 'Created project_labor_role_id_fkey';
  END IF;
END $$;

DO $$
DECLARE
  m_fk boolean;
  l_fk boolean;
BEGIN
  SELECT EXISTS(SELECT 1 FROM pg_constraint WHERE conname = 'project_machinery_machinery_id_fkey') INTO m_fk;
  SELECT EXISTS(SELECT 1 FROM pg_constraint WHERE conname = 'project_labor_role_id_fkey') INTO l_fk;
  RAISE NOTICE 'FK status: machinery=%, labor=%', m_fk, l_fk;
END $$;

NOTIFY pgrst, 'reload schema';
