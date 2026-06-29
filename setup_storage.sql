-- Create the "cars" storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('cars', 'cars', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to the cars bucket
CREATE POLICY "Public Access" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'cars');

-- Allow authenticated users (like Admin) to upload files
CREATE POLICY "Admin Upload Access" 
ON storage.objects FOR INSERT 
TO authenticated
WITH CHECK (bucket_id = 'cars');

-- Allow authenticated users to delete files
CREATE POLICY "Admin Delete Access" 
ON storage.objects FOR DELETE 
TO authenticated
USING (bucket_id = 'cars');
