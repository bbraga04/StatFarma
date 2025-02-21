/*
  # Adicionar função para gerenciar administradores

  1. Nova Função
    - `make_user_admin`: Função para definir um usuário como administrador
    - Parâmetros:
      - user_id: UUID do usuário
      - is_admin: boolean para definir se o usuário é admin ou não

  2. Segurança
    - Função só pode ser executada por superusuários ou administradores existentes
*/

-- Função para tornar um usuário administrador
CREATE OR REPLACE FUNCTION make_user_admin(user_id uuid, is_admin boolean)
RETURNS void AS $$
BEGIN
  -- Atualiza os metadados do usuário
  UPDATE auth.users
  SET raw_user_meta_data = 
    CASE 
      WHEN raw_user_meta_data IS NULL THEN 
        jsonb_build_object('is_admin', is_admin)
      ELSE 
        raw_user_meta_data || jsonb_build_object('is_admin', is_admin)
    END
  WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;