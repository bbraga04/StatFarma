-- Function to check if previous lesson is completed
CREATE OR REPLACE FUNCTION can_access_lesson(p_lesson_id uuid, p_user_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_module_id uuid;
  v_order_number integer;
  v_previous_lesson_id uuid;
  v_previous_completed boolean;
  v_course_id uuid;
  v_has_access boolean;
BEGIN
  -- First check if user has access to the course
  SELECT course_id INTO v_course_id
  FROM course_modules cm
  JOIN course_lessons cl ON cl.module_id = cm.id
  WHERE cl.id = p_lesson_id;

  SELECT EXISTS (
    SELECT 1 FROM user_courses
    WHERE course_id = v_course_id
    AND user_id = p_user_id
  ) INTO v_has_access;

  IF NOT v_has_access THEN
    RETURN false;
  END IF;

  -- Get lesson details
  SELECT module_id, order_number
  INTO v_module_id, v_order_number
  FROM course_lessons
  WHERE id = p_lesson_id;

  -- If it's the first lesson, allow access
  IF v_order_number = 1 THEN
    RETURN true;
  END IF;

  -- Get previous lesson
  SELECT id INTO v_previous_lesson_id
  FROM course_lessons
  WHERE module_id = v_module_id
  AND order_number = v_order_number - 1;

  -- Check if previous lesson is completed
  SELECT completed INTO v_previous_completed
  FROM lesson_progress
  WHERE lesson_id = v_previous_lesson_id
  AND user_id = p_user_id;

  RETURN COALESCE(v_previous_completed, false);
END;
$$;

-- Function to update course progress
CREATE OR REPLACE FUNCTION update_course_progress()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_course_id uuid;
  v_total_lessons integer;
  v_completed_lessons integer;
BEGIN
  -- Get course ID for the lesson
  SELECT course_id INTO v_course_id
  FROM course_modules
  WHERE id = (
    SELECT module_id
    FROM course_lessons
    WHERE id = NEW.lesson_id
  );

  -- Count total and completed lessons
  WITH lesson_counts AS (
    SELECT
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE lp.completed) as completed
    FROM course_lessons cl
    JOIN course_modules cm ON cm.id = cl.module_id
    LEFT JOIN lesson_progress lp ON lp.lesson_id = cl.id 
      AND lp.user_id = NEW.user_id
    WHERE cm.course_id = v_course_id
  )
  SELECT 
    total,
    completed
  INTO 
    v_total_lessons,
    v_completed_lessons
  FROM lesson_counts;

  -- Update course progress
  INSERT INTO course_progress (
    user_id,
    course_id,
    completed,
    completed_at,
    last_accessed_at
  )
  VALUES (
    NEW.user_id,
    v_course_id,
    v_completed_lessons = v_total_lessons,
    CASE WHEN v_completed_lessons = v_total_lessons THEN now() ELSE NULL END,
    now()
  )
  ON CONFLICT (user_id, course_id)
  DO UPDATE SET
    completed = v_completed_lessons = v_total_lessons,
    completed_at = CASE WHEN v_completed_lessons = v_total_lessons THEN now() ELSE NULL END,
    last_accessed_at = now(),
    updated_at = now();

  RETURN NEW;
END;
$$;

-- Create trigger for updating course progress
CREATE TRIGGER update_course_progress_trigger
  AFTER INSERT OR UPDATE ON lesson_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_course_progress();

-- Add helpful comments
COMMENT ON FUNCTION can_access_lesson IS 
'Verifica se um usuário pode acessar uma lição baseado em:
1. Se possui acesso ao curso
2. Se completou a lição anterior
Retorna true se o acesso for permitido, false caso contrário.';

COMMENT ON FUNCTION update_course_progress IS 
'Atualiza o progresso geral do curso quando o progresso de uma lição é alterado.
Calcula a porcentagem de conclusão e atualiza o status de conclusão do curso.';