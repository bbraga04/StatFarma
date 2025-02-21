-- Função para matricular usuário em curso
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
  -- Insere matrícula
  INSERT INTO user_courses (user_id, course_id)
  VALUES (p_user_id, p_course_id)
  ON CONFLICT (user_id, course_id) DO NOTHING;

  -- Cria registro de progresso inicial
  INSERT INTO course_progress (user_id, course_id)
  VALUES (p_user_id, p_course_id)
  ON CONFLICT (user_id, course_id) DO NOTHING;
END;
$$;

-- Adiciona comentário
COMMENT ON FUNCTION enroll_user_in_course IS 'Matricula um usuário em um curso e inicializa seu progresso';

-- Revoga acesso público
REVOKE ALL ON FUNCTION enroll_user_in_course FROM PUBLIC;

-- Permite execução apenas para usuários autenticados
GRANT EXECUTE ON FUNCTION enroll_user_in_course TO authenticated;