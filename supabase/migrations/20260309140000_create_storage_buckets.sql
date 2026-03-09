-- Create the equipment storage bucket
insert into storage.buckets (id, name, public)
values ('equipment', 'equipment', true)
on conflict (id) do nothing;

-- Allow public read access (select)
create policy "Public Access equipment"
on storage.objects for select
to public
using ( bucket_id = 'equipment' );

-- Allow authenticated users to upload (insert)
create policy "Authenticated users can upload equipment"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'equipment' );

-- Allow authenticated users to update their files (update)
create policy "Authenticated users can update equipment"
on storage.objects for update
to authenticated
using ( bucket_id = 'equipment' );

-- Allow authenticated users to delete their files (delete)
create policy "Authenticated users can delete equipment"
on storage.objects for delete
to authenticated
using ( bucket_id = 'equipment' );
