import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { 
  LogOut, BookOpen, Shield, User, Clock, Award, 
  ChevronRight, Download, AlertCircle 
} from 'lucide-react';
import toast from 'react-hot-toast';

interface Course {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url?: string;
}

interface CourseProgress {
  course_id: string;
  completed: boolean;
  completed_at: string | null;
  last_accessed_at: string;
  completion_percentage: number;
}

interface Certificate {
  id: string;
  course_id: string;
  status: 'pending' | 'approved' | 'rejected';
  certificate_url: string | null;
  created_at: string;
  course: {
    title: string;
    description: string;
  };
}

export default function Dashboard() {
  const navigate = useNavigate();
  const [user, setUser] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [enrolledCourses, setEnrolledCourses] = useState<Course[]>([]);
  const [courseProgress, setProgress] = useState<Record<string, CourseProgress>>({});
  const [certificates, setCertificates] = useState<Certificate[]>([]);
  const [activeTab, setActiveTab] = useState<'courses' | 'certificates'>('courses');

  useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      setUser(user);
      setIsAdmin(user?.app_metadata?.is_admin ?? false);
      if (user) {
        await Promise.all([
          fetchEnrolledCourses(user.id),
          fetchCertificates(user.id)
        ]);
      } else {
        setLoading(false);
      }
    };
    getUser();
  }, []);

  const fetchEnrolledCourses = async (userId: string) => {
    try {
      const { data: enrollments, error: enrollmentError } = await supabase
        .from('user_courses')
        .select('course_id')
        .eq('user_id', userId);

      if (enrollmentError) throw enrollmentError;

      if (enrollments && enrollments.length > 0) {
        const courseIds = enrollments.map(e => e.course_id);
        
        const { data: courses, error: coursesError } = await supabase
          .from('courses')
          .select('*')
          .in('id', courseIds);

        if (coursesError) throw coursesError;

        // Fetch progress for each course
        const progressPromises = courseIds.map(async (courseId) => {
          const { data: completedLessons } = await supabase
            .from('lesson_progress')
            .select('*')
            .eq('user_id', userId)
            .eq('completed', true);

          const { data: totalLessons } = await supabase
            .from('course_lessons')
            .select('*')
            .eq('course_id', courseId);

          const completionPercentage = totalLessons?.length 
            ? (completedLessons?.length || 0) / totalLessons.length * 100 
            : 0;

          return {
            course_id: courseId,
            completion_percentage: Math.round(completionPercentage)
          };
        });

        const progressResults = await Promise.all(progressPromises);
        const progressLookup = progressResults.reduce((acc, p) => ({
          ...acc,
          [p.course_id]: p
        }), {});

        setEnrolledCourses(courses || []);
        setProgress(progressLookup);
      }
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar cursos matriculados');
    } finally {
      setLoading(false);
    }
  };

  const fetchCertificates = async (userId: string) => {
    try {
      const { data, error } = await supabase
        .from('certificate_requests')
        .select(`
          *,
          course:courses (
            title,
            description
          )
        `)
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCertificates(data || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar certificados');
    }
  };

  const handleLogout = async () => {
    try {
      await supabase.auth.signOut();
      setUser(null);
      setIsAdmin(false);
      navigate('/');
    } catch (error) {
      console.error('Error:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto py-6 px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center">
            <div>
              <h1 className="text-3xl font-bold text-gray-900">Minha Área</h1>
              <div className="mt-1 flex items-center">
                {isAdmin ? (
                  <div className="flex items-center text-indigo-600">
                    <Shield className="h-5 w-5 mr-2" />
                    <span className="font-medium">Administrador</span>
                  </div>
                ) : (
                  <div className="flex items-center text-gray-600">
                    <User className="h-5 w-5 mr-2" />
                    <span className="font-medium">Aluno</span>
                  </div>
                )}
              </div>
            </div>
            <button
              onClick={handleLogout}
              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Sair
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {/* Seção de Boas-vindas */}
        <div className="px-4 py-6 sm:px-0">
          <div className="bg-white rounded-lg shadow-sm p-6 mb-6">
            <h2 className="text-xl font-semibold text-gray-900 mb-2">
              Bem-vindo(a), {user?.user_metadata?.name || 'Aluno'}!
            </h2>
            <p className="text-gray-600">
              {isAdmin 
                ? 'Como administrador, você tem acesso a todas as funcionalidades da plataforma.'
                : 'Aqui você pode acompanhar seus cursos e certificados.'}
            </p>
          </div>
        </div>

        {/* Tabs */}
        <div className="px-4 sm:px-0">
          <div className="border-b border-gray-200">
            <nav className="-mb-px flex space-x-8">
              <button
                onClick={() => setActiveTab('courses')}
                className={`
                  py-4 px-1 border-b-2 font-medium text-sm
                  ${activeTab === 'courses'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
                `}
              >
                <BookOpen className="w-5 h-5 inline-block mr-2" />
                Meus Cursos
              </button>
              <button
                onClick={() => setActiveTab('certificates')}
                className={`
                  py-4 px-1 border-b-2 font-medium text-sm
                  ${activeTab === 'certificates'
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'}
                `}
              >
                <Award className="w-5 h-5 inline-block mr-2" />
                Meus Certificados
              </button>
            </nav>
          </div>
        </div>

        {/* Content */}
        <div className="px-4 py-6 sm:px-0">
          {activeTab === 'courses' ? (
            <>
              {enrolledCourses.length === 0 ? (
                <div className="bg-white rounded-lg border-4 border-dashed border-gray-200 p-8">
                  <div className="text-center">
                    <BookOpen className="mx-auto h-12 w-12 text-gray-400" />
                    <h3 className="mt-2 text-sm font-medium text-gray-900">
                      Nenhum curso matriculado
                    </h3>
                    <p className="mt-1 text-sm text-gray-500">
                      Comece agora mesmo a sua jornada de aprendizado.
                    </p>
                    <div className="mt-6">
                      <button
                        onClick={() => navigate('/')}
                        className="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                      >
                        Ver catálogo de cursos
                      </button>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="grid gap-6 lg:grid-cols-2">
                  {enrolledCourses.map((course) => {
                    const progress = courseProgress[course.id];
                    return (
                      <div
                        key={course.id}
                        className="bg-white rounded-lg shadow-sm overflow-hidden hover:shadow-md transition-shadow"
                      >
                        {course.image_url && (
                          <img
                            src={course.image_url}
                            alt={course.title}
                            className="w-full h-48 object-cover"
                          />
                        )}
                        <div className="p-6">
                          <h4 className="text-lg font-semibold text-gray-900 mb-2">
                            {course.title}
                          </h4>
                          
                          <div className="flex items-center space-x-4 text-sm text-gray-500 mb-4">
                            <div className="flex items-center">
                              <Clock className="h-4 w-4 mr-1" />
                              <span>
                                Progresso: {progress?.completion_percentage || 0}%
                              </span>
                            </div>
                            {progress?.completion_percentage === 100 && (
                              <div className="flex items-center text-green-600">
                                <Award className="h-4 w-4 mr-1" />
                                <span>Concluído</span>
                              </div>
                            )}
                          </div>

                          {/* Progress bar */}
                          <div className="w-full bg-gray-200 rounded-full h-2.5 mb-4">
                            <div 
                              className="bg-indigo-600 h-2.5 rounded-full transition-all duration-500"
                              style={{ width: `${progress?.completion_percentage || 0}%` }}
                            ></div>
                          </div>

                          <button
                            onClick={() => navigate(`/curso/${course.id}/aulas`)}
                            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                          >
                            Acessar Curso
                            <ChevronRight className="ml-2 h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </>
          ) : (
            <>
              {certificates.length === 0 ? (
                <div className="bg-white rounded-lg border-4 border-dashed border-gray-200 p-8">
                  <div className="text-center">
                    <Award className="mx-auto h-12 w-12 text-gray-400" />
                    <h3 className="mt-2 text-sm font-medium text-gray-900">
                      Nenhum certificado disponível
                    </h3>
                    <p className="mt-1 text-sm text-gray-500">
                      Complete um curso para solicitar seu certificado.
                    </p>
                  </div>
                </div>
              ) : (
                <div className="space-y-6">
                  {certificates.map((cert) => (
                    <div
                      key={cert.id}
                      className="bg-white rounded-lg shadow-sm p-6"
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <h4 className="text-lg font-semibold text-gray-900">
                            {cert.course?.title || 'Curso não encontrado'}
                          </h4>
                          <p className="mt-1 text-sm text-gray-500">
                            Solicitado em: {new Date(cert.created_at).toLocaleDateString('pt-BR')}
                          </p>
                        </div>
                        <div className="flex items-center space-x-4">
                          {cert.status === 'pending' && (
                            <div className="flex items-center text-yellow-600">
                              <AlertCircle className="h-5 w-5 mr-2" />
                              <span>Em análise</span>
                            </div>
                          )}
                          {cert.status === 'approved' && cert.certificate_url && (
                            <a
                              href={cert.certificate_url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                            >
                              <Download className="h-4 w-4 mr-2" />
                              Baixar Certificado
                            </a>
                          )}
                          {cert.status === 'rejected' && (
                            <div className="flex items-center text-red-600">
                              <AlertCircle className="h-5 w-5 mr-2" />
                              <span>Solicitação rejeitada</span>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </>
          )}
        </div>

        {/* Links Rápidos para Administradores */}
        {isAdmin && (
          <div className="px-4 py-6 sm:px-0">
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">
                Acesso Rápido
              </h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <button
                  onClick={() => navigate('/admin')}
                  className="flex items-center justify-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                >
                  <Shield className="h-4 w-4 mr-2" />
                  Painel Administrativo
                </button>
                <button
                  onClick={() => navigate('/perfil')}
                  className="flex items-center justify-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                >
                  <User className="h-4 w-4 mr-2" />
                  Meu Perfil
                </button>
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}