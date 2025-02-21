import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Trash2, Edit, Plus, X, Save, 
  DollarSign, Image, FileText, Check,
  UserPlus, Users, Award, Download,
  XCircle, UserMinus, Upload, RefreshCw,
  ChevronRight
} from 'lucide-react';
import toast from 'react-hot-toast';
import { supabase, unenrollUserFromCourse } from '../lib/supabase';

interface Course {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url?: string;
  status: 'draft' | 'published' | 'archived';
  visible: boolean;
}

interface User {
  id: string;
  name: string;
  created_at: string;
}

interface UserCourse {
  user_id: string;
  course_id: string;
}

interface CertificateRequest {
  id: string;
  user_id: string;
  course_id: string;
  status: 'pending' | 'approved' | 'rejected';
  certificate_url: string | null;
  created_at: string;
  full_name: string;
  course: {
    title: string;
    description: string;
  };
}

export default function Admin() {
  const navigate = useNavigate();
  const [courses, setCourses] = useState<Course[]>([]);
  const [users, setUsers] = useState<User[]>([]);
  const [userCourses, setUserCourses] = useState<UserCourse[]>([]);
  const [certificateRequests, setCertificateRequests] = useState<CertificateRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingCourse, setEditingCourse] = useState<Course | null>(null);
  const [isAddingCourse, setIsAddingCourse] = useState(false);
  const [showEnrollments, setShowEnrollments] = useState(false);
  const [showCertificates, setShowCertificates] = useState(false);
  const [uploadingCertificate, setUploadingCertificate] = useState<string | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    price: 0,
    image_url: '',
    visible: false
  });

  useEffect(() => {
    checkAdmin();
    fetchCourses();
    fetchUsers();
    fetchUserCourses();
    fetchCertificateRequests();
  }, []);

  const checkAdmin = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        toast.error('Você precisa estar logado');
        navigate('/login');
        return;
      }

      const isAdmin = user.app_metadata?.is_admin;
      
      if (!isAdmin) {
        toast.error('Acesso não autorizado');
        navigate('/');
        return;
      }
    } catch (error) {
      console.error('Error checking admin:', error);
      toast.error('Erro ao verificar permissões');
      navigate('/');
    }
  };

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

  const fetchUsers = async () => {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('id, name, created_at');

      if (error) throw error;
      setUsers(data || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar usuários');
    }
  };

  const fetchUserCourses = async () => {
    try {
      const { data, error } = await supabase
        .from('user_courses')
        .select('*');

      if (error) throw error;
      setUserCourses(data || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar matrículas');
    }
  };

  const fetchCertificateRequests = async () => {
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
        .order('created_at', { ascending: false });

      if (error) throw error;
      setCertificateRequests(data || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar solicitações de certificado');
    }
  };

  const handleAddCourse = async () => {
    try {
      if (!formData.title || !formData.description || formData.price <= 0) {
        toast.error('Preencha todos os campos obrigatórios');
        return;
      }

      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user?.app_metadata?.is_admin) {
        toast.error('Acesso não autorizado');
        return;
      }

      const { data, error } = await supabase
        .from('courses')
        .insert([{
          title: formData.title,
          description: formData.description,
          price: formData.price,
          image_url: formData.image_url || null,
          visible: formData.visible,
          status: 'draft'
        }])
        .select()
        .single();

      if (error) throw error;

      setCourses([data, ...courses]);
      setIsAddingCourse(false);
      setFormData({ title: '', description: '', price: 0, image_url: '', visible: false });
      toast.success('Curso adicionado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error(error.message || 'Erro ao adicionar curso');
    }
  };

  const handleUpdateCourse = async () => {
    if (!editingCourse) return;

    try {
      if (!formData.title || !formData.description || formData.price <= 0) {
        toast.error('Preencha todos os campos obrigatórios');
        return;
      }

      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user?.app_metadata?.is_admin) {
        toast.error('Acesso não autorizado');
        return;
      }

      const { data, error } = await supabase
        .from('courses')
        .update({
          title: formData.title,
          description: formData.description,
          price: formData.price,
          image_url: formData.image_url || null,
          visible: formData.visible
        })
        .eq('id', editingCourse.id)
        .select()
        .single();

      if (error) throw error;

      setCourses(courses.map(course => 
        course.id === editingCourse.id ? data : course
      ));
      setEditingCourse(null);
      setFormData({ title: '', description: '', price: 0, image_url: '', visible: false });
      toast.success('Curso atualizado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error(error.message || 'Erro ao atualizar curso');
    }
  };

  const handleDeleteCourse = async (courseId: string) => {
    if (!confirm('Tem certeza que deseja excluir este curso?')) return;

    try {
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user?.app_metadata?.is_admin) {
        toast.error('Acesso não autorizado');
        return;
      }

      const { error } = await supabase
        .from('courses')
        .delete()
        .eq('id', courseId);

      if (error) throw error;

      setCourses(courses.filter(course => course.id !== courseId));
      toast.success('Curso excluído com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error(error.message || 'Erro ao excluir curso');
    }
  };

  const handleEnrollUser = async (userId: string, courseId: string) => {
    try {
      const { error } = await supabase.rpc('enroll_user_in_course', {
        p_user_id: userId,
        p_course_id: courseId
      });

      if (error) throw error;

      setUserCourses([...userCourses, { user_id: userId, course_id: courseId }]);
      toast.success('Usuário matriculado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error(error.message || 'Erro ao matricular usuário');
    }
  };

  const handleUnenrollUser = async (userId: string, courseId: string) => {
    if (!confirm('Tem certeza que deseja remover a matrícula deste aluno?')) {
      return;
    }

    try {
      await unenrollUserFromCourse(userId, courseId);
      
      // Update local state
      setUserCourses(userCourses.filter(uc => 
        !(uc.user_id === userId && uc.course_id === courseId)
      ));
      
      toast.success('Matrícula removida com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao remover matrícula');
    }
  };

  const handleUploadCertificate = async (requestId: string, file: File) => {
    try {
      setUploadingCertificate(requestId);

      // Upload certificate file
      const fileName = `${requestId}.pdf`;
      const { error: uploadError } = await supabase.storage
        .from('certificates')
        .upload(fileName, file, {
          contentType: 'application/pdf',
          upsert: true
        });

      if (uploadError) throw uploadError;

      // Get public URL
      const { data: { publicUrl } } = supabase.storage
        .from('certificates')
        .getPublicUrl(fileName);

      // Update certificate request
      const { error: updateError } = await supabase
        .from('certificate_requests')
        .update({ 
          status: 'approved',
          certificate_url: publicUrl,
          updated_at: new Date().toISOString()
        })
        .eq('id', requestId);

      if (updateError) throw updateError;

      // Update local state
      setCertificateRequests(prevRequests =>
        prevRequests.map(req =>
          req.id === requestId
            ? { ...req, status: 'approved', certificate_url: publicUrl }
            : req
        )
      );

      toast.success('Certificado aprovado com sucesso');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao aprovar certificado');
    } finally {
      setUploadingCertificate(null);
    }
  };

  const handleRejectCertificate = async (requestId: string) => {
    try {
      const { error } = await supabase
        .from('certificate_requests')
        .update({
          status: 'rejected',
          updated_at: new Date().toISOString()
        })
        .eq('id', requestId);

      if (error) throw error;

      // Update the list of requests
      setCertificateRequests(prevRequests =>
        prevRequests.map(req =>
          req.id === requestId
            ? { ...req, status: 'rejected' }
            : req
        )
      );

      toast.success('Certificado rejeitado');
    } catch (error: any) {
      console.error('Error:', error);
      toast.error('Erro ao rejeitar certificado');
    }
  };

  const startEditing = (course: Course) => {
    setEditingCourse(course);
    setFormData({
      title: course.title,
      description: course.description,
      price: course.price,
      image_url: course.image_url || '',
      visible: course.visible
    });
  };

  const cancelEditing = () => {
    setEditingCourse(null);
    setFormData({ title: '', description: '', price: 0, image_url: '', visible: false });
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
        <div className="sm:flex sm:items-center sm:justify-between">
          <div>
            <h2 className="text-2xl font-semibold text-gray-900">Painel Administrativo</h2>
            <p className="mt-2 text-sm text-gray-700">
              Gerencie cursos, matrículas e certificados
            </p>
          </div>
          <div className="mt-4 sm:mt-0 flex space-x-3">
            <button
              onClick={() => {
                setShowEnrollments(false);
                setShowCertificates(!showCertificates);
              }}
              className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
            >
              <Award className="h-4 w-4 mr-2" />
              {showCertificates ? 'Gerenciar Cursos' : 'Certificados'}
            </button>
            {!showCertificates && (
              <button
                onClick={() => setShowEnrollments(!showEnrollments)}
                className="inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
              >
                <Users className="h-4 w-4 mr-2" />
                {showEnrollments ? 'Gerenciar Cursos' : 'Gerenciar Matrículas'}
              </button>
            )}
            {!showEnrollments && !showCertificates && (
              <button
                onClick={() => setIsAddingCourse(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                <Plus className="h-4 w-4 mr-2" />
                Novo Curso
              </button>
            )}
          </div>
        </div>

        {showCertificates ? (
          <div className="mt-8 bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Solicitações de Certificados</h3>
              <div className="space-y-6">
                {certificateRequests.length === 0 ? (
                  <p className="text-gray-500 text-center py-4">
                    Nenhuma solicitação de certificado pendente
                  </p>
                ) : (
                  certificateRequests.map((cert) => (
                    <div
                      key={cert.id}
                      className="bg-white rounded-lg shadow-sm p-6"
                    >
                      <div className="flex items-start justify-between">
                        <div>
                          <h4 className="text-lg font-semibold text-gray-900">
                            {cert.full_name}
                          </h4>
                          <p className="mt-1 text-sm text-gray-500">
                            Curso: {cert.course?.title || 'Curso não encontrado'}
                          </p>
                          <p className="text-sm text-gray-600 mt-1">
                            {cert.course?.description}
                          </p>
                          <p className="text-sm text-gray-500 mt-1">
                            Solicitado em: {new Date(cert.created_at).toLocaleDateString('pt-BR')}
                          </p>
                        </div>
                        <div className="flex items-center space-x-4">
                          {cert.status === 'pending' && (
                            <>
                              <label className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 cursor-pointer">
                                <Upload className="h-4 w-4 mr-2" />
                                Enviar Certificado
                                <input
                                  type="file"
                                  accept=".pdf"
                                  className="hidden"
                                  onChange={(e) => {
                                    const file = e.target.files?.[0];
                                    if (file) {
                                      handleUploadCertificate(cert.id, file);
                                    }
                                  }}
                                />
                              </label>
                              <button
                                onClick={() => handleRejectCertificate(cert.id)}
                                className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-red-600 hover:bg-red-700"
                              >
                                <X className="h-4 w-4 mr-2" />
                                Rejeitar
                              </button>
                            </>
                          )}
                          {cert.status === 'approved' && cert.certificate_url && (
                            <>
                              <a
                                href={cert.certificate_url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                              >
                                <Download className="h-4 w-4 mr-2" />
                                Download
                              </a>
                              <label className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-green-600 hover:bg-green-700 cursor-pointer">
                                <RefreshCw className="h-4 w-4 mr-2" />
                                Reenviar
                                <input
                                  type="file"
                                  accept=".pdf"
                                  className="hidden"
                                  onChange={(e) => {
                                    const file = e.target.files?.[0];
                                    if (file) {
                                      handleUploadCertificate(cert.id, file);
                                    }
                                  }}
                                />
                              </label>
                            </>
                          )}
                          {cert.status === 'rejected' && (
                            <span className="inline-flex items-center text-red-600">
                              <XCircle className="h-5 w-5 mr-2" />
                              Rejeitado
                            </span>
                          )}
                          {uploadingCertificate === cert.id && (
                            <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-600" />
                          )}
                        </div>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        ) : showEnrollments ? (
          <div className="mt-8 bg-white shadow rounded-lg overflow-hidden">
            <div className="px-4 py-5 sm:p-6">
              <h3 className="text-lg font-medium text-gray-900 mb-4">Matrículas</h3>
              <div className="grid gap-6">
                {users.map((user) => (
                  <div key={user.id} className="bg-gray-50 p-4 rounded-lg">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="text-sm font-medium text-gray-900">{user.name || 'Usuário sem nome'}</h4>
                        <p className="text-sm text-gray-500">
                          Criado em: {new Date(user.created_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <select
                          className="block w-64 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                          onChange={(e) => {
                            if (e.target.value) {
                              handleEnrollUser(user.id, e.target.value);
                              e.target.value = '';
                            }
                          }}
                          value=""
                        >
                          <option value="">Selecione um curso...</option>
                          {courses
                            .filter(course => !userCourses.some(uc => 
                              uc.user_id === user.id && uc.course_id === course.id
                            ))
                            .map(course => (
                              <option key={course.id} value={course.id}>
                                {course.title}
                              </option>
                            ))
                          }
                        </select>
                        <button
                          onClick={() => {}}
                          className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                        >
                          <UserPlus className="h-4 w-4" />
                        </button>
                      </div>
                    </div>
                    <div className="mt-4">
                      <h5 className="text-sm font-medium text-gray-700 mb-2">Cursos Matriculados:</h5>
                      <div className="space-y-2">
                        {courses
                          .filter(course => 
                            userCourses.some(uc => 
                              uc.user_id === user.id && uc.course_id === course.id
                            )
                          )
                          .map(course => (
                            <div key={course.id} className="flex items-center justify-between text-sm text-gray-600 bg-white p-2 rounded-md">
                              <span>{course.title}</span>
                              <button
                                onClick={() => handleUnenrollUser(user.id, course.id)}
                                className="text-red-600 hover:text-red-800 p-1"
                                title="Remover matrícula"
                              >
                                <UserMinus className="h-4 w-4" />
                              </button>
                            </div>
                          ))
                        }
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        ) : (
          <div className="mt-8 grid grid-cols-1 gap-6">
            {courses.map((course) => (
              <div 
                key={course.id} 
                className="bg-white shadow rounded-lg overflow-hidden"
              >
                <div className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-xl font-semibold text-gray-900">
                        {course.title}
                      </h3>
                      <p className="mt-2 text-gray-600">{course.description}</p>
                      <p className="mt-2 text-lg font-semibold text-gray-900">
                        R$ {course.price.toFixed(2)}
                      </p>
                      <div className="mt-2 flex items-center space-x-4">
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          course.status === 'published' ? 'bg-green-100 text-green-800' :
                          course.status === 'draft' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {course.status === 'published' ? 'Publicado' :
                           course.status === 'draft' ? 'Rascunho' :
                           'Arquivado'}
                        </span>
                        <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                          course.visible ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800'
                        }`}>
                          {course.visible ? 'Visível' : 'Oculto'}
                        </span>
                      </div>
                    </div>
                    <div className="ml-4 flex items-center space-x-2">
                      <button
                        onClick={() => navigate(`/admin/curso/${course.id}`)}
                        className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                      >
                        Editar Conteúdo
                        <ChevronRight className="ml-2 h-4 w-4" />
                      </button>
                      <button
                        onClick={() => startEditing(course)}
                        className="p-2 text-indigo-600 hover:text-indigo-900"
                      >
                        <Edit className="h-5 w-5" />
                      </button>
                      <button
                        onClick={() => handleDeleteCourse(course.id)}
                        className="p-2 text-red-600 hover:text-red-900"
                      >
                        <Trash2 className="h-5 w-5" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Modal de Adicionar/Editar Curso */}
        {(isAddingCourse || editingCourse) && (
          <div className="fixed inset-0 bg-gray-500 bg-opacity-75 flex items-center justify-center">
            <div className="bg-white rounded-lg p-6 max-w-2xl w-full">
              <div className="flex justify-between items-center mb-6">
                <h3 className="text-lg font-medium text-gray-900">
                  {editingCourse ? 'Editar Curso' : 'Novo Curso'}
                </h3>
                <button
                  onClick={() => {
                    setIsAddingCourse(false);
                    cancelEditing();
                  }}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <X className="h-6 w-6" />
                </button>
              </div>

              <div className="space-y-6">
                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Título
                  </label>
                  <input
                    type="text"
                    value={formData.title}
                    onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Descrição
                  </label>
                  <textarea
                    rows={4}
                    value={formData.description}
                    onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                    className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    Preço (R$)
                  </label>
                  <div className="mt-1 relative rounded-md shadow-sm">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <DollarSign className="h-5 w-5 text-gray-400" />
                    </div>
                    <input
                      type="number"
                      min="0"
                      step="0.01"
                      value={formData.price}
                      onChange={(e) => setFormData({ ...formData, price: parseFloat(e.target.value) })}
                      className="block w-full pl-10 rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700">
                    URL da Imagem
                  </label>
                  <div className="mt-1 flex rounded-md shadow-sm">
                    <span className="inline-flex items-center px-3 rounded-l-md border border-r-0 border-gray-300 bg-gray-50 text-gray-500">
                      <Image className="h-5 w-5" />
                    </span>
                    <input
                      type="text"
                      value={formData.image_url}
                      onChange={(e) => setFormData({ ...formData, image_url: e.target.value })}
                      className="flex-1 block w-full rounded-none rounded-r-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500"
                    />
                   </div>
                </div>

                <div className="flex items-center">
                  <input
                    type="checkbox"
                    checked={formData.visible}
                    onChange={(e) => setFormData({ ...formData, visible: e.target.checked })}
                    className="h-4 w-4 text-indigo-600 focus:ring-indigo-500 border-gray-300 rounded"
                  />
                  <label className="ml-2 block text-sm text-gray-900">
                    Curso visível para alunos
                  </label>
                </div>

                <div className="flex justify-end space-x-3">
                  <button
                    onClick={() => {
                      setIsAddingCourse(false);
                      cancelEditing();
                    }}
                    className="px-4 py-2 border border-gray-300 rounded-md text-sm font-medium text-gray-700 hover:bg-gray-50"
                  >
                    Cancelar
                  </button>
                  <button
                    onClick={editingCourse ? handleUpdateCourse : handleAddCourse}
                    className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
                  >
                    {editingCourse ? (
                      <div className="flex items-center">
                        <Save className="h-4 w-4 mr-2" />
                        Salvar
                      </div>
                    ) : (
                      <div className="flex items-center">
                        <Plus className="h-4 w-4 mr-2" />
                        Adicionar
                      </div>
                    )}
                  </button>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}