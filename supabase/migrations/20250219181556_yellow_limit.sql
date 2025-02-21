-- Matricula o usuário em todos os cursos
INSERT INTO user_courses (user_id, course_id)
SELECT 
  '10bb8a2c-7354-4838-a6a8-e801f687747e'::uuid,
  id
FROM courses
ON CONFLICT (user_id, course_id) DO NOTHING;

-- Cria registros de progresso inicial para cada curso
INSERT INTO course_progress (user_id, course_id)
SELECT 
  '10bb8a2c-7354-4838-a6a8-e801f687747e'::uuid,
  id
FROM courses
ON CONFLICT (user_id, course_id) DO NOTHING;