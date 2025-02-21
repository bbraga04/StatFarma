/*
  # Move pg_trgm extension to dedicated schema

  1. Changes
    - Create dedicated extensions schema
    - Move pg_trgm extension from public to extensions schema
    - Recreate indexes using qualified extension name
    - Update search function to use qualified extension name

  2. Security
    - Grant usage on extensions schema to authenticated users
    - Revoke public access to extensions schema
*/

-- Drop existing indexes that use pg_trgm
DROP INDEX IF EXISTS idx_courses_title_gin;
DROP INDEX IF EXISTS idx_courses_description_gin;

-- Create extensions schema
CREATE SCHEMA IF NOT EXISTS extensions;

-- Move extension to new schema
ALTER EXTENSION pg_trgm SET SCHEMA extensions;

-- Grant usage on extensions schema
GRANT USAGE ON SCHEMA extensions TO authenticated;
REVOKE ALL ON SCHEMA extensions FROM public;

-- Recreate indexes using qualified extension name
CREATE INDEX idx_courses_title_gin ON courses USING gin (title extensions.gin_trgm_ops);
CREATE INDEX idx_courses_description_gin ON courses USING gin (description extensions.gin_trgm_ops);

-- Update search function to use qualified extension name
CREATE OR REPLACE FUNCTION search_courses(search_term text)
RETURNS SETOF courses
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, extensions, pg_temp
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

-- Add comment
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição, ordenando por data de criação';