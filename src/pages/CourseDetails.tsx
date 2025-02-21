import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { Clock, Award, ShoppingCart, ArrowLeft } from 'lucide-react';
import toast from 'react-hot-toast';

interface Course {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url?: string;
}

interface CourseContent {
  id: string;
  title: string;
  type: string;
  url: string;
  order: number;
}

export default function CourseDetails() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [course, setCourse] = useState<Course | null>(null);
  const [contents, setContents] = useState<CourseContent[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasPurchased, setHasPurchased] = useState(false);
  const [isInCart, setIsInCart] = useState(false);
  const [user, setUser] = useState<any>(null);

  useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      setUser(user);
    };
    getUser();
  }, []);

  useEffect(() => {
    if (id) {
      fetchCourse();
      checkPurchaseStatus();
      checkCartStatus();
    }
  }, [id, user]);

  const fetchCourse = async () => {
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

      const { data: contentData, error: contentError } = await supabase
        .from('course_contents')
        .select('*')
        .eq('course_id', id)
        .order('order', { ascending: true });

      if (contentError) throw contentError;
      setContents(contentData || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar o curso');
      navigate('/');
    } finally {
      setLoading(false);
    }
  };

  const checkPurchaseStatus = async () => {
    if (!id || !user) {
      setHasPurchased(false);
      return;
    }

    try {
      const { data, error } = await supabase
        .from('user_courses')
        .select('*')
        .eq('user_id', user.id)
        .eq('course_id', id);

      if (error) {
        console.error('Error checking purchase status:', error);
        setHasPurchased(false);
        return;
      }

      setHasPurchased(data && data.length > 0);
    } catch (error) {
      console.error('Error:', error);
      setHasPurchased(false);
    }
  };

  const checkCartStatus = () => {
    try {
      const cartData = localStorage.getItem('cart');
      if (cartData) {
        const cart = JSON.parse(cartData);
        setIsInCart(cart.some((item: Course) => item.id === id));
      } else {
        setIsInCart(false);
      }
    } catch (error) {
      console.error('Error checking cart:', error);
      setIsInCart(false);
    }
  };

  const addToCart = () => {
    if (!user) {
      toast.error('Faça login para adicionar ao carrinho');
      navigate('/login', { state: { returnTo: `/curso/${id}` } });
      return;
    }

    try {
      const cartData = localStorage.getItem('cart');
      let cart = [];
      
      if (cartData) {
        cart = JSON.parse(cartData);
        if (cart.some((item: Course) => item.id === course?.id)) {
          toast.error('Curso já está no carrinho');
          return;
        }
      }
      
      if (course) {
        cart.push(course);
        localStorage.setItem('cart', JSON.stringify(cart));
        
        window.dispatchEvent(new StorageEvent('storage', {
          key: 'cart',
          newValue: JSON.stringify(cart)
        }));
        
        setIsInCart(true);
        toast.success('Curso adicionado ao carrinho');
        navigate('/carrinho');
      }
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao adicionar ao carrinho');
    }
  };

  const renderActionButton = () => {
    if (hasPurchased) {
      return (
        <button
          className="w-full bg-green-600 text-white py-3 px-4 rounded-md font-medium cursor-not-allowed"
          disabled
        >
          Curso Adquirido
        </button>
      );
    }

    if (isInCart) {
      return (
        <button
          onClick={() => navigate('/carrinho')}
          className="w-full bg-indigo-600 text-white py-3 px-4 rounded-md font-medium hover:bg-indigo-700 flex items-center justify-center transition-colors"
        >
          <ShoppingCart className="w-5 h-5 mr-2" />
          Ver no Carrinho
        </button>
      );
    }

    return (
      <button
        onClick={addToCart}
        className="w-full bg-indigo-600 text-white py-3 px-4 rounded-md font-medium hover:bg-indigo-700 flex items-center justify-center transition-colors"
      >
        <ShoppingCart className="w-5 h-5 mr-2" />
        Adicionar ao Carrinho
      </button>
    );
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
            onClick={() => navigate('/')}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 mr-2" />
            Voltar para a página inicial
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          {course.image_url && (
            <div className="relative h-96">
              <img
                src={course.image_url}
                alt={course.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-black bg-opacity-50 flex items-center justify-center">
                <div className="text-center text-white p-8">
                  <h1 className="text-4xl font-bold mb-4">{course.title}</h1>
                  <p className="text-xl">{course.description}</p>
                </div>
              </div>
            </div>
          )}

          <div className="p-8">
            <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between">
              <div className="lg:w-2/3 lg:pr-8">
                <h2 className="text-2xl font-bold text-gray-900 mb-4">
                  Sobre o Curso
                </h2>
                <p className="text-gray-600 mb-6">
                  {course.description}
                </p>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
                  <div className="flex items-center space-x-2 text-gray-600">
                    <Clock className="w-5 h-5" />
                    <span>40 horas de conteúdo</span>
                  </div>
                  <div className="flex items-center space-x-2 text-gray-600">
                    <Award className="w-5 h-5" />
                    <span>Certificado incluso</span>
                  </div>
                </div>

                <div>
                  <h3 className="text-xl font-semibold text-gray-900 mb-4">
                    Conteúdo do Curso
                  </h3>
                  <div className="space-y-4">
                    {contents.map((content, index) => (
                      <div
                        key={content.id}
                        className="bg-gray-50 p-4 rounded-lg hover:bg-gray-100 transition-colors"
                      >
                        <div className="flex items-center justify-between">
                          <div className="flex items-center space-x-3">
                            <span className="text-indigo-600 font-medium">
                              {index + 1}.
                            </span>
                            <h4 className="font-medium text-gray-900">
                              {content.title}
                            </h4>
                          </div>
                          {!hasPurchased && (
                            <span className="text-sm text-gray-500">
                              Bloqueado
                            </span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              <div className="lg:w-1/3 mt-8 lg:mt-0">
                <div className="bg-gray-50 rounded-lg p-6 sticky top-8">
                  <div className="text-center">
                    <p className="text-4xl font-bold text-gray-900 mb-4">
                      R$ {course.price.toFixed(2)}
                    </p>
                    {renderActionButton()}
                  </div>

                  <div className="mt-6 space-y-4">
                    <div className="flex items-center text-gray-600">
                      <Award className="w-5 h-5 mr-2" />
                      <span>Certificado de Conclusão</span>
                    </div>
                    <div className="flex items-center text-gray-600">
                      <Clock className="w-5 h-5 mr-2" />
                      <span>Acesso por 12 meses</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}