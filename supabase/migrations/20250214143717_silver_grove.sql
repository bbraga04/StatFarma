/*
  # Fix course search functionality

  1. Changes
    - Simplify course search function
    - Add proper indexes for search
    - Update course table constraints
  
  2. Security
    - Maintain RLS policies
    - Keep security settings
*/

-- Drop existing function if exists
DROP FUNCTION IF EXISTS search_courses(text);

-- Create extension if not exists
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Create simplified search function
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
  ORDER BY 
    CASE 
      WHEN search_term IS NULL OR search_term = '' THEN created_at
      ELSE created_at
    END DESC;
$$;

-- Ensure proper indexes exist
CREATE INDEX IF NOT EXISTS idx_courses_title_gin ON courses USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_courses_description_gin ON courses USING gin (description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_courses_created_at ON courses(created_at DESC);

-- Update function comment
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição, ordenando por data de criação';

-- Ensure policies are correct
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
DROP POLICY IF EXISTS "All users can view courses" ON courses;

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