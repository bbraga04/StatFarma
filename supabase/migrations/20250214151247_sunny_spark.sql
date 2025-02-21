/*
  # Adiciona coluna image_url à tabela de cursos

  1. Alterações
    - Adiciona coluna image_url à tabela courses
    - Atualiza os cursos existentes com URLs de imagens
*/

-- Adiciona coluna image_url se não existir
ALTER TABLE courses ADD COLUMN IF NOT EXISTS image_url text;

-- Atualiza os cursos existentes com URLs de imagens
UPDATE courses
SET image_url = CASE title
  WHEN 'Estatística Básica para Profissionais da Saúde' 
    THEN 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  WHEN 'Estatística para Controle de Qualidade Industrial'
    THEN 'https://images.unsplash.com/photo-1581092921461-eab62e97a780?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  WHEN 'Especialização em Análise de Dados Clínicos'
    THEN 'https://images.unsplash.com/photo-1576671081837-49000212a370?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  WHEN 'Bioestatística Aplicada'
    THEN 'https://images.unsplash.com/photo-1532187863486-abf9dbad1b69?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  WHEN 'Estatística para Validação de Métodos Analíticos'
    THEN 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
END;