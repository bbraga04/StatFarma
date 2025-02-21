/*
  # Adiciona cursos iniciais

  1. Cursos Adicionados
    - Estatística Básica para Profissionais da Saúde (R$ 299,90)
    - Estatística para Controle de Qualidade Industrial (R$ 349,90)
    - Especialização em Análise de Dados Clínicos (R$ 599,90)
    - Bioestatística Aplicada (R$ 399,90)
    - Estatística para Validação de Métodos Analíticos (R$ 449,90)

  2. Detalhes
    - Cada curso inclui título, descrição detalhada e preço
    - Imagens são carregadas de URLs do Unsplash
*/

-- Insere os cursos iniciais
INSERT INTO courses (title, description, price)
VALUES
  (
    'Estatística Básica para Profissionais da Saúde',
    'Fundamentos de bioestatística, análise de dados clínicos e interpretação de estudos científicos. Curso ideal para profissionais da área de saúde que desejam compreender e aplicar conceitos estatísticos em sua prática diária.',
    299.90
  ),
  (
    'Estatística para Controle de Qualidade Industrial',
    'Métodos estatísticos para controle de processos, análise de variabilidade e melhoria contínua. Aprenda a implementar ferramentas estatísticas essenciais para o controle de qualidade na indústria.',
    349.90
  ),
  (
    'Especialização em Análise de Dados Clínicos',
    'Análise avançada de dados de pesquisa clínica, estudos de caso e metodologias estatísticas. Curso avançado para profissionais que desejam se especializar em análise de dados na área da saúde.',
    599.90
  ),
  (
    'Bioestatística Aplicada',
    'Métodos estatísticos essenciais para análise de dados em saúde e pesquisa biomédica. Aprenda a planejar estudos, analisar dados e interpretar resultados em pesquisas biomédicas.',
    399.90
  ),
  (
    'Estatística para Validação de Métodos Analíticos',
    'Aplicação de métodos estatísticos na validação de processos e métodos analíticos. Curso focado em profissionais que trabalham com desenvolvimento e validação de métodos em laboratórios e indústria.',
    449.90
  );