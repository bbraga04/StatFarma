/*
  # Fix course creation and search functionality

  1. Changes
    - Drop and recreate courses table with correct structure
    - Create simplified search function
    - Add proper indexes
  
  2. Security
    - Maintain RLS policies
    - Keep security settings
*/

-- Drop existing function and table
DROP FUNCTION IF EXISTS search_courses(text);
DROP TABLE IF EXISTS courses CASCADE;

-- Create courses table
CREATE TABLE courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  price numeric NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  CONSTRAINT price_non_negative CHECK (price >= 0)
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

-- Create extension for text search
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create search function
CREATE OR REPLACE FUNCTION search_courses(search_term text)
RETURNS SETOF courses
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT *
  FROM courses
  WHERE 
    CASE 
      WHEN search_term IS NULL OR search_term = '' THEN true
      ELSE 
        title ILIKE '%' || search_term || '%' OR 
        description ILIKE '%' || search_term || '%'
    END
  ORDER BY created_at DESC;
$$;

-- Create indexes
CREATE INDEX idx_courses_title_gin ON courses USING gin (title gin_trgm_ops);
CREATE INDEX idx_courses_description_gin ON courses USING gin (description gin_trgm_ops);
CREATE INDEX idx_courses_created_at ON courses(created_at DESC);

-- Add comment
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição, ordenando por data de criação';