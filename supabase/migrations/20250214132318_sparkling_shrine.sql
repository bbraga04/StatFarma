/*
  # Correção da tabela de cursos

  1. Alterações
    - Adiciona restrições NOT NULL apropriadas
    - Adiciona validações para URLs
    - Adiciona índices para busca

  2. Índices
    - Índice GIN para busca em texto
    - Índice B-tree para ordenação por data
*/

-- Adiciona extensão para busca em texto completo se não existir
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Atualiza a tabela de cursos
ALTER TABLE courses
  ALTER COLUMN title SET NOT NULL,
  ALTER COLUMN description SET NOT NULL,
  ALTER COLUMN price SET DEFAULT 0,
  ALTER COLUMN price SET NOT NULL,
  ADD CONSTRAINT price_non_negative CHECK (price >= 0),
  ADD CONSTRAINT valid_image_url CHECK (
    image_url IS NULL OR 
    image_url ~ '^https?://.+'
  );

-- Cria índices para melhorar performance de busca
CREATE INDEX IF NOT EXISTS courses_title_trgm_idx ON courses USING gin (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS courses_description_trgm_idx ON courses USING gin (description gin_trgm_ops);
CREATE INDEX IF NOT EXISTS courses_created_at_idx ON courses (created_at DESC);

-- Atualiza a tabela de conteúdos
ALTER TABLE course_contents
  ADD CONSTRAINT valid_content_url CHECK (
    url ~ '^https?://.+'
  );

-- Função para busca de cursos
CREATE OR REPLACE FUNCTION search_courses(search_term text)
RETURNS TABLE (
  id uuid,
  title text,
  description text,
  price numeric,
  image_url text,
  created_at timestamptz,
  updated_at timestamptz,
  similarity float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.*,
    GREATEST(
      similarity(c.title, search_term),
      similarity(c.description, search_term)
    ) as similarity
  FROM courses c
  WHERE 
    search_term IS NULL 
    OR c.title ILIKE '%' || search_term || '%'
    OR c.description ILIKE '%' || search_term || '%'
  ORDER BY 
    CASE WHEN search_term IS NULL THEN c.created_at
    ELSE similarity END DESC;
END;
$$;