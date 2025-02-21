-- Drop existing user_courses table if exists
DROP TABLE IF EXISTS user_courses CASCADE;

-- Create user_courses table with proper types
CREATE TABLE user_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  purchased_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE user_courses ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own purchases"
ON user_courses
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own purchases"
ON user_courses
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_user_courses_user ON user_courses(user_id);
CREATE INDEX idx_user_courses_course ON user_courses(course_id);
CREATE INDEX idx_user_courses_user_course ON user_courses(user_id, course_id);

-- Add helpful comments
COMMENT ON TABLE user_courses IS 'Records of course purchases by users';
COMMENT ON COLUMN user_courses.user_id IS 'Reference to auth.users table';
COMMENT ON COLUMN user_courses.course_id IS 'Reference to courses table';
COMMENT ON COLUMN user_courses.purchased_at IS 'When the course was purchased';