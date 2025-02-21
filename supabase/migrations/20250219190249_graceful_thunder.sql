-- Create function to enroll user in course
CREATE OR REPLACE FUNCTION enroll_user_in_course(
  p_user_id uuid,
  p_course_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Insert into user_courses if not exists
  INSERT INTO user_courses (user_id, course_id)
  VALUES (p_user_id, p_course_id)
  ON CONFLICT (user_id, course_id) DO NOTHING;

  -- Create initial course progress
  INSERT INTO course_progress (user_id, course_id)
  VALUES (p_user_id, p_course_id)
  ON CONFLICT (user_id, course_id) DO NOTHING;
END;
$$;

-- Revoke public access
REVOKE ALL ON FUNCTION enroll_user_in_course(uuid, uuid) FROM PUBLIC;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION enroll_user_in_course(uuid, uuid) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION enroll_user_in_course IS 
'Matricula um usuário em um curso e cria registro de progresso inicial.
Parâmetros:
  - p_user_id: ID do usuário
  - p_course_id: ID do curso';