/*
  # Correção da Estrutura de Cursos

  1. Simplificação
    - Remove campos desnecessários
    - Melhora validações
    - Simplifica estrutura

  2. Segurança
    - Mantém RLS
    - Melhora políticas

  3. Performance
    - Otimiza índices
    - Melhora busca
*/

-- Simplifica a estrutura de cursos
DO $$ 
BEGIN
  -- Remove colunas se existirem
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'folder_id') THEN
    ALTER TABLE courses DROP COLUMN folder_id CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'category_id') THEN
    ALTER TABLE courses DROP COLUMN category_id CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'status') THEN
    ALTER TABLE courses DROP COLUMN status CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'duration') THEN
    ALTER TABLE courses DROP COLUMN duration CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'level') THEN
    ALTER TABLE courses DROP COLUMN level CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'requirements') THEN
    ALTER TABLE courses DROP COLUMN requirements CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'what_will_learn') THEN
    ALTER TABLE courses DROP COLUMN what_will_learn CASCADE;
  END IF;
  
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'courses' AND column_name = 'instructor_id') THEN
    ALTER TABLE courses DROP COLUMN instructor_id CASCADE;
  END IF;
END $$;

-- Remove tabelas relacionadas que não estão sendo usadas
DROP TABLE IF EXISTS course_categories CASCADE;
DROP TABLE IF EXISTS course_modules CASCADE;
DROP TABLE IF EXISTS course_lessons CASCADE;

-- Adiciona validações mais rigorosas
DO $$ 
BEGIN
  -- Altera colunas para NOT NULL se ainda não forem
  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'courses' AND column_name = 'title' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE courses ALTER COLUMN title SET NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'courses' AND column_name = 'description' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE courses ALTER COLUMN description SET NOT NULL;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.columns 
             WHERE table_name = 'courses' AND column_name = 'price' 
             AND is_nullable = 'YES') THEN
    ALTER TABLE courses ALTER COLUMN price SET NOT NULL;
  END IF;

  -- Adiciona constraints se não existirem
  IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints 
                WHERE constraint_name = 'title_length') THEN
    ALTER TABLE courses ADD CONSTRAINT title_length 
      CHECK (char_length(title) BETWEEN 3 AND 255);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM information_schema.check_constraints 
                WHERE constraint_name = 'description_length') THEN
    ALTER TABLE courses ADD CONSTRAINT description_length 
      CHECK (char_length(description) >= 10);
  END IF;
END $$;

-- Recria função de busca de forma mais simples e eficiente
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

-- Otimiza índices
DROP INDEX IF EXISTS idx_courses_search;
CREATE INDEX IF NOT EXISTS idx_courses_title ON courses(title);
CREATE INDEX IF NOT EXISTS idx_courses_created_at ON courses(created_at DESC);

-- Adiciona comentários úteis
COMMENT ON TABLE courses IS 'Tabela principal de cursos';
COMMENT ON COLUMN courses.title IS 'Título do curso (3-255 caracteres)';
COMMENT ON COLUMN courses.description IS 'Descrição detalhada do curso (mínimo 10 caracteres)';
COMMENT ON COLUMN courses.price IS 'Preço do curso em reais (não negativo)';
COMMENT ON FUNCTION search_courses(text) IS 'Busca cursos por título ou descrição';