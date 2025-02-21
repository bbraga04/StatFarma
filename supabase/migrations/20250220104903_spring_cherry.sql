-- Create certificates bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'certificates',
  'certificates',
  true,
  10485760, -- 10MB limit
  ARRAY['application/pdf']::text[]
)
ON CONFLICT (id) DO NOTHING;

-- Create policies for certificates bucket
CREATE POLICY "Admins can upload certificates"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'certificates'
  AND auth.is_admin()
  AND (LOWER(RIGHT(name, 4)) = '.pdf')
);

CREATE POLICY "Anyone can download certificates"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'certificates');

CREATE POLICY "Admins can update certificates"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'certificates'
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id = 'certificates'
  AND auth.is_admin()
);

CREATE POLICY "Admins can delete certificates"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'certificates'
  AND auth.is_admin()
);

-- Add helpful comments
COMMENT ON POLICY "Admins can upload certificates" ON storage.objects IS 'Only admins can upload PDF certificates';
COMMENT ON POLICY "Anyone can download certificates" ON storage.objects IS 'Certificates are publicly downloadable';
COMMENT ON POLICY "Admins can update certificates" ON storage.objects IS 'Only admins can update certificates';
COMMENT ON POLICY "Admins can delete certificates" ON storage.objects IS 'Only admins can delete certificates';