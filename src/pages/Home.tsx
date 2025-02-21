import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Calculator, BookOpen, Award, GraduationCap, ChevronRight, CheckCircle, Star } from 'lucide-react';
import toast from 'react-hot-toast';
import SEO from '../components/SEO';

interface Course {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url?: string;
}

export default function Home() {
  const navigate = useNavigate();
  const [courses, setCourses] = useState<Course[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchCourses();
  }, []);

  const fetchCourses = async () => {
    try {
      const { data, error } = await supabase
        .from('courses')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCourses(data || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar cursos');
    } finally {
      setLoading(false);
    }
  };

  return (
    <>
      <SEO
        title="Curso de Estatística Farmacêutica | StatFarma - Especialização em Análise de Dados para Indústria Farmacêutica"
        description="Aprenda estatística aplicada à indústria farmacêutica com nossos cursos especializados. Domine análise de dados, validação de processos, controle estatístico de qualidade e bioestatística. Certificação reconhecida pelo mercado."
        keywords={[
          'curso estatística farmacêutica',
          'estatística para indústria farmacêutica',
          'curso estatística para farmacêuticos',
          'bioestatística farmacêutica',
          'análise de dados farmacêuticos',
          'validação de processos farmacêuticos',
          'controle estatístico farmacêutico',
          'GMP estatística',
          'validação de métodos analíticos',
          'estatística para controle de qualidade',
          'curso online estatística farmácia',
          'estatística para estudos de estabilidade',
          'análise estatística farmacêutica',
          'estatística para validação de limpeza',
          'estatística para validação de processo'
        ]}
      />

      <div>
        {/* Hero Section */}
        <div className="bg-indigo-600 text-white py-20">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h1 className="text-4xl font-extrabold tracking-tight sm:text-5xl mb-4">
                Curso de Estatística para Indústria Farmacêutica
              </h1>
              <p className="mt-4 text-xl text-indigo-100 max-w-3xl mx-auto">
                Domine as análises estatísticas essenciais para a indústria farmacêutica.
                Cursos especializados para profissionais que buscam excelência em GMP e controle de qualidade.
              </p>
              <div className="mt-8">
                <button
                  onClick={() => navigate('/login')}
                  className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50"
                >
                  Comece Agora
                  <ChevronRight className="ml-2 h-5 w-5" />
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* Benefícios Section */}
        <div className="py-16 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h2 className="text-3xl font-extrabold text-gray-900">
                Por que escolher nossos cursos de estatística farmacêutica?
              </h2>
            </div>

            <div className="mt-12 grid grid-cols-1 gap-8 sm:grid-cols-2 lg:grid-cols-3">
              <div className="bg-gray-50 p-6 rounded-lg">
                <div className="text-center">
                  <div className="h-12 w-12 text-indigo-600 mx-auto">
                    <GraduationCap className="h-12 w-12" />
                  </div>
                  <h3 className="mt-4 text-lg font-medium text-gray-900">Especializado para Farmacêuticos</h3>
                  <p className="mt-2 text-gray-500">
                    Conteúdo focado nas necessidades específicas da indústria farmacêutica e GMP
                  </p>
                </div>
              </div>

              <div className="bg-gray-50 p-6 rounded-lg">
                <div className="text-center">
                  <div className="h-12 w-12 text-indigo-600 mx-auto">
                    <Calculator className="h-12 w-12" />
                  </div>
                  <h3 className="mt-4 text-lg font-medium text-gray-900">Aplicação Prática</h3>
                  <p className="mt-2 text-gray-500">
                    Exemplos reais e exercícios práticos da rotina farmacêutica
                  </p>
                </div>
              </div>

              <div className="bg-gray-50 p-6 rounded-lg">
                <div className="text-center">
                  <div className="h-12 w-12 text-indigo-600 mx-auto">
                    <Award className="h-12 w-12" />
                  </div>
                  <h3 className="mt-4 text-lg font-medium text-gray-900">Certificado Reconhecido</h3>
                  <p className="mt-2 text-gray-500">
                    Certificação valorizada pela indústria farmacêutica
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Diferenciais Section */}
        <div className="py-16 bg-gray-50">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h2 className="text-3xl font-extrabold text-gray-900">
                Diferenciais dos Nossos Cursos
              </h2>
              <p className="mt-4 text-xl text-gray-500">
                Aprenda estatística farmacêutica com quem entende do assunto
              </p>
            </div>

            <div className="mt-12 grid gap-8 lg:grid-cols-2">
              <div className="bg-white p-6 rounded-lg shadow-lg">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  Conteúdo Especializado
                </h3>
                <ul className="space-y-4">
                  <li className="flex items-start">
                    <CheckCircle className="h-6 w-6 text-green-500 mr-2 flex-shrink-0" />
                    <span>Validação de Processos Farmacêuticos</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="h-6 w-6 text-green-500 mr-2 flex-shrink-0" />
                    <span>Controle Estatístico de Qualidade</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="h-6 w-6 text-green-500 mr-2 flex-shrink-0" />
                    <span>Análise de Dados de Estabilidade</span>
                  </li>
                  <li className="flex items-start">
                    <CheckCircle className="h-6 w-6 text-green-500 mr-2 flex-shrink-0" />
                    <span>Validação de Métodos Analíticos</span>
                  </li>
                </ul>
              </div>

              <div className="bg-white p-6 rounded-lg shadow-lg">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  Metodologia
                </h3>
                <ul className="space-y-4">
                  <li className="flex items-start">
                    <Star className="h-6 w-6 text-yellow-500 mr-2 flex-shrink-0" />
                    <span>Aulas Online com Exemplos Práticos</span>
                  </li>
                  <li className="flex items-start">
                    <Star className="h-6 w-6 text-yellow-500 mr-2 flex-shrink-0" />
                    <span>Material Didático Completo</span>
                  </li>
                  <li className="flex items-start">
                    <Star className="h-6 w-6 text-yellow-500 mr-2 flex-shrink-0" />
                    <span>Exercícios e Estudos de Caso</span>
                  </li>
                  <li className="flex items-start">
                    <Star className="h-6 w-6 text-yellow-500 mr-2 flex-shrink-0" />
                    <span>Suporte Técnico Especializado</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        {/* Courses Section */}
        <div className="py-16 bg-white">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="text-center">
              <h2 className="text-3xl font-extrabold text-gray-900">
                Cursos de Estatística Farmacêutica
              </h2>
              <p className="mt-4 text-xl text-gray-500">
                Escolha o curso ideal para sua especialização
              </p>
            </div>

            {loading ? (
              <div className="mt-12 flex justify-center">
                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
              </div>
            ) : (
              <div className="mt-12 grid gap-8 lg:grid-cols-3">
                {courses.map((course) => (
                  <div
                    key={course.id}
                    className="bg-white rounded-lg shadow-lg overflow-hidden hover:shadow-xl transition-shadow duration-300"
                  >
                    {course.image_url && (
                      <img
                        src={course.image_url}
                        alt={course.title}
                        className="w-full h-48 object-cover"
                      />
                    )}
                    <div className="p-6">
                      <h3 className="text-xl font-semibold text-gray-900 mb-2">
                        {course.title}
                      </h3>
                      <p className="text-gray-600 mb-4 line-clamp-3">
                        {course.description}
                      </p>
                      <div className="flex items-center justify-between mt-4">
                        <span className="text-2xl font-bold text-gray-900">
                          R$ {course.price.toFixed(2)}
                        </span>
                        <button
                          onClick={() => navigate(`/curso/${course.id}`)}
                          className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                        >
                          Ver Detalhes
                        </button>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* CTA Section */}
        <div className="bg-indigo-600 text-white py-16">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h2 className="text-3xl font-extrabold">
              Pronto para dominar estatística farmacêutica?
            </h2>
            <p className="mt-4 text-xl text-indigo-100">
              Junte-se a milhares de profissionais que já transformaram sua carreira
            </p>
            <div className="mt-8">
              <button
                onClick={() => navigate('/login')}
                className="inline-flex items-center px-6 py-3 border border-transparent text-base font-medium rounded-md text-indigo-600 bg-white hover:bg-indigo-50"
              >
                Comece Agora
                <ChevronRight className="ml-2 h-5 w-5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
}