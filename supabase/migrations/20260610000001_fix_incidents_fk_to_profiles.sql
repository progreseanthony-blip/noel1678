-- Fix FK references in incidents module: use profiles(id) instead of auth.users(id)
-- profiles.id = auth.users.id, but PostgREST needs direct FK to resolve joins

ALTER TABLE public.incidents
    DROP CONSTRAINT IF EXISTS incidents_reported_by_fkey,
    DROP CONSTRAINT IF EXISTS incidents_resolved_by_fkey;

ALTER TABLE public.incidents
    ADD CONSTRAINT incidents_reported_by_fkey FOREIGN KEY (reported_by) REFERENCES public.profiles(id) ON DELETE SET NULL,
    ADD CONSTRAINT incidents_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.profiles(id) ON DELETE SET NULL;

ALTER TABLE public.incident_actions
    DROP CONSTRAINT IF EXISTS incident_actions_assigned_to_fkey;

ALTER TABLE public.incident_actions
    ADD CONSTRAINT incident_actions_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.profiles(id) ON DELETE SET NULL;

NOTIFY pgrst, 'reload schema';
