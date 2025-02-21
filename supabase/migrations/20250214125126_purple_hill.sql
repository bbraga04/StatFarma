/*
  # Add function to detect missing search_path

  1. New Functions
    - `detect_functions_without_search_path`: Retorna uma lista de funções que não têm search_path definido
      - Retorna: table(schema_name text, function_name text)
      - Segurança: SECURITY DEFINER para garantir acesso aos catálogos do sistema
      - Busca em todos os schemas não-sistema

  2. Security
    - Função marcada como SECURITY DEFINER para garantir acesso aos catálogos
    - Restrito a usuários autenticados
*/

CREATE OR REPLACE FUNCTION detect_functions_without_search_path()
RETURNS TABLE(schema_name text, function_name text) 
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
  RETURN QUERY
  SELECT n.nspname::text, p.proname::text
  FROM pg_proc p
  JOIN pg_namespace n ON p.pronamespace = n.oid
  WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
    AND p.prosrc NOT ILIKE '%set search_path =%'
    AND p.prokind = 'f'  -- apenas funções normais
    AND p.proname NOT IN (
      SELECT routine_name::text
      FROM information_schema.routines
      WHERE routine_definition ILIKE '%set search_path =%'
    )
  ORDER BY n.nspname, p.proname;
END;
$$ LANGUAGE plpgsql;

-- Permissão apenas para usuários autenticados
REVOKE ALL ON FUNCTION detect_functions_without_search_path() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION detect_functions_without_search_path() TO authenticated;

COMMENT ON FUNCTION detect_functions_without_search_path() IS 
'Detecta funções que não têm search_path definido explicitamente.
Retorna uma tabela com schema_name e function_name das funções afetadas.';