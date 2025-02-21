/*
  # Correção da tabela de cursos e função de busca

  1. Alterações
    - Remove restrições desnecessárias da tabela courses
    - Simplifica a função de busca
    - Mantém apenas os índices essenciais
  
  2. Segurança
    - Mantém as políticas RLS existentes
    - Garante que a função de busca é segura
*/

-- Drop existing function
DROP FUNCTION IF EXISTS search_courses(text);

-- Remove constraints that might be causing issues
ALTER TABLE courses
DROP CONSTRAINT IF EXISTS valid_image_url;

-- Simplify search function
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

-- Ensure basic indexes exist
CREATE INDEX IF NOT EXISTS idx_courses_created_at ON courses(created_at DESC);

-- Update function comment
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição';

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