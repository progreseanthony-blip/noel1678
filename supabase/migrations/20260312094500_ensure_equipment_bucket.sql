-- Ensure the storage bucket for equipment exists and is public
insert into storage.buckets (id, name, public)
values ('equipment', 'equipment', true)
on conflict (id) do update set public = true;

-- Allow public access to the equipment bucket
create policy "Allow public access to equipment bucket"
on storage.objects for select
using ( bucket_id = 'equipment' );

-- Allow authenticated users to upload to equipment bucket
create policy "Allow authenticated uploads to equipment bucket"
on storage.objects for insert
with check ( bucket_id = 'equipment' );

create policy "Allow authenticated updates to equipment bucket"
on storage.objects for update
with check ( bucket_id = 'equipment' );

create policy "Allow authenticated deletes to equipment bucket"
on storage.objects for delete
using ( bucket_id = 'equipment' );
