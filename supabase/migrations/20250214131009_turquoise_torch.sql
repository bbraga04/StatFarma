/*
  # Criar tabelas para gerenciamento de cursos

  1. Novas Tabelas
    - `courses`
      - `id` (uuid, primary key)
      - `title` (text)
      - `description` (text)
      - `price` (numeric)
      - `image_url` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `course_contents`
      - `id` (uuid, primary key)
      - `course_id` (uuid, foreign key)
      - `title` (text)
      - `type` (enum: video, pdf, image)
      - `url` (text)
      - `order` (integer)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)

    - `user_courses`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `course_id` (uuid, foreign key)
      - `purchased_at` (timestamptz)
      - `created_at` (timestamptz)

  2. Security
    - Enable RLS on all tables
    - Add policies for:
      - Admins can manage all courses and contents
      - Users can view purchased courses
      - Users can view course contents for purchased courses
*/

-- Create content type enum
CREATE TYPE content_type AS ENUM ('video', 'pdf', 'image');

-- Create courses table
CREATE TABLE IF NOT EXISTS courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  price numeric NOT NULL DEFAULT 0,
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create course_contents table
CREATE TABLE IF NOT EXISTS course_contents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  type content_type NOT NULL,
  url text NOT NULL,
  "order" integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create user_courses table
CREATE TABLE IF NOT EXISTS user_courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  purchased_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_contents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_courses ENABLE ROW LEVEL SECURITY;

-- Policies for courses table
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

-- Policies for course_contents table
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

-- Policies for user_courses table
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

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_courses_updated_at
  BEFORE UPDATE ON courses
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_course_contents_updated_at
  BEFORE UPDATE ON course_contents
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();