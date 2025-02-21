/*
  # Policy Evaluation Efficiency Check

  1. New Functions
    - `check_policy_evaluations`: Analyzes RLS policies for inefficient function calls
    - Returns a table with schema, table, policy name, and potential issues

  2. Security
    - Function is security definer
    - Restricted to authenticated users
    - Uses explicit search path

  3. Checks
    - Detects repeated calls to current_setting()
    - Detects repeated calls to auth.* functions
    - Suggests optimizations
*/

-- Create function to analyze policy evaluations
CREATE OR REPLACE FUNCTION check_policy_evaluations()
RETURNS TABLE (
  schema_name text,
  table_name text,
  policy_name text,
  policy_definition text,
  potential_issues text[]
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
  policy record;
  issues text[];
BEGIN
  FOR policy IN
    SELECT
      n.nspname as schema_name,
      c.relname as table_name,
      pol.polname as policy_name,
      pg_get_expr(pol.polqual, pol.polrelid) as policy_using,
      pg_get_expr(pol.polwithcheck, pol.polrelid) as policy_check
    FROM pg_policy pol
    JOIN pg_class c ON c.oid = pol.polrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname NOT IN ('pg_catalog', 'information_schema')
  LOOP
    issues := ARRAY[]::text[];
    
    -- Check for current_setting calls
    IF (policy.policy_using ILIKE '%current_setting%' OR 
        policy.policy_check ILIKE '%current_setting%')
    THEN
      issues := array_append(
        issues,
        'Uses current_setting() which is evaluated for each row. Consider caching the value in a variable.'
      );
    END IF;

    -- Check for auth function calls
    IF (policy.policy_using ILIKE '%auth.%()%' OR 
        policy.policy_check ILIKE '%auth.%()%')
    THEN
      issues := array_append(
        issues,
        'Uses auth.* functions which are evaluated for each row. Consider caching the result in a variable.'
      );
    END IF;

    -- Only return policies with issues
    IF array_length(issues, 1) > 0 THEN
      schema_name := policy.schema_name;
      table_name := policy.table_name;
      policy_name := policy.policy_name;
      policy_definition := COALESCE(policy.policy_using, '') || 
                         CASE WHEN policy.policy_check IS NOT NULL 
                              THEN E'\nWITH CHECK ' || policy.policy_check
                              ELSE '' 
                         END;
      potential_issues := issues;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

-- Revoke public access
REVOKE ALL ON FUNCTION check_policy_evaluations() FROM PUBLIC;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION check_policy_evaluations() TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION check_policy_evaluations() IS 
'Analyzes RLS policies for potentially inefficient function calls that may be unnecessarily re-evaluated for each row.
Returns a table with:
- schema_name: Schema containing the table
- table_name: Table with the policy
- policy_name: Name of the policy
- policy_definition: Full policy definition
- potential_issues: Array of identified efficiency concerns';