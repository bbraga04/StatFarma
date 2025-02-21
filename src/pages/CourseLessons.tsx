import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  Clock, Award, ChevronLeft, Download, AlertCircle,
  Play, FileText, Lock, CheckCircle, X, Presentation
} from 'lucide-react';
import toast from 'react-hot-toast';
import { supabase } from '../lib/supabase';
import ContentViewer from '../components/ContentViewer';

interface Course {
  id: string;
  title: string;
  description: string;
}

interface Module {
  id: string;
  title: string;
  description: string;
  order_number: number;
}

interface Lesson {
  id: string;
  title: string;
  description: string;
  content_type: 'video' | 'pdf' | 'presentation';
  content_url: string;
  order_number: number;
}

interface LessonProgress {
  completed: boolean;
  completed_at: string | null;
  last_position: string;
  last_accessed_at: string;
}

interface CertificateRequest {
  id: string;
  status: 'pending' | 'approved' | 'rejected';
  certificate_url: string | null;
  created_at: string;
}

export default function CourseLessons() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [course, setCourse] = useState<Course | null>(null);
  const [modules, setModules] = useState<Module[]>([]);
  const [lessons, setLessons] = useState<Record<string, Lesson[]>>({});
  const [progress, setProgress] = useState<Record<string, LessonProgress>>({});
  const [loading, setLoading] = useState(true);
  const [selectedLesson, setSelectedLesson] = useState<Lesson | null>(null);
  const [updatingProgress, setUpdatingProgress] = useState(false);
  const [completionPercentage, setCompletionPercentage] = useState(0);
  const [showCertificateModal, setShowCertificateModal] = useState(false);
  const [fullName, setFullName] = useState('');
  const [requestingCertificate, setRequestingCertificate] = useState(false);
  const [certificateRequest, setCertificateRequest] = useState<CertificateRequest | null>(null);

  useEffect(() => {
    if (id) {
      fetchCourseData();
      fetchCertificateRequest();
    }
  }, [id]);

  useEffect(() => {
    calculateCompletionPercentage();
  }, [progress, lessons]);

  const calculateCompletionPercentage = () => {
    const totalLessons = Object.values(lessons).reduce((sum, moduleLessons) => sum + moduleLessons.length, 0);
    const completedLessons = Object.values(progress).filter(p => p.completed).length;
    const percentage = totalLessons > 0 ? (completedLessons / totalLessons) * 100 : 0;
    setCompletionPercentage(Math.round(percentage));
  };

  const fetchCertificateRequest = async () => {
    if (!id) return;

    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data, error } = await supabase
        .from('certificate_requests')
        .select('*')
        .eq('user_id', user.id)
        .eq('course_id', id)
        .maybeSingle();

      if (error && error.code !== 'PGRST116') throw error;
      if (data) setCertificateRequest(data);
    } catch (error) {
      console.error('Error fetching certificate request:', error);
    }
  };

  const handleRequestCertificate = async () => {
    if (!id || !fullName.trim() || requestingCertificate) return;

    try {
      setRequestingCertificate(true);

      const { data, error } = await supabase
        .rpc('request_certificate', {
          p_course_id: id,
          p_full_name: fullName.trim()
        });

      if (error) {
        if (error.message === 'Certificate already requested') {
          toast.error('Você já solicitou o certificado para este curso');
        } else if (error.message === 'Course not completed') {
          toast.error('Complete o curso primeiro para solicitar o certificado');
        } else {
          throw error;
        }
        return;
      }

      await fetchCertificateRequest();
      setShowCertificateModal(false);
      toast.success('Solicitação de certificado enviada com sucesso!');
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao solicitar certificado');
    } finally {
      setRequestingCertificate(false);
    }
  };

  const fetchCourseData = async () => {
    if (!id) {
      navigate('/');
      return;
    }

    try {
      const { data: courseData, error: courseError } = await supabase
        .from('courses')
        .select('*')
        .eq('id', id)
        .single();

      if (courseError) throw courseError;
      setCourse(courseData);

      const { data: moduleData, error: moduleError } = await supabase
        .from('course_modules')
        .select('*')
        .eq('course_id', id)
        .order('order_number');

      if (moduleError) throw moduleError;
      setModules(moduleData || []);

      const lessonsByModule: Record<string, Lesson[]> = {};
      for (const module of moduleData || []) {
        const { data: lessonData, error: lessonError } = await supabase
          .from('course_lessons')
          .select('*')
          .eq('module_id', module.id)
          .order('order_number');

        if (lessonError) throw lessonError;
        lessonsByModule[module.id] = lessonData || [];
      }
      setLessons(lessonsByModule);

      const allLessons = Object.values(lessonsByModule).flat();
      if (allLessons.length > 0) {
        const { data: progressData, error: progressError } = await supabase
          .from('lesson_progress')
          .select('*')
          .in('lesson_id', allLessons.map(l => l.id));

        if (progressError) throw progressError;

        const progressByLesson = (progressData || []).reduce((acc, p) => ({
          ...acc,
          [p.lesson_id]: {
            completed: p.completed,
            completed_at: p.completed_at,
            last_position: p.last_position,
            last_accessed_at: p.last_accessed_at
          }
        }), {});

        setProgress(progressByLesson);
      }
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar o curso');
      navigate('/');
    } finally {
      setLoading(false);
    }
  };

  const handleLessonClick = async (lesson: Lesson) => {
    try {
      const { data: canAccess, error: accessError } = await supabase
        .rpc('can_access_lesson', {
          p_lesson_id: lesson.id,
          p_user_id: (await supabase.auth.getUser()).data.user?.id
        });

      if (accessError) throw accessError;

      if (!canAccess) {
        toast.error('Complete a lição anterior primeiro');
        return;
      }

      setSelectedLesson(lesson);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Usuário não autenticado');
        return;
      }

      const now = new Date().toISOString();

      const { error: progressError } = await supabase
        .from('lesson_progress')
        .upsert({
          lesson_id: lesson.id,
          user_id: user.id,
          last_accessed_at: now
        }, {
          onConflict: 'user_id,lesson_id'
        });

      if (progressError) throw progressError;

      setProgress(prev => ({
        ...prev,
        [lesson.id]: {
          ...prev[lesson.id],
          last_accessed_at: now
        }
      }));
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao acessar lição');
    }
  };

  const markLessonComplete = async (lessonId: string) => {
    if (updatingProgress) return;

    try {
      setUpdatingProgress(true);

      const { data: { user } } = await supabase.auth.getUser();
      if (!user) {
        toast.error('Usuário não autenticado');
        return;
      }

      const now = new Date().toISOString();

      const { error } = await supabase
        .from('lesson_progress')
        .upsert({
          lesson_id: lessonId,
          user_id: user.id,
          completed: true,
          completed_at: now,
          last_accessed_at: now
        }, {
          onConflict: 'user_id,lesson_id'
        });

      if (error) throw error;

      setProgress(prev => ({
        ...prev,
        [lessonId]: {
          ...prev[lessonId],
          completed: true,
          completed_at: now,
          last_accessed_at: now
        }
      }));

      toast.success('Lição concluída!');
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao marcar lição como concluída');
    } finally {
      setUpdatingProgress(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando curso...</p>
        </div>
      </div>
    );
  }

  if (!course) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-xl text-gray-600 mb-4">Curso não encontrado</p>
          <button
            onClick={() => navigate('/dashboard')}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Voltar para Dashboard
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <button
            onClick={() => navigate('/dashboard')}
            className="inline-flex items-center text-indigo-600 hover:text-indigo-700"
          >
            <ChevronLeft className="w-4 h-4 mr-1" />
            Voltar para Dashboard
          </button>
          <h1 className="text-3xl font-bold text-gray-900 mt-4">{course.title}</h1>
          
          {/* Progress Bar */}
          <div className="mt-4 bg-gray-200 rounded-full h-4 overflow-hidden">
            <div 
              className="h-full bg-indigo-600 transition-all duration-500"
              style={{ width: `${completionPercentage}%` }}
            />
          </div>
          <div className="mt-2 flex items-center justify-between">
            <div className="flex items-center text-sm text-gray-600">
              <Clock className="w-4 h-4 mr-2" />
              <span>Progresso: {completionPercentage}% concluído</span>
            </div>
            {completionPercentage === 100 && !certificateRequest && (
              <button
                onClick={() => setShowCertificateModal(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
              >
                <Award className="w-4 h-4 mr-2" />
                Solicitar Certificado
              </button>
            )}
            {certificateRequest && (
              <div className="flex items-center text-sm">
                {certificateRequest.status === 'pending' && (
                  <span className="text-yellow-600">Certificado em análise</span>
                )}
                {certificateRequest.status === 'approved' && certificateRequest.certificate_url && (
                  <a
                    href={certificateRequest.certificate_url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700"
                  >
                    <Download className="w-4 h-4 mr-2" />
                    Ver Certificado
                  </a>
                )}
                {certificateRequest.status === 'rejected' && (
                  <span className="text-red-600">Solicitação de certificado rejeitada</span>
                )}
              </div>
            )}
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Sidebar with modules and lessons */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-lg shadow-sm p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Conteúdo do Curso</h2>
              <div className="space-y-6">
                {modules.map((module) => (
                  <div key={module.id}>
                    <h3 className="text-sm font-medium text-gray-900 mb-2">
                      {module.title}
                    </h3>
                    <div className="space-y-2">
                      {lessons[module.id]?.map((lesson) => {
                        const lessonProgress = progress[lesson.id];
                        const isCompleted = lessonProgress?.completed;
                        
                        return (
                          <button
                            key={lesson.id}
                            onClick={() => handleLessonClick(lesson)}
                            className={`w-full text-left p-3 rounded-lg flex items-center space-x-3 ${
                              selectedLesson?.id === lesson.id
                                ? 'bg-indigo-50 text-indigo-700'
                                : 'hover:bg-gray-50'
                            }`}
                          >
                            {lesson.content_type === 'video' ? (
                              <Play className="w-4 h-4" />
                            ) : lesson.content_type === 'presentation' ? (
                              <Presentation className="w-4 h-4" />
                            ) : (
                              <FileText className="w-4 h-4" />
                            )}
                            <span className="flex-1 text-sm">
                              {lesson.title}
                            </span>
                            {isCompleted ? (
                              <CheckCircle className="w-4 h-4 text-green-500 flex-shrink-0" />
                            ) : (
                              <Lock className="w-4 h-4 text-gray-400 flex-shrink-0" />
                            )}
                          </button>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Main content area */}
          <div className="lg:col-span-2">
            {selectedLesson ? (
              <div className="bg-white rounded-lg shadow-sm p-6">
                <h2 className="text-xl font-semibold text-gray-900 mb-4">
                  {selectedLesson.title}
                </h2>
                
                {selectedLesson.description && (
                  <p className="text-gray-600 mb-6">{selectedLesson.description}</p>
                )}

                <div className="mb-6">
                  <ContentViewer
                    type={selectedLesson.content_type}
                    url={selectedLesson.content_url}
                    title={selectedLesson.title}
                  />
                </div>

                {!progress[selectedLesson.id]?.completed && (
                  <button
                    onClick={() => markLessonComplete(selectedLesson.id)}
                    disabled={updatingProgress}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
                  >
                    <CheckCircle className="w-4 h-4 mr-2" />
                    {updatingProgress ? 'Salvando...' : 'Marcar como Concluída'}
                  </button>
                )}
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow-sm p-6 text-center">
                <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">
                  Selecione uma lição
                </h3>
                <p className="text-gray-500">
                  Escolha uma lição no menu ao lado para começar a estudar
                </p>
              </div>
            )}
          </div>
        </div>

        {/* Certificate Request Modal */}
        {showCertificateModal && (
          <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4">
            <div className="bg-white rounded-lg max-w-md w-full p-6">
              <div className="flex justify-between items-center mb-4">
                <h3 className="text-lg font-medium text-gray-900">
                  Solicitar Certificado
                </h3>
                <button
                  onClick={() => setShowCertificateModal(false)}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>
              
              <p className="text-sm text-gray-500 mb-4">
                Parabéns por completar o curso! Preencha seu nome completo como deseja que apareça no certificado.
              </p>

              <div className="mb-4">
                <label htmlFor="fullName" className="block text-sm font-medium text-gray-700">
                  Nome Completo
                </label>
                <input
                  type="text"
                  id="fullName"
                  value={fullName}
                  onChange={(e) => setFullName(e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                  placeholder="Digite seu nome completo"
                />
              </div>

              <div className="flex justify-end space-x-3">
                <button
                  onClick={() => setShowCertificateModal(false)}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                >
                  Cancelar
                </button>
                <button
                  onClick={handleRequestCertificate}
                  disabled={!fullName.trim() || requestingCertificate}
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
                >
                  {requestingCertificate ? (
                    <>
                      <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2" />
                      Solicitando...
                    </>
                  ) : (
                    <>
                      <Award className="w-4 h-4 mr-2" />
                      Solicitar Certificado
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}