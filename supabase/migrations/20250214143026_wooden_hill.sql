/*
  # Correção da função de busca de cursos

  1. Alterações
    - Remove função antiga de busca
    - Cria nova função de busca com implementação correta
    - Adiciona índices para melhor performance
  
  2. Segurança
    - Mantém RLS ativo
    - Atualiza políticas de acesso
*/

-- Drop existing function first
DROP FUNCTION IF EXISTS search_courses(text);

-- Recria função de busca com implementação correta
CREATE OR REPLACE FUNCTION search_courses(search_term text)
RETURNS SETOF courses
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  IF search_term IS NULL OR search_term = '' THEN
    RETURN QUERY
    SELECT *
    FROM courses
    ORDER BY created_at DESC;
  ELSE
    RETURN QUERY
    SELECT *
    FROM courses
    WHERE 
      title ILIKE '%' || search_term || '%'
      OR description ILIKE '%' || search_term || '%'
    ORDER BY 
      CASE 
        WHEN title ILIKE '%' || search_term || '%' THEN 0
        WHEN description ILIKE '%' || search_term || '%' THEN 1
        ELSE 2
      END,
      created_at DESC;
  END IF;
END;
$$;

-- Adiciona índices para melhorar performance de busca
CREATE INDEX IF NOT EXISTS idx_courses_title_gin ON courses USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_courses_description_gin ON courses USING gin (description gin_trgm_ops);

-- Atualiza comentários
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição, ordenando por relevância e data de criação';

-- Garante que as políticas estão corretas
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