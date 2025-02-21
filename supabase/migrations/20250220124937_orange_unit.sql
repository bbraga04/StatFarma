-- Update is_admin function without dropping
CREATE OR REPLACE FUNCTION auth.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = auth, pg_temp
AS $$
DECLARE
  claims jsonb;
BEGIN
  -- Get claims in a safer way
  claims := nullif(current_setting('request.jwt.claims', true), '')::jsonb;
  
  -- Return false if no claims
  IF claims IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check is_admin flag with proper JSONB path
  RETURN COALESCE((claims #>> '{app_metadata,is_admin}')::boolean, false);
END;
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