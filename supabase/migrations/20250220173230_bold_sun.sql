-- Create buckets for presentations
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

-- Update URL validation function
CREATE OR REPLACE FUNCTION is_valid_url(url text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Handle null or empty URLs
  IF url IS NULL OR url = '' THEN
    RETURN false;
  END IF;

  -- Handle special cases
  IF url LIKE '/%' THEN -- Relative URLs
    RETURN true;
  END IF;

  IF url LIKE 'data:%' THEN -- Data URLs
    RETURN true;
  END IF;

  IF url LIKE 'blob:%' THEN -- Blob URLs
    RETURN true;
  END IF;

  -- Handle YouTube embeds
  IF url LIKE 'https://www.youtube.com/embed/%' THEN
    RETURN true;
  END IF;

  -- Handle Supabase storage URLs
  IF url LIKE current_setting('supabase_url') || '/storage/v1/object/public/%' THEN
    RETURN true;
  END IF;

  -- Basic URL validation
  RETURN url ~ '^https?://[^\s/$.?#].[^\s]*$';
END;
$$;

-- Add URL validation check
ALTER TABLE course_lessons
ADD CONSTRAINT valid_content_url 
CHECK (content_url = '' OR is_valid_url(content_url));

-- Add helpful comments
COMMENT ON TYPE content_type IS 'Type of lesson content (video, pdf, or presentation)';
COMMENT ON TABLE course_lessons IS 'Individual lessons within course modules';
COMMENT ON FUNCTION is_valid_url IS 'Validates if a string is a valid URL';
COMMENT ON CONSTRAINT valid_content_url ON course_lessons IS 'Ensures content_url is a valid URL when present';