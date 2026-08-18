-- Ensure the storage bucket for incident photos exists and is public
insert into storage.buckets (id, name, public)
values ('incident-photos', 'incident-photos', true)
on conflict (id) do update set public = true;

-- Allow public access to the incident photos bucket
create policy "Public Access for incident photos"
on storage.objects for select
using ( bucket_id = 'incident-photos' );

-- Allow authenticated users to upload to incident photos bucket
create policy "Auth Insert for incident photos"
on storage.objects for insert
with check ( bucket_id = 'incident-photos' AND auth.role() = 'authenticated' );

-- Allow authenticated users to update objects in incident photos bucket
create policy "Auth Update for incident photos"
on storage.objects for update
with check ( bucket_id = 'incident-photos' AND auth.role() = 'authenticated' );

-- Allow authenticated users to delete objects in incident photos bucket
create policy "Auth Delete for incident photos"
on storage.objects for delete
using ( bucket_id = 'incident-photos' AND auth.role() = 'authenticated' );