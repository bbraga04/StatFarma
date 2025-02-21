-- Update is_admin function without dropping
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
  SELECT coalesce(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb #>> '{app_metadata,is_admin}',
    'false'
  )::boolean;
$$;

-- Revoke public access
REVOKE ALL ON FUNCTION auth.is_admin() FROM PUBLIC;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION auth.is_admin() TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION auth.is_admin() IS 
'Verifica se o usuário atual é um administrador.
Retorna true se o usuário tiver a flag is_admin = true em app_metadata.
Retorna false se não houver claims ou se is_admin não estiver definido.';