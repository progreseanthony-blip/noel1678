-- ============================================================
-- Migration: create change_order_disruption_services table
-- Links disruption COs to specific project services/tasks
-- with affectation type (total_stop, partial, indirect)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.change_order_disruption_services (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  change_order_id uuid NOT NULL REFERENCES public.change_orders(id) ON DELETE CASCADE,
  project_task_id uuid NOT NULL REFERENCES public.project_tasks(id) ON DELETE CASCADE,
  affectation_type text NOT NULL DEFAULT 'total_stop'
    CHECK (affectation_type IN ('total_stop', 'partial', 'indirect')),
  notes text,
  created_at timestamp with time zone DEFAULT now()
);

ALTER TABLE public.change_order_disruption_services ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE policyname = 'Enable all access for authenticated users on change_order_disruption_services'
  ) THEN
    CREATE POLICY "Enable all access for authenticated users on change_order_disruption_services"
      ON public.change_order_disruption_services FOR ALL TO authenticated
      USING (true) WITH CHECK (true);
  END IF;
END
$$;
