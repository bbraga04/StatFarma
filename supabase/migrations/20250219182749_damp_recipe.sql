-- Add modules and lessons for the first course (Fundamentos de Estatística para Farmacêuticos)
INSERT INTO course_modules (id, course_id, title, description, order_number)
SELECT 
  gen_random_uuid(),
  id,
  'Introdução à Estatística',
  'Conceitos fundamentais e sua aplicação na indústria farmacêutica',
  1
FROM courses 
WHERE title = 'Fundamentos de Estatística para Farmacêuticos';

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Conceitos Básicos de Estatística',
  'Introdução aos conceitos fundamentais de estatística e sua importância na indústria farmacêutica',
  'video',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  1
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 1;

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Tipos de Dados e Variáveis',
  'Compreenda os diferentes tipos de dados e variáveis utilizados em análises estatísticas',
  'video',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  2
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 1;

-- Add second module
INSERT INTO course_modules (id, course_id, title, description, order_number)
SELECT 
  gen_random_uuid(),
  id,
  'Estatística Descritiva',
  'Medidas de tendência central e dispersão',
  2
FROM courses 
WHERE title = 'Fundamentos de Estatística para Farmacêuticos';

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Medidas de Tendência Central',
  'Aprenda sobre média, mediana e moda e suas aplicações práticas',
  'video',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  1
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 2;

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Medidas de Dispersão',
  'Compreenda variância, desvio padrão e coeficiente de variação',
  'video',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  2
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 2;

-- Add third module
INSERT INTO course_modules (id, course_id, title, description, order_number)
SELECT 
  gen_random_uuid(),
  id,
  'Distribuições de Probabilidade',
  'Principais distribuições e suas aplicações',
  3
FROM courses 
WHERE title = 'Fundamentos de Estatística para Farmacêuticos';

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Distribuição Normal',
  'Entenda a distribuição normal e sua importância na indústria farmacêutica',
  'video',
  'https://www.youtube.com/embed/dQw4w9WgXcQ',
  1
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 3;

INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
SELECT 
  m.id,
  'Material Complementar',
  'Tabelas e fórmulas importantes para distribuições de probabilidade',
  'pdf',
  'https://example.com/sample.pdf',
  2
FROM course_modules m
JOIN courses c ON c.id = m.course_id
WHERE c.title = 'Fundamentos de Estatística para Farmacêuticos'
AND m.order_number = 3;