/*
  # Adiciona gerenciamento de pastas para cursos

  1. Alterações
    - Adiciona coluna folder_id na tabela courses
    - Cria função para gerar folder_id automaticamente
    - Adiciona trigger para gerar folder_id em novos cursos

  2. Segurança
    - Mantém RLS existente
    - Garante que folder_id seja único
*/

-- Adiciona coluna folder_id
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS folder_id uuid DEFAULT gen_random_uuid(),
ADD CONSTRAINT folder_id_unique UNIQUE (folder_id);

-- Função para gerar folder_id automaticamente
CREATE OR REPLACE FUNCTION generate_course_folder()
RETURNS trigger AS $$
BEGIN
  -- Garante que folder_id seja único
  IF NEW.folder_id IS NULL THEN
    NEW.folder_id := gen_random_uuid();
  END IF;
  
  -- Cria bucket para o curso se não existir
  INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types, owner)
  VALUES (
    NEW.folder_id::text,
    'course-' || NEW.folder_id::text,
    true,
    52428800, -- 50MB
    ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'video/mp4']::text[],
    NULL
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para gerar folder_id
DROP TRIGGER IF EXISTS before_course_insert ON courses;
CREATE TRIGGER before_course_insert
  BEFORE INSERT ON courses
  FOR EACH ROW
  EXECUTE FUNCTION generate_course_folder();

-- Políticas de acesso para os buckets dos cursos
CREATE POLICY "Admins can manage course files"
ON storage.objects
FOR ALL
TO authenticated
USING (
  auth.is_admin() = true
  AND bucket_id IN (
    SELECT folder_id::text FROM courses
  )
)
WITH CHECK (
  auth.is_admin() = true
  AND bucket_id IN (
    SELECT folder_id::text FROM courses
  )
);

CREATE POLICY "Anyone can view course files"
ON storage.objects
FOR SELECT
TO public
USING (
  bucket_id IN (
    SELECT folder_id::text FROM courses
  )
);

-- Comentários
COMMENT ON COLUMN courses.folder_id IS 'ID único da pasta do curso no storage';
COMMENT ON FUNCTION generate_course_folder() IS 'Gera automaticamente uma pasta para cada novo curso';