import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { 
  Plus, Save, X, ArrowLeft, Upload, 
  FileText, Video, ListOrdered, Edit, Trash2,
  GripVertical, CheckSquare, Presentation
} from 'lucide-react';
import toast from 'react-hot-toast';
import { supabase } from '../lib/supabase';

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

interface Quiz {
  id: string;
  title: string;
  description: string;
  passing_score: number;
  questions: {
    question: string;
    options: string[];
    correct_answer: string;
  }[];
}

export default function CourseEditor() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [course, setCourse] = useState<any>(null);
  const [modules, setModules] = useState<Module[]>([]);
  const [lessons, setLessons] = useState<Record<string, Lesson[]>>({});
  const [quizzes, setQuizzes] = useState<Record<string, Quiz>>({});
  const [editingModule, setEditingModule] = useState<string | null>(null);
  const [editingLesson, setEditingLesson] = useState<string | null>(null);
  const [editingQuiz, setEditingQuiz] = useState<string | null>(null);
  const [uploadingFile, setUploadingFile] = useState<string | null>(null);

  useEffect(() => {
    if (id) {
      loadCourseData();
    }
  }, [id]);

  const loadCourseData = async () => {
    try {
      // Load course details
      const { data: courseData, error: courseError } = await supabase
        .from('courses')
        .select('*')
        .eq('id', id)
        .single();

      if (courseError) throw courseError;
      setCourse(courseData);

      // Load modules
      const { data: moduleData, error: moduleError } = await supabase
        .from('course_modules')
        .select('*')
        .eq('course_id', id)
        .order('order_number');

      if (moduleError) throw moduleError;
      setModules(moduleData || []);

      // Load lessons for each module
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

      // Load quizzes for each module
      const quizzesByModule: Record<string, Quiz> = {};
      for (const module of moduleData || []) {
        const { data: quizData, error: quizError } = await supabase
          .from('course_quizzes')
          .select('*')
          .eq('module_id', module.id)
          .maybeSingle();

        if (quizError) throw quizError;
        if (quizData) {
          quizzesByModule[module.id] = quizData;
        }
      }
      setQuizzes(quizzesByModule);
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao carregar dados do curso');
    } finally {
      setLoading(false);
    }
  };

  const handleAddModule = async () => {
    try {
      const newModule = {
        course_id: id,
        title: 'Novo Módulo',
        description: 'Descrição do módulo',
        order_number: modules.length + 1
      };

      const { data, error } = await supabase
        .from('course_modules')
        .insert([newModule])
        .select()
        .single();

      if (error) throw error;

      setModules([...modules, data]);
      setLessons({ ...lessons, [data.id]: [] });
      toast.success('Módulo adicionado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao adicionar módulo');
    }
  };

  const handleUpdateModule = async (moduleId: string, updates: Partial<Module>) => {
    try {
      const { data, error } = await supabase
        .from('course_modules')
        .update(updates)
        .eq('id', moduleId)
        .select()
        .single();

      if (error) throw error;

      setModules(modules.map(m => m.id === moduleId ? data : m));
      setEditingModule(null);
      toast.success('Módulo atualizado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao atualizar módulo');
    }
  };

  const handleDeleteModule = async (moduleId: string) => {
    if (!confirm('Tem certeza que deseja excluir este módulo e todo seu conteúdo?')) {
      return;
    }

    try {
      const { error } = await supabase
        .from('course_modules')
        .delete()
        .eq('id', moduleId);

      if (error) throw error;

      setModules(modules.filter(m => m.id !== moduleId));
      const newLessons = { ...lessons };
      delete newLessons[moduleId];
      setLessons(newLessons);
      const newQuizzes = { ...quizzes };
      delete newQuizzes[moduleId];
      setQuizzes(newQuizzes);
      toast.success('Módulo excluído com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao excluir módulo');
    }
  };

  const handleAddLesson = async (moduleId: string) => {
    try {
      const newLesson = {
        module_id: moduleId,
        course_id: id,
        title: 'Nova Lição',
        description: 'Descrição da lição',
        content_type: 'video',
        content_url: '',
        order_number: (lessons[moduleId]?.length || 0) + 1
      };

      const { data, error } = await supabase
        .from('course_lessons')
        .insert([newLesson])
        .select()
        .single();

      if (error) throw error;

      setLessons({
        ...lessons,
        [moduleId]: [...(lessons[moduleId] || []), data]
      });
      toast.success('Lição adicionada com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao adicionar lição');
    }
  };

  const handleUpdateLesson = async (moduleId: string, lessonId: string, updates: Partial<Lesson>) => {
    try {
      const { data, error } = await supabase
        .from('course_lessons')
        .update(updates)
        .eq('id', lessonId)
        .select()
        .single();

      if (error) throw error;

      setLessons({
        ...lessons,
        [moduleId]: lessons[moduleId].map(l => l.id === lessonId ? data : l)
      });
      setEditingLesson(null);
      toast.success('Lição atualizada com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao atualizar lição');
    }
  };

  const handleDeleteLesson = async (moduleId: string, lessonId: string) => {
    if (!confirm('Tem certeza que deseja excluir esta lição?')) {
      return;
    }

    try {
      const { error } = await supabase
        .from('course_lessons')
        .delete()
        .eq('id', lessonId);

      if (error) throw error;

      setLessons({
        ...lessons,
        [moduleId]: lessons[moduleId].filter(l => l.id !== lessonId)
      });
      toast.success('Lição excluída com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao excluir lição');
    }
  };

  const handleFileUpload = async (moduleId: string, lessonId: string, file: File) => {
    try {
      setUploadingFile(lessonId);

      const lesson = lessons[moduleId].find(l => l.id === lessonId);
      if (!lesson) throw new Error('Lição não encontrada');

      let bucket = 'course-documents';
      if (lesson.content_type === 'video') {
        bucket = 'course-videos';
      } else if (lesson.content_type === 'presentation') {
        bucket = 'course-presentations';
      }

      const fileName = `${id}/${moduleId}/${lessonId}/${file.name}`;

      const { error: uploadError } = await supabase.storage
        .from(bucket)
        .upload(fileName, file, {
          cacheControl: '3600',
          upsert: true
        });

      if (uploadError) throw uploadError;

      const { data: { publicUrl } } = supabase.storage
        .from(bucket)
        .getPublicUrl(fileName);

      await handleUpdateLesson(moduleId, lessonId, { content_url: publicUrl });
      toast.success('Arquivo enviado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao enviar arquivo');
    } finally {
      setUploadingFile(null);
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
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <button
            onClick={() => navigate('/admin')}
            className="inline-flex items-center text-indigo-600 hover:text-indigo-700"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar para Administração
          </button>
          <h1 className="text-3xl font-bold text-gray-900 mt-4">
            Editar Curso: {course?.title}
          </h1>
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <h2 className="text-xl font-semibold text-gray-900 mb-6">
            Módulos e Conteúdo
          </h2>

          <div className="space-y-6">
            {modules.map((module) => (
              <div
                key={module.id}
                className="border border-gray-200 rounded-lg p-4"
              >
                {editingModule === module.id ? (
                  <div className="space-y-4">
                    <input
                      type="text"
                      value={module.title}
                      onChange={(e) => setModules(modules.map(m =>
                        m.id === module.id ? { ...m, title: e.target.value } : m
                      ))}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      placeholder="Título do módulo"
                    />
                    <textarea
                      value={module.description}
                      onChange={(e) => setModules(modules.map(m =>
                        m.id === module.id ? { ...m, description: e.target.value } : m
                      ))}
                      className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      placeholder="Descrição do módulo"
                      rows={3}
                    />
                    <div className="flex justify-end space-x-3">
                      <button
                        onClick={() => setEditingModule(null)}
                        className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                      >
                        Cancelar
                      </button>
                      <button
                        onClick={() => handleUpdateModule(module.id, {
                          title: module.title,
                          description: module.description
                        })}
                        className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                      >
                        <Save className="w-4 h-4 mr-2" />
                        Salvar
                      </button>
                    </div>
                  </div>
                ) : (
                  <div>
                    <div className="flex items-center justify-between mb-4">
                      <div>
                        <h3 className="text-lg font-medium text-gray-900">
                          {module.title}
                        </h3>
                        <p className="mt-1 text-sm text-gray-500">
                          {module.description}
                        </p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => setEditingModule(module.id)}
                          className="p-1 text-gray-400 hover:text-gray-500"
                          title="Editar módulo"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleDeleteModule(module.id)}
                          className="p-1 text-red-400 hover:text-red-500"
                          title="Excluir módulo"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>

                    {/* Lessons */}
                    <div className="space-y-4 mb-4">
                      {lessons[module.id]?.map((lesson) => (
                        <div
                          key={lesson.id}
                          className="bg-gray-50 rounded-lg p-4"
                        >
                          {editingLesson === lesson.id ? (
                            <div className="space-y-4">
                              <input
                                type="text"
                                value={lesson.title}
                                onChange={(e) => setLessons({
                                  ...lessons,
                                  [module.id]: lessons[module.id].map(l =>
                                    l.id === lesson.id ? { ...l, title: e.target.value } : l
                                  )
                                })}
                                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                placeholder="Título da lição"
                              />
                              <textarea
                                value={lesson.description}
                                onChange={(e) => setLessons({
                                  ...lessons,
                                  [module.id]: lessons[module.id].map(l =>
                                    l.id === lesson.id ? { ...l, description: e.target.value } : l
                                  )
                                })}
                                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                                placeholder="Descrição da lição"
                                rows={3}
                              />
                              <select
                                value={lesson.content_type}
                                onChange={(e) => setLessons({
                                  ...lessons,
                                  [module.id]: lessons[module.id].map(l =>
                                    l.id === lesson.id ? { ...l, content_type: e.target.value as 'video' | 'pdf' | 'presentation' } : l
                                  )
                                })}
                                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                              >
                                <option value="video">Vídeo</option>
                                <option value="pdf">PDF</option>
                                <option value="presentation">Apresentação</option>
                              </select>
                              <div className="flex justify-end space-x-3">
                                <button
                                  onClick={() => setEditingLesson(null)}
                                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                                >
                                  Cancelar
                                </button>
                                <button
                                  onClick={() => handleUpdateLesson(module.id, lesson.id, {
                                    title: lesson.title,
                                    description: lesson.description,
                                    content_type: lesson.content_type
                                  })}
                                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                                >
                                  <Save className="w-4 h-4 mr-2" />
                                  Salvar
                                </button>
                              </div>
                            </div>
                          ) : (
                            <div className="flex items-center justify-between">
                              <div>
                                <h4 className="text-sm font-medium text-gray-900">
                                  {lesson.title}
                                </h4>
                                <p className="mt-1 text-sm text-gray-500">
                                  {lesson.description}
                                </p>
                                <div className="mt-2 flex items-center space-x-4">
                                  <span className="inline-flex items-center text-sm text-gray-500">
                                    {lesson.content_type === 'video' ? (
                                      <Video className="w-4 h-4 mr-1" />
                                    ) : lesson.content_type === 'presentation' ? (
                                      <Presentation className="w-4 h-4 mr-1" />
                                    ) : (
                                      <FileText className="w-4 h-4 mr-1" />
                                    )}
                                    {lesson.content_type === 'video' ? 'Vídeo' : lesson.content_type === 'presentation' ? 'Apresentação' : 'PDF'}
                                  </span>
                                  {lesson.content_url && (
                                    <a
                                      href={lesson.content_url}
                                      target="_blank"
                                      rel="noopener noreferrer"
                                      className="text-sm text-indigo-600 hover:text-indigo-500"
                                    >
                                      Ver conteúdo
                                    </a>
                                  )}
                                </div>
                              </div>
                              <div className="flex items-center space-x-2">
                                <label className="cursor-pointer">
                                  <input
                                    type="file"
                                    className="hidden"
                                    accept={lesson.content_type === 'video' ? 'video/*' : 'application/pdf'}
                                    onChange={(e) => {
                                      const file = e.target.files?.[0];
                                      if (file) {
                                        handleFileUpload(module.id, lesson.id, file);
                                      }
                                    }}
                                  />
                                  <Upload
                                    className={`w-4 h-4 ${
                                      uploadingFile === lesson.id
                                        ? 'text-gray-400 animate-spin'
                                        : 'text-gray-400 hover:text-gray-500'
                                    }`}
                                  />
                                </label>
                                <button
                                  onClick={() => setEditingLesson(lesson.id)}
                                  className="p-1 text-gray-400 hover:text-gray-500"
                                  title="Editar lição"
                                >
                                  <Edit className="w-4 h-4" />
                                </button>
                                <button
                                  onClick={() => handleDeleteLesson(module.id, lesson.id)}
                                  className="p-1 text-red-400 hover:text-red-500"
                                  title="Excluir lição"
                                >
                                  <Trash2 className="w-4 h-4" />
                                </button>
                              </div>
                            </div>
                          )}
                        </div>
                      ))}
                    </div>

                    <div className="flex space-x-2">
                      <button
                        onClick={() => handleAddLesson(module.id)}
                        className="inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                      >
                        <Plus className="w-4 h-4 mr-2" />
                        Adicionar Lição
                      </button>
                    </div>
                  </div>
                )}
              </div>
            ))}

            <button
              onClick={handleAddModule}
              className="w-full py-4 border-2 border-dashed border-gray-300 rounded-lg text-center text-gray-600 hover:border-indigo-500 hover:text-indigo-500 transition-colors"
            >
              <Plus className="w-6 h-6 mx-auto mb-2" />
              Adicionar Módulo
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}