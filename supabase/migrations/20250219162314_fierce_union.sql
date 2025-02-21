-- Drop existing function if exists
DROP FUNCTION IF EXISTS make_user_admin(uuid, boolean);

-- Create new version with proper metadata handling
CREATE OR REPLACE FUNCTION make_user_admin(user_id uuid, is_admin boolean)
RETURNS void
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
BEGIN
  -- Update user metadata using raw_app_meta_data
  UPDATE auth.users
  SET raw_app_meta_data = 
    CASE 
      WHEN raw_app_meta_data IS NULL THEN 
        jsonb_build_object('is_admin', is_admin)
      ELSE 
        raw_app_meta_data || jsonb_build_object('is_admin', is_admin)
    END,
    updated_at = now()
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql;

-- Revoke public access and grant to authenticated users
REVOKE ALL ON FUNCTION make_user_admin(uuid, boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION make_user_admin(uuid, boolean) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION make_user_admin(uuid, boolean) IS 
'Atualiza o status de administrador de um usuário.
Parâmetros:
  - user_id: ID do usuário
  - is_admin: true para tornar admin, false para remover';

-- Recria a tabela courses para garantir estrutura correta
DROP TABLE IF EXISTS courses CASCADE;

CREATE TABLE courses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL,
  price numeric NOT NULL CHECK (price >= 0),
  image_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Recreate policies
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

-- Reinsert initial courses
INSERT INTO courses (title, description, price, image_url)
VALUES
  (
    'Estatística Básica para Profissionais da Saúde',
    'Fundamentos de bioestatística, análise de dados clínicos e interpretação de estudos científicos. Curso ideal para profissionais da área de saúde que desejam compreender e aplicar conceitos estatísticos em sua prática diária.',
    299.90,
    'https://images.unsplash.com/photo-1576091160550-2173dba999ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Controle de Qualidade Industrial',
    'Métodos estatísticos para controle de processos, análise de variabilidade e melhoria contínua. Aprenda a implementar ferramentas estatísticas essenciais para o controle de qualidade na indústria.',
    349.90,
    'https://images.unsplash.com/photo-1581092921461-eab62e97a780?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Especialização em Análise de Dados Clínicos',
    'Análise avançada de dados de pesquisa clínica, estudos de caso e metodologias estatísticas. Curso avançado para profissionais que desejam se especializar em análise de dados na área da saúde.',
    599.90,
    'https://images.unsplash.com/photo-1576671081837-49000212a370?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Bioestatística Aplicada',
    'Métodos estatísticos essenciais para análise de dados em saúde e pesquisa biomédica. Aprenda a planejar estudos, analisar dados e interpretar resultados em pesquisas biomédicas.',
    399.90,
    'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Validação de Métodos Analíticos',
    'Aplicação de métodos estatísticos na validação de processos e métodos analíticos. Curso focado em profissionais que trabalham com desenvolvimento e validação de métodos em laboratórios e indústria.',
    449.90,
    'https://images.unsplash.com/photo-1532094349884-543bc11b234d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  );