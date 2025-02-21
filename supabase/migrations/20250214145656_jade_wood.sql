/*
  # Melhorias no Sistema de Cursos

  1. Novas Tabelas
    - `course_categories` - Categorias dos cursos
    - `course_modules` - Módulos dos cursos
    - `course_lessons` - Lições dentro dos módulos

  2. Alterações
    - Adiciona campos importantes na tabela `courses`
    - Melhora a organização do conteúdo

  3. Segurança
    - Mantém as políticas de RLS
    - Adiciona validações importantes
*/

-- Criar enum para status do curso
CREATE TYPE course_status AS ENUM ('draft', 'published', 'archived');

-- Criar tabela de categorias
CREATE TABLE course_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Adicionar campos na tabela de cursos
ALTER TABLE courses 
ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES course_categories(id),
ADD COLUMN IF NOT EXISTS status course_status DEFAULT 'draft',
ADD COLUMN IF NOT EXISTS duration interval,
ADD COLUMN IF NOT EXISTS level text CHECK (level IN ('iniciante', 'intermediario', 'avancado')),
ADD COLUMN IF NOT EXISTS requirements text[],
ADD COLUMN IF NOT EXISTS what_will_learn text[],
ADD COLUMN IF NOT EXISTS instructor_id uuid REFERENCES auth.users(id);

-- Criar tabela de módulos
CREATE TABLE course_modules (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  order_number integer NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(course_id, order_number)
);

-- Criar tabela de lições
CREATE TABLE course_lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES course_modules(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  content_type text NOT NULL CHECK (content_type IN ('video', 'text', 'quiz', 'assignment')),
  content jsonb NOT NULL,
  duration interval,
  order_number integer NOT NULL,
  is_free boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(module_id, order_number)
);

-- Habilitar RLS
ALTER TABLE course_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_modules ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons ENABLE ROW LEVEL SECURITY;

-- Políticas para categorias
CREATE POLICY "Admins can manage categories"
  ON course_categories
  FOR ALL
  TO authenticated
  USING (auth.is_admin() = true)
  WITH CHECK (auth.is_admin() = true);

CREATE POLICY "Anyone can view categories"
  ON course_categories
  FOR SELECT
  TO authenticated
  USING (true);

-- Políticas para módulos
CREATE POLICY "Admins can manage modules"
  ON course_modules
  FOR ALL
  TO authenticated
  USING (auth.is_admin() = true)
  WITH CHECK (auth.is_admin() = true);

CREATE POLICY "Anyone can view published course modules"
  ON course_modules
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM courses 
      WHERE courses.id = course_modules.course_id 
      AND courses.status = 'published'
    )
  );

-- Políticas para lições
CREATE POLICY "Admins can manage lessons"
  ON course_lessons
  FOR ALL
  TO authenticated
  USING (auth.is_admin() = true)
  WITH CHECK (auth.is_admin() = true);

CREATE POLICY "Anyone can view free lessons"
  ON course_lessons
  FOR SELECT
  TO authenticated
  USING (is_free = true);

CREATE POLICY "Enrolled students can view lessons"
  ON course_lessons
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM course_modules 
      JOIN courses ON courses.id = course_modules.course_id
      JOIN user_courses ON user_courses.course_id = courses.id
      WHERE course_modules.id = course_lessons.module_id
      AND user_courses.user_id = auth.uid()
    )
  );

-- Triggers para updated_at
CREATE TRIGGER update_categories_updated_at
  BEFORE UPDATE ON course_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_modules_updated_at
  BEFORE UPDATE ON course_modules
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at
  BEFORE UPDATE ON course_lessons
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Função para calcular duração total do curso
CREATE OR REPLACE FUNCTION calculate_course_duration(course_id uuid)
RETURNS interval
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  total_duration interval;
BEGIN
  SELECT COALESCE(SUM(duration), '0'::interval)
  INTO total_duration
  FROM course_lessons l
  JOIN course_modules m ON m.id = l.module_id
  WHERE m.course_id = calculate_course_duration.course_id;
  
  RETURN total_duration;
END;
$$;

-- Trigger para atualizar duração do curso
CREATE OR REPLACE FUNCTION update_course_duration()
RETURNS trigger AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE courses
    SET duration = calculate_course_duration(
      (SELECT course_id FROM course_modules WHERE id = NEW.module_id)
    )
    WHERE id = (SELECT course_id FROM course_modules WHERE id = NEW.module_id);
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE courses
    SET duration = calculate_course_duration(
      (SELECT course_id FROM course_modules WHERE id = OLD.module_id)
    )
    WHERE id = (SELECT course_id FROM course_modules WHERE id = OLD.module_id);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_course_duration_trigger
  AFTER INSERT OR UPDATE OR DELETE ON course_lessons
  FOR EACH ROW
  EXECUTE FUNCTION update_course_duration();

-- Índices
CREATE INDEX idx_course_modules_course_id ON course_modules(course_id);
CREATE INDEX idx_course_modules_order ON course_modules(course_id, order_number);
CREATE INDEX idx_course_lessons_module_id ON course_lessons(module_id);
CREATE INDEX idx_course_lessons_order ON course_lessons(module_id, order_number);
CREATE INDEX idx_courses_category ON courses(category_id);
CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_status ON courses(status);

-- Comentários
COMMENT ON TABLE course_categories IS 'Categorias dos cursos (ex: Estatística Básica, Bioestatística)';
COMMENT ON TABLE course_modules IS 'Módulos que organizam o conteúdo dos cursos';
COMMENT ON TABLE course_lessons IS 'Lições individuais dentro dos módulos';
COMMENT ON COLUMN courses.status IS 'Status do curso: rascunho, publicado ou arquivado';
COMMENT ON COLUMN courses.level IS 'Nível de dificuldade do curso';
COMMENT ON COLUMN courses.requirements IS 'Pré-requisitos para fazer o curso';
COMMENT ON COLUMN courses.what_will_learn IS 'O que o aluno aprenderá no curso';
COMMENT ON COLUMN course_lessons.content_type IS 'Tipo de conteúdo da lição';
COMMENT ON COLUMN course_lessons.content IS 'Conteúdo da lição em formato JSON';
COMMENT ON COLUMN course_lessons.is_free IS 'Indica se a lição é gratuita/preview';