-- Create buckets for course content
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'course-videos',
    'course-videos',
    true,
    524288000, -- 500MB limit
    ARRAY['video/mp4', 'video/webm']::text[]
  ),
  (
    'course-documents',
    'course-documents',
    true,
    10485760, -- 10MB limit
    ARRAY['application/pdf']::text[]
  ),
  (
    'course-thumbnails',
    'course-thumbnails',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
  )
ON CONFLICT (id) DO NOTHING;

-- Create policies for course content buckets
CREATE POLICY "Admins can manage course videos"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'course-videos'
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id = 'course-videos'
  AND auth.is_admin()
);

CREATE POLICY "Anyone can view course videos"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-videos');

CREATE POLICY "Admins can manage course documents"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'course-documents'
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id = 'course-documents'
  AND auth.is_admin()
);

CREATE POLICY "Anyone can view course documents"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-documents');

CREATE POLICY "Admins can manage course thumbnails"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'course-thumbnails'
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id = 'course-thumbnails'
  AND auth.is_admin()
);

CREATE POLICY "Anyone can view course thumbnails"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-thumbnails');

-- Add comments using proper syntax
COMMENT ON TABLE storage.objects IS 'Table storing all storage objects';
COMMENT ON COLUMN storage.objects.bucket_id IS 'The bucket this object belongs to';