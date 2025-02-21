-- Create functions to get course info
CREATE OR REPLACE FUNCTION get_course_info(p_module_id uuid)
RETURNS TABLE (
  course_id uuid,
  course_title text,
  course_description text,
  course_price numeric,
  course_image_url text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT 
    c.id,
    c.title,
    c.description,
    c.price,
    c.image_url
  FROM courses c
  JOIN course_modules cm ON cm.course_id = c.id
  WHERE cm.id = p_module_id;
$$;

CREATE OR REPLACE FUNCTION get_module_info(p_lesson_id uuid)
RETURNS TABLE (
  module_id uuid,
  module_title text,
  module_description text,
  course_id uuid,
  course_title text,
  course_description text,
  course_price numeric,
  course_image_url text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT 
    cm.id,
    cm.title,
    cm.description,
    c.id,
    c.title,
    c.description,
    c.price,
    c.image_url
  FROM course_modules cm
  JOIN courses c ON c.id = cm.course_id
  JOIN course_lessons cl ON cl.module_id = cm.id
  WHERE cl.id = p_lesson_id;
$$;

CREATE OR REPLACE FUNCTION get_quiz_info(p_quiz_id uuid)
RETURNS TABLE (
  module_id uuid,
  module_title text,
  module_description text,
  course_id uuid,
  course_title text,
  course_description text
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  SELECT 
    cm.id,
    cm.title,
    cm.description,
    c.id,
    c.title,
    c.description
  FROM course_modules cm
  JOIN courses c ON c.id = cm.course_id
  JOIN course_quizzes cq ON cq.module_id = cm.id
  WHERE cq.id = p_quiz_id;
$$;

-- Revoke public access
REVOKE ALL ON FUNCTION get_course_info(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_module_info(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_quiz_info(uuid) FROM PUBLIC;

-- Grant access to authenticated users
GRANT EXECUTE ON FUNCTION get_course_info(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_module_info(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_quiz_info(uuid) TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION get_course_info IS 'Retorna informações do curso para um módulo específico';
COMMENT ON FUNCTION get_module_info IS 'Retorna informações do módulo e curso para uma lição específica';
COMMENT ON FUNCTION get_quiz_info IS 'Retorna informações do módulo e curso para um quiz específico';