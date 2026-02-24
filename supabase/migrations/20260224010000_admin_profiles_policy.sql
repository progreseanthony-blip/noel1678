-- Allow admins to manage all profiles
-- First, check if the policy exists and drop it
drop policy if exists "Admins can update any profile." on public.profiles;
drop policy if exists "Admins can insert any profile." on public.profiles;
drop policy if exists "Admins can delete any profile." on public.profiles;

-- Admins can update any profile
create policy "Admins can update any profile." on public.profiles
  for update using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'Admin'
    )
  );

-- Admins can insert any profile
create policy "Admins can insert any profile." on public.profiles
  for insert with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'Admin'
    )
  );

-- Admins can delete any profile
create policy "Admins can delete any profile." on public.profiles
  for delete using (
    exists (
      select 1 from public.profiles
      where id = auth.uid() and role = 'Admin'
    )
  );
