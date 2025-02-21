/*
  # Course Structure and Progress Tracking

  1. Tables
    - course_modules: Organizes course content into modules
    - course_lessons: Individual lessons within modules
    - lesson_progress: Tracks user progress through lessons
    - course_progress: Tracks overall course completion

  2. Security
    - Enable RLS on all tables
    - Add policies for user and admin access
    - Add functions for progress tracking
*/

-- Drop existing policies if they exist
DO $$ 
BEGIN
  -- Drop policies for course_modules
  DROP POLICY IF EXISTS "Admins can manage course modules" ON course_modules;
  DROP POLICY IF EXISTS "Users can view modules of purchased courses" ON course_modules;
  
  -- Drop policies for course_lessons  
  DROP POLICY IF EXISTS "Admins can manage course lessons" ON course_lessons;
  DROP POLICY IF EXISTS "Users can view lessons of purchased courses" ON course_lessons;
  
  -- Drop policies for lesson_progress
  DROP POLICY IF EXISTS "Users can manage their own lesson progress" ON lesson_progress;
  
  -- Drop policies for course_progress
  DROP POLICY IF EXISTS "Users can manage their own course progress" ON course_progress;
EXCEPTION
  WHEN undefined_table THEN NULL;
  WHEN undefined_object THEN NULL;
END $$;

-- Create content_type enum if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_type') THEN
    CREATE TYPE content_type AS ENUM ('video', 'pdf');
  END IF;
END $$;

-- Create course_modules table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  order_number integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(course_id, order_number)
);

-- Create course_lessons table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_lessons (
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

-- Create lesson_progress table if it doesn't exist
CREATE TABLE IF NOT EXISTS lesson_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id uuid REFERENCES course_lessons(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  last_position interval DEFAULT '0 seconds',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, lesson_id)
);

-- Create course_progress table if it doesn't exist
CREATE TABLE IF NOT EXISTS course_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  last_accessed_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_progress ENABLE ROW LEVEL SECURITY;

-- Create new policies
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
    auth.is_admin() OR
    EXISTS (
      SELECT 1 FROM user_courses
      WHERE user_courses.course_id = course_modules.course_id
      AND user_courses.user_id = auth.uid()
    )
  );

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
    auth.is_admin() OR
    EXISTS (
      SELECT 1 FROM course_modules
      JOIN user_courses ON user_courses.course_id = course_modules.course_id
      WHERE course_modules.id = course_lessons.module_id
      AND user_courses.user_id = auth.uid()
    )
  );

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

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_course_modules_course ON course_modules(course_id);
CREATE INDEX IF NOT EXISTS idx_course_modules_order ON course_modules(course_id, order_number);
CREATE INDEX IF NOT EXISTS idx_course_lessons_module ON course_lessons(module_id);
CREATE INDEX IF NOT EXISTS idx_course_lessons_order ON course_lessons(module_id, order_number);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_lesson ON lesson_progress(lesson_id);
CREATE INDEX IF NOT EXISTS idx_course_progress_user ON course_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_course_progress_course ON course_progress(course_id);

-- Add helpful comments
COMMENT ON TABLE course_modules IS 'Organizes course content into modules';
COMMENT ON TABLE course_lessons IS 'Individual lessons within modules';
COMMENT ON TABLE lesson_progress IS 'Tracks user progress through individual lessons';
COMMENT ON TABLE course_progress IS 'Tracks overall course completion progress';
COMMENT ON TYPE content_type IS 'Type of lesson content (video or pdf)';