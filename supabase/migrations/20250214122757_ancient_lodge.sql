/*
  # Adicionar funcionalidade de administrador

  1. Alterações
    - Adiciona função para verificar se um usuário é administrador
    - Adiciona política para permitir que administradores vejam todos os perfis
    - Adiciona política para permitir que administradores atualizem todos os perfis
    - Adiciona política para permitir que administradores excluam perfis

  2. Segurança
    - Apenas administradores podem ver, atualizar e excluir todos os perfis
    - Usuários normais continuam vendo apenas seus próprios perfis
*/

-- Função para verificar se um usuário é administrador
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN (
    SELECT COALESCE(
      current_setting('request.jwt.claims', true)::json->>'app_metadata'->>'is_admin',
      'false'
    )::boolean
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Política para permitir que administradores vejam todos os perfis
CREATE POLICY "Admins can read all profiles"
  ON profiles
  FOR SELECT
  TO authenticated
  USING (auth.is_admin() = true);

-- Política para permitir que administradores atualizem todos os perfis
CREATE POLICY "Admins can update all profiles"
  ON profiles
  FOR UPDATE
  TO authenticated
  USING (auth.is_admin() = true)
  WITH CHECK (auth.is_admin() = true);

-- Política para permitir que administradores excluam perfis
CREATE POLICY "Admins can delete profiles"
  ON profiles
  FOR DELETE
  TO authenticated
  USING (auth.is_admin() = true);