-- First, clean up existing content
DELETE FROM quiz_questions;
DELETE FROM course_quizzes;
DELETE FROM course_lessons;
DELETE FROM course_modules;

-- Add modules and lessons for all courses
DO $$ 
DECLARE
  v_course record;
  v_module_id uuid;
  v_quiz_id uuid;
BEGIN
  -- For each course
  FOR v_course IN SELECT id, title FROM courses LOOP
    -- Module 1: Introdução
    INSERT INTO course_modules (id, course_id, title, description, order_number)
    VALUES (
      gen_random_uuid(),
      v_course.id,
      'Introdução',
      'Conceitos fundamentais e visão geral do curso',
      1
    ) RETURNING id INTO v_module_id;

    -- Lessons for Module 1
    INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
    VALUES
      (
        v_module_id,
        'Apresentação do Curso',
        'Visão geral dos objetivos e conteúdo do curso',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        1
      ),
      (
        v_module_id,
        'Material de Apoio',
        'Documentação e recursos necessários para o curso',
        'pdf',
        'https://example.com/material.pdf',
        2
      );

    -- Add quiz for Module 1
    INSERT INTO course_quizzes (module_id, title, description, passing_score)
    VALUES (
      v_module_id,
      'Quiz - Introdução',
      'Teste seus conhecimentos sobre os conceitos básicos',
      70
    ) RETURNING id INTO v_quiz_id;

    INSERT INTO quiz_questions (quiz_id, question, options, correct_answer)
    VALUES
      (
        v_quiz_id,
        'Qual é o principal objetivo deste curso?',
        jsonb_build_array(
          'Apenas teoria estatística',
          'Aplicação prática na indústria farmacêutica',
          'Programação de computadores',
          'História da estatística'
        ),
        'Aplicação prática na indústria farmacêutica'
      ),
      (
        v_quiz_id,
        'Qual é a importância da estatística na indústria farmacêutica?',
        jsonb_build_array(
          'Apenas para relatórios',
          'Não é importante',
          'Fundamental para controle de qualidade e tomada de decisão',
          'Somente para pesquisa acadêmica'
        ),
        'Fundamental para controle de qualidade e tomada de decisão'
      );

    -- Module 2: Fundamentos
    INSERT INTO course_modules (id, course_id, title, description, order_number)
    VALUES (
      gen_random_uuid(),
      v_course.id,
      'Fundamentos',
      'Conceitos essenciais e aplicações práticas',
      2
    ) RETURNING id INTO v_module_id;

    -- Lessons for Module 2
    INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
    VALUES
      (
        v_module_id,
        'Conceitos Básicos',
        'Fundamentos essenciais para o entendimento do curso',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        1
      ),
      (
        v_module_id,
        'Exercícios Práticos',
        'Aplicação dos conceitos em casos reais',
        'pdf',
        'https://example.com/exercises.pdf',
        2
      );

    -- Add quiz for Module 2
    INSERT INTO course_quizzes (module_id, title, description, passing_score)
    VALUES (
      v_module_id,
      'Quiz - Fundamentos',
      'Avalie seu conhecimento sobre os fundamentos',
      70
    ) RETURNING id INTO v_quiz_id;

    INSERT INTO quiz_questions (quiz_id, question, options, correct_answer)
    VALUES
      (
        v_quiz_id,
        'Qual é a medida de tendência central mais apropriada para dados assimétricos?',
        jsonb_build_array(
          'Média',
          'Mediana',
          'Moda',
          'Desvio padrão'
        ),
        'Mediana'
      ),
      (
        v_quiz_id,
        'O que representa o desvio padrão?',
        jsonb_build_array(
          'A média dos dados',
          'O valor mais frequente',
          'A dispersão dos dados em relação à média',
          'O maior valor do conjunto'
        ),
        'A dispersão dos dados em relação à média'
      );

    -- Module 3: Aplicações Práticas
    INSERT INTO course_modules (id, course_id, title, description, order_number)
    VALUES (
      gen_random_uuid(),
      v_course.id,
      'Aplicações Práticas',
      'Casos reais e implementação prática',
      3
    ) RETURNING id INTO v_module_id;

    -- Lessons for Module 3
    INSERT INTO course_lessons (module_id, title, description, content_type, content_url, order_number)
    VALUES
      (
        v_module_id,
        'Estudo de Caso',
        'Análise de um caso real da indústria farmacêutica',
        'video',
        'https://www.youtube.com/embed/dQw4w9WgXcQ',
        1
      ),
      (
        v_module_id,
        'Documentação e Templates',
        'Modelos e documentos para aplicação prática',
        'pdf',
        'https://example.com/templates.pdf',
        2
      );

    -- Add quiz for Module 3
    INSERT INTO course_quizzes (module_id, title, description, passing_score)
    VALUES (
      v_module_id,
      'Quiz - Aplicações Práticas',
      'Teste final sobre aplicações práticas',
      70
    ) RETURNING id INTO v_quiz_id;

    INSERT INTO quiz_questions (quiz_id, question, options, correct_answer)
    VALUES
      (
        v_quiz_id,
        'Em um processo de validação, qual é a importância da análise estatística?',
        jsonb_build_array(
          'Não é importante',
          'Apenas para documentação',
          'Fundamental para comprovar a consistência do processo',
          'Somente para relatórios gerenciais'
        ),
        'Fundamental para comprovar a consistência do processo'
      ),
      (
        v_quiz_id,
        'Qual é o primeiro passo em uma análise estatística de processo?',
        jsonb_build_array(
          'Calcular a média',
          'Coletar e verificar a qualidade dos dados',
          'Fazer o relatório final',
          'Apresentar os resultados'
        ),
        'Coletar e verificar a qualidade dos dados'
      );

  END LOOP;
END $$;

-- Add helpful comments
COMMENT ON TABLE course_modules IS 'Módulos organizando o conteúdo dos cursos';
COMMENT ON TABLE course_lessons IS 'Lições individuais dentro dos módulos';
COMMENT ON TABLE course_quizzes IS 'Quizzes para avaliação do aprendizado';
COMMENT ON TABLE quiz_questions IS 'Questões dos quizzes com alternativas';