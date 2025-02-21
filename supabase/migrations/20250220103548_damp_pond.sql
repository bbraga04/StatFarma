-- Fix ambiguous column references in can_access_lesson function
CREATE OR REPLACE FUNCTION can_access_lesson(p_lesson_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_module_id uuid;
  v_order_number integer;
  v_previous_lesson_id uuid;
  v_previous_completed boolean;
  v_course_id uuid;
  v_has_access boolean;
BEGIN
  -- Get course ID and check access
  SELECT cl.course_id INTO v_course_id
  FROM course_lessons cl
  WHERE cl.id = p_lesson_id;

  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Check if user has access to the course
  SELECT EXISTS (
    SELECT 1 FROM user_courses uc
    WHERE uc.course_id = v_course_id
    AND uc.user_id = p_user_id
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    RETURN false;
  END IF;

  -- Get lesson details
  SELECT 
    cl.module_id,
    cl.order_number
  INTO 
    v_module_id,
    v_order_number
  FROM course_lessons cl
  WHERE cl.id = p_lesson_id;

  -- If it's the first lesson, allow access
  IF v_order_number = 1 THEN
    RETURN true;
  END IF;

  -- Get previous lesson
  SELECT cl.id INTO v_previous_lesson_id
  FROM course_lessons cl
  WHERE cl.module_id = v_module_id
  AND cl.order_number = v_order_number - 1;

  -- Check if previous lesson is completed
  SELECT lp.completed INTO v_previous_completed
  FROM lesson_progress lp
  WHERE lp.lesson_id = v_previous_lesson_id
  AND lp.user_id = p_user_id;

  RETURN COALESCE(v_previous_completed, false);
END;
$$;

-- Add helpful comment
COMMENT ON FUNCTION can_access_lesson IS 
'Checks if a user can access a lesson based on course enrollment and previous lesson completion.
Returns true if:
1. User is enrolled in the course
2. Lesson is first in module OR previous lesson is completed';

-- Revoke public access
REVOKE ALL ON FUNCTION can_access_lesson FROM public;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION can_access_lesson TO authenticated;

-- Create function to validate URLs
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

  -- Check for valid protocol
  IF NOT (
    url LIKE 'http://%' OR 
    url LIKE 'https://%' OR 
    url LIKE 'ftp://%'
  ) THEN
    RETURN false;
  END IF;

  -- Basic URL validation
  RETURN url ~ '^https?://[^\s/$.?#].[^\s]*$';
END;
$$;

-- Add URL validation check to course_lessons
ALTER TABLE course_lessons
ADD CONSTRAINT valid_content_url 
CHECK (is_valid_url(content_url));

-- Add URL validation check to courses
ALTER TABLE courses
ADD CONSTRAINT valid_image_url 
CHECK (image_url IS NULL OR is_valid_url(image_url));

-- Add helpful comments
COMMENT ON FUNCTION is_valid_url IS 'Validates if a string is a valid URL';
COMMENT ON CONSTRAINT valid_content_url ON course_lessons IS 'Ensures content_url is a valid URL';
COMMENT ON CONSTRAINT valid_image_url ON courses IS 'Ensures image_url is a valid URL when present';