-- Drop existing type and table
DROP TABLE IF EXISTS course_lessons CASCADE;
DROP TYPE IF EXISTS content_type CASCADE;

-- Create new content_type type
CREATE TYPE content_type AS ENUM ('video', 'pdf', 'presentation');

-- Create course_lessons table with new type
CREATE TABLE course_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES course_modules(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id),
  title text NOT NULL,
  description text,
  content_type content_type NOT NULL,
  content_url text NOT NULL,
  duration interval,
  order_number integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(module_id, order_number)
);

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'course-presentations',
    'course-presentations',
    true,
    52428800, -- 50MB limit
    ARRAY[
      'application/vnd.ms-powerpoint',
      'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'application/pdf'
    ]::text[]
  )
ON CONFLICT (id) DO NOTHING;

-- Enable RLS
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admins can manage lessons"
ON course_lessons
FOR ALL
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

CREATE POLICY "Users can view lessons of purchased courses"
ON course_lessons
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM course_modules cm
    JOIN user_courses uc ON uc.course_id = cm.course_id
    WHERE cm.id = course_lessons.module_id
    AND uc.user_id = auth.uid()
  )
);

-- Create storage policies
CREATE POLICY "Anyone can view course content"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-presentations');

CREATE POLICY "Admins can manage course content"
ON storage.objects
FOR ALL
TO authenticated
USING (
  bucket_id = 'course-presentations'
  AND auth.is_admin()
)
WITH CHECK (
  bucket_id = 'course-presentations'
  AND auth.is_admin()
);

-- Add helpful comments
COMMENT ON TABLE course_lessons IS 'Individual lessons within course modules';
COMMENT ON TYPE content_type IS 'Type of lesson content (video, pdf, or presentation)';