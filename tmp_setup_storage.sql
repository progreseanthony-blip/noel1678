INSERT INTO storage.buckets (id, name, public) VALUES ('equipment', 'equipment', true) ON CONFLICT (id) DO NOTHING;
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Allow Public Image Upload') THEN
        CREATE POLICY "Allow Public Image Upload" ON storage.objects FOR ALL USING (bucket_id = 'equipment') WITH CHECK (bucket_id = 'equipment');
    END IF;
END $$;
