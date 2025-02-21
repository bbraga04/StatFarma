/*
  # Course Content Management Base Tables
  
  1. New Tables
    - course_modules: Organizes course content into modules
    - course_lessons: Individual lessons within modules
  
  2. Security
    - Enable RLS on all tables
    - Add policies for content access
*/

-- Safely handle content_type enum
DO $$ 
BEGIN
  -- Drop the enum type if it exists
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_type') THEN
    DROP TYPE content_type CASCADE;
  END IF;
  
  -- Create the enum type
  CREATE TYPE content_type AS ENUM ('video', 'pdf');
EXCEPTION
  WHEN duplicate_object THEN 
    NULL;
END $$;

-- Create course_modules table
CREATE TABLE course_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  order_number integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(course_id, order_number)
);

-- Create course_lessons table
CREATE TABLE course_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES course_modules(id) ON DELETE CASCADE,
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

-- Enable RLS
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Policies for course_modules
CREATE POLICY "Admins can manage course modules"
  ON course_modules
  FOR ALL
  TO authenticated
  USING (auth.is_admin())
  WITH CHECK (auth.is_admin());

CREATE POLICY "Users can view modules of purchased courses"
  ON course_modules
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM user_courses
      WHERE user_courses.course_id = course_modules.course_id
      AND user_courses.user_id = auth.uid()
    )
  );

-- Policies for course_lessons
CREATE POLICY "Admins can manage course lessons"
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
      SELECT 1 FROM course_modules
      JOIN user_courses ON user_courses.course_id = course_modules.course_id
      WHERE course_modules.id = course_lessons.module_id
      AND user_courses.user_id = auth.uid()
    )
  );

-- Create indexes
CREATE INDEX idx_course_modules_course ON course_modules(course_id);
CREATE INDEX idx_course_modules_order ON course_modules(course_id, order_number);
CREATE INDEX idx_course_lessons_module ON course_lessons(module_id);
CREATE INDEX idx_course_lessons_order ON course_lessons(module_id, order_number);

-- Add helpful comments
COMMENT ON TABLE course_modules IS 'Organizes course content into modules';
COMMENT ON TABLE course_lessons IS 'Individual lessons within modules';
COMMENT ON TYPE content_type IS 'Type of lesson content (video or pdf)';