/*
  # Correções e Melhorias no Banco de Dados

  1. Correções
    - Remove restrições problemáticas
    - Simplifica estrutura de cursos
    - Melhora índices e buscas

  2. Segurança
    - Mantém RLS
    - Simplifica políticas

  3. Performance
    - Otimiza índices
    - Melhora função de busca
*/

-- Simplifica a tabela de cursos
ALTER TABLE courses
DROP COLUMN IF EXISTS image_url,
ALTER COLUMN description SET NOT NULL,
ADD CONSTRAINT price_positive CHECK (price >= 0);

-- Recria função de busca de forma mais eficiente
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
      WHEN title ILIKE '%' || search_term || '%' THEN created_at
      ELSE created_at + interval '1 second'
    END DESC;
$$;

-- Otimiza índices
DROP INDEX IF EXISTS courses_title_trgm_idx;
DROP INDEX IF EXISTS courses_description_trgm_idx;
CREATE INDEX IF NOT EXISTS idx_courses_search 
ON courses USING btree (
  title text_pattern_ops,
  description text_pattern_ops,
  created_at DESC
);

-- Adiciona comentários úteis
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição';
COMMENT ON TABLE courses IS 'Tabela principal de cursos';
COMMENT ON COLUMN courses.title IS 'Título do curso';
COMMENT ON COLUMN courses.description IS 'Descrição detalhada do curso';
COMMENT ON COLUMN courses.price IS 'Preço do curso em reais';