-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage course videos" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view course videos" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage course documents" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view course documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage course thumbnails" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view course thumbnails" ON storage.objects;

-- Create buckets if they don't exist
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

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policies for course content buckets
CREATE POLICY "Course content access policy"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id IN ('course-videos', 'course-documents', 'course-thumbnails')
);

CREATE POLICY "Admin content management policy"
ON storage.objects
FOR ALL 
TO authenticated
USING (
  bucket_id IN ('course-videos', 'course-documents', 'course-thumbnails')
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id IN ('course-videos', 'course-documents', 'course-thumbnails')
  AND auth.is_admin()
);

-- Add helpful comments
COMMENT ON TABLE storage.objects IS 'Table storing all storage objects';
COMMENT ON COLUMN storage.objects.bucket_id IS 'The bucket this object belongs to';