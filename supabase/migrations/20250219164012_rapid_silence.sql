-- Delete existing courses
DELETE FROM courses;

-- Insert new courses
INSERT INTO courses (title, description, price, image_url)
VALUES
  (
    'Fundamentos de Estatística para Farmacêuticos',
    'Aprenda os conceitos fundamentais de estatística aplicados à área farmacêutica. Curso essencial para profissionais que desejam compreender e aplicar análises estatísticas no contexto farmacêutico.',
    399.90,
    'https://images.unsplash.com/photo-1585435557343-3b092031a831?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Plano de Amostragem: Inspeção de Atributo e Variável',
    'Domine as técnicas de amostragem e inspeção estatística para controle de qualidade na indústria farmacêutica. Aprenda a desenvolver e implementar planos de amostragem eficientes.',
    449.90,
    'https://images.unsplash.com/photo-1579154204601-01588f351e67?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Controle Estatístico de Processo',
    'Aprenda a implementar e gerenciar o controle estatístico de processo na indústria farmacêutica. Desenvolva habilidades para monitorar e melhorar a qualidade dos processos produtivos.',
    499.90,
    'https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Excel para Farmacêuticos',
    'Aprenda a utilizar o Excel para análises estatísticas no contexto farmacêutico. Curso prático focado em ferramentas e funcionalidades essenciais para o dia a dia do profissional.',
    299.90,
    'https://images.unsplash.com/photo-1561736778-92e52a7769ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Validação de Processo',
    'Compreenda e aplique métodos estatísticos para validação de processos farmacêuticos. Curso focado em garantir a qualidade e conformidade dos processos produtivos.',
    549.90,
    'https://images.unsplash.com/photo-1563213126-a4273aed2016?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Validação de Limpeza',
    'Aprenda a aplicar métodos estatísticos na validação de procedimentos de limpeza. Curso essencial para garantir a qualidade e segurança dos processos de limpeza na indústria farmacêutica.',
    449.90,
    'https://images.unsplash.com/photo-1584744982491-665216d95f8b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Estabilidade do Produto',
    'Domine as técnicas estatísticas para análise de estabilidade de produtos farmacêuticos. Aprenda a planejar, executar e interpretar estudos de estabilidade.',
    499.90,
    'https://images.unsplash.com/photo-1563213126-a4273aed2016?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Controle Estatístico de Contaminação Ambiental',
    'Aprenda a implementar e gerenciar o controle estatístico de contaminação ambiental em áreas produtivas. Curso focado em monitoramento e análise de dados ambientais.',
    449.90,
    'https://images.unsplash.com/photo-1579154204601-01588f351e67?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Verificação Continuada de Processo',
    'Desenvolva habilidades para realizar a verificação continuada de processos utilizando métodos estatísticos. Curso focado em monitoramento e melhoria contínua.',
    549.90,
    'https://images.unsplash.com/photo-1581093458791-9f3c3900df4b?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Estatística para Revisão da Qualidade do Produto',
    'Aprenda a aplicar métodos estatísticos na revisão periódica da qualidade de produtos farmacêuticos. Curso essencial para garantir a conformidade e melhoria contínua.',
    499.90,
    'https://images.unsplash.com/photo-1585435557343-3b092031a831?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  ),
  (
    'Avaliação de Tendência',
    'Domine as técnicas estatísticas para análise e avaliação de tendências em processos farmacêuticos. Aprenda a identificar e interpretar padrões e tendências nos dados.',
    399.90,
    'https://images.unsplash.com/photo-1561736778-92e52a7769ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80'
  );