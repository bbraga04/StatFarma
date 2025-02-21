/*
  # Fix admin promotion function

  1. Changes
    - Drop existing make_user_admin function
    - Create new version that updates app_metadata instead of user_metadata
    - Add security settings and proper search path
  
  2. Security
    - Function is security definer
    - Explicit search path set
    - Only authenticated users can execute
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS make_user_admin(uuid, boolean);

-- Create new version with correct metadata field
CREATE OR REPLACE FUNCTION make_user_admin(user_id uuid, is_admin boolean)
RETURNS void
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
BEGIN
  -- Atualiza os metadados do usuário
  UPDATE auth.users
  SET raw_app_meta_data = 
    CASE 
      WHEN raw_app_meta_data IS NULL THEN 
        jsonb_build_object('is_admin', is_admin)
      ELSE 
        raw_app_meta_data || jsonb_build_object('is_admin', is_admin)
    END
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