/*
  # Fix Admin Access to Courses
  
  1. Updates
    - Simplify auth.is_admin() function
    - Update course policies to ensure admin access
    - Add explicit admin policy for viewing courses
*/

-- Update is_admin function to be more reliable
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
BEGIN
  RETURN coalesce(
    current_setting('request.jwt.claims', true)::jsonb #>> '{app_metadata,is_admin}',
    'false'
  )::boolean;
END;
$$ LANGUAGE plpgsql;

-- Drop existing policies
DROP POLICY IF EXISTS "Admins can manage courses" ON courses;
DROP POLICY IF EXISTS "All users can view courses" ON courses;

-- Create new policies with explicit admin access
CREATE POLICY "Admins can manage courses"
ON courses
FOR ALL
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

CREATE POLICY "Anyone can view courses"
ON courses
FOR SELECT
USING (true);

-- Add helpful comment
COMMENT ON FUNCTION auth.is_admin() IS 
'Verifica se o usuário atual é um administrador.
Retorna true se o usuário tiver a flag is_admin = true em app_metadata.
Retorna false em outros casos.';