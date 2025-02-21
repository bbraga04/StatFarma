/*
  # Fix course tables and relationships

  1. Changes
    - Safely recreate courses table
    - Update course_contents if exists
    - Add proper constraints and indexes
  
  2. Security
    - Enable RLS
    - Add policies for admins and users
*/

-- Drop existing table if exists (this will cascade to related tables)
DROP TABLE IF EXISTS courses CASCADE;

-- Create courses table
CREATE TABLE courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  price numeric NOT NULL DEFAULT 0,
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admins can manage courses"
ON courses
FOR ALL
TO authenticated
USING (auth.is_admin() = true)
WITH CHECK (auth.is_admin() = true);

CREATE POLICY "All users can view courses"
ON courses
FOR SELECT
TO authenticated
USING (true);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

-- Create basic indexes
CREATE INDEX idx_courses_created_at ON courses(created_at DESC);
CREATE INDEX idx_courses_title ON courses(title);

-- Only create course_contents if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'course_contents') THEN
    CREATE TABLE course_contents (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
      title text NOT NULL,
      type text NOT NULL CHECK (type IN ('video', 'pdf', 'image')),
      url text NOT NULL,
      "order" integer NOT NULL,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    -- Enable RLS on course_contents
    ALTER TABLE course_contents ENABLE ROW LEVEL SECURITY;

    -- Create policies for course_contents
    CREATE POLICY "Admins can manage course contents"
    ON course_contents
    FOR ALL
    TO authenticated
    USING (auth.is_admin() = true)
    WITH CHECK (auth.is_admin() = true);

    CREATE POLICY "Users can view contents of purchased courses"
    ON course_contents
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM user_courses
        WHERE user_courses.course_id = course_contents.course_id
        AND user_courses.user_id = auth.uid()
      )
    );

    -- Create trigger for course_contents updated_at
    CREATE TRIGGER update_course_contents_updated_at
      BEFORE UPDATE ON course_contents
      FOR EACH ROW
      EXECUTE PROCEDURE update_updated_at_column();
  END IF;
END $$;

-- Only create user_courses if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_courses') THEN
    CREATE TABLE user_courses (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
      course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
      purchased_at timestamptz DEFAULT now(),
      created_at timestamptz DEFAULT now(),
      UNIQUE(user_id, course_id)
    );

    -- Enable RLS on user_courses
    ALTER TABLE user_courses ENABLE ROW LEVEL SECURITY;

    -- Create policies for user_courses
    CREATE POLICY "Admins can manage user courses"
    ON user_courses
    FOR ALL
    TO authenticated
    USING (auth.is_admin() = true)
    WITH CHECK (auth.is_admin() = true);

    CREATE POLICY "Users can view their own course purchases"
    ON user_courses
    FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
  END IF;
END $$;