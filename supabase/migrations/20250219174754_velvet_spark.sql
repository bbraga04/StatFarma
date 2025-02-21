/*
  # Update course access policies for admins

  1. Changes
    - Add policy for admins to view all course content
    - Add policy for admins to view all progress
    - Update existing policies to include admin access

  2. Security
    - Maintains existing RLS
    - Adds explicit admin access policies
*/

-- Update policies for course_modules to include admin access
DROP POLICY IF EXISTS "Users can view modules of purchased courses" ON course_modules;
CREATE POLICY "Users can view modules of purchased courses"
  ON course_modules
  FOR SELECT
  TO authenticated
  USING (
    auth.is_admin() OR
    EXISTS (
      SELECT 1 FROM user_courses
      WHERE user_courses.course_id = course_modules.course_id
      AND user_courses.user_id = auth.uid()
    )
  );

-- Update policies for course_lessons to include admin access
DROP POLICY IF EXISTS "Users can view lessons of purchased courses" ON course_lessons;
CREATE POLICY "Users can view lessons of purchased courses"
  ON course_lessons
  FOR SELECT
  TO authenticated
  USING (
    auth.is_admin() OR
    EXISTS (
      SELECT 1 FROM course_modules
      JOIN user_courses ON user_courses.course_id = course_modules.course_id
      WHERE course_modules.id = course_lessons.module_id
      AND user_courses.user_id = auth.uid()
    )
  );

-- Update policies for lesson_progress to include admin access
DROP POLICY IF EXISTS "Users can manage their own lesson progress" ON lesson_progress;
CREATE POLICY "Users can manage their own lesson progress"
  ON lesson_progress
  FOR ALL
  TO authenticated
  USING (
    auth.is_admin() OR
    auth.uid() = user_id
  )
  WITH CHECK (
    auth.is_admin() OR
    auth.uid() = user_id
  );

-- Update policies for course_progress to include admin access
DROP POLICY IF EXISTS "Users can manage their own course progress" ON course_progress;
CREATE POLICY "Users can manage their own course progress"
  ON course_progress
  FOR ALL
  TO authenticated
  USING (
    auth.is_admin() OR
    auth.uid() = user_id
  )
  WITH CHECK (
    auth.is_admin() OR
    auth.uid() = user_id
  );

-- Update can_access_lesson function to allow admin access
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
  v_is_admin boolean;
BEGIN
  -- Check if user is admin
  SELECT auth.is_admin() INTO v_is_admin;
  
  -- Admins can access all lessons
  IF v_is_admin THEN
    RETURN true;
  END IF;

  -- For non-admins, check course access
  SELECT course_id INTO v_course_id
  FROM course_modules cm
  JOIN course_lessons cl ON cl.module_id = cm.id
  WHERE cl.id = p_lesson_id;

  SELECT EXISTS (
    SELECT 1 FROM user_courses
    WHERE course_id = v_course_id
    AND user_id = p_user_id
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    RETURN false;
  END IF;

  -- Get lesson details
  SELECT module_id, order_number
  INTO v_module_id, v_order_number
  FROM course_lessons
  WHERE id = p_lesson_id;

  -- If it's the first lesson, allow access
  IF v_order_number = 1 THEN
    RETURN true;
  END IF;

  -- Get previous lesson
  SELECT id INTO v_previous_lesson_id
  FROM course_lessons
  WHERE module_id = v_module_id
  AND order_number = v_order_number - 1;

  -- Check if previous lesson is completed
  SELECT completed INTO v_previous_completed
  FROM lesson_progress
  WHERE lesson_id = v_previous_lesson_id
  AND user_id = p_user_id;

  RETURN COALESCE(v_previous_completed, false);
END;
$$;