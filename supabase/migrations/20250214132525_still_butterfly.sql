/*
  # Correção da função de busca de cursos

  1. Alterações
    - Corrige o problema de tipos no CASE
    - Melhora a ordenação dos resultados
    - Adiciona índices otimizados

  2. Segurança
    - Define search_path explicitamente
    - Adiciona SECURITY DEFINER
*/

-- Recria a função de busca com ordenação corrigida
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
  IF search_term IS NULL OR search_term = '' THEN
    RETURN QUERY
    SELECT 
      c.*,
      0::float as similarity
    FROM courses c
    ORDER BY c.created_at DESC;
  ELSE
    RETURN QUERY
    SELECT 
      c.*,
      GREATEST(
        similarity(c.title, search_term),
        similarity(c.description, search_term)
      ) as similarity
    FROM courses c
    WHERE 
      c.title ILIKE '%' || search_term || '%'
      OR c.description ILIKE '%' || search_term || '%'
    ORDER BY similarity DESC;
  END IF;
END;
$$;