import React from 'react';
import { useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ShoppingCart, Trash2, X } from 'lucide-react';
import toast from 'react-hot-toast';

interface CartItem {
  id: string;
  title: string;
  description: string;
  price: number;
  image_url: string;
}

export default function Cart() {
  const navigate = useNavigate();
  const [cartItems, setCartItems] = React.useState<CartItem[]>([]);
  const [loading, setLoading] = React.useState(true);
  const [purchasing, setPurchasing] = React.useState(false);

  React.useEffect(() => {
    loadCartItems();
  }, []);

  const loadCartItems = async () => {
    try {
      const cartData = localStorage.getItem('cart');
      if (cartData) {
        const items = JSON.parse(cartData);
        setCartItems(items);
      }
    } catch (error) {
      console.error('Error loading cart:', error);
      toast.error('Erro ao carregar carrinho');
    } finally {
      setLoading(false);
    }
  };

  const removeFromCart = (courseId: string) => {
    try {
      const updatedCart = cartItems.filter(item => item.id !== courseId);
      setCartItems(updatedCart);
      localStorage.setItem('cart', JSON.stringify(updatedCart));
      
      // Dispatch storage event for cart count update
      window.dispatchEvent(new StorageEvent('storage', {
        key: 'cart',
        newValue: JSON.stringify(updatedCart)
      }));
      
      toast.success('Item removido do carrinho');
    } catch (error) {
      console.error('Error removing item:', error);
      toast.error('Erro ao remover item');
    }
  };

  const clearCart = () => {
    try {
      setCartItems([]);
      localStorage.removeItem('cart');
      
      // Dispatch storage event for cart count update
      window.dispatchEvent(new StorageEvent('storage', {
        key: 'cart',
        newValue: null
      }));
      
      toast.success('Carrinho limpo com sucesso');
    } catch (error) {
      console.error('Error clearing cart:', error);
      toast.error('Erro ao limpar carrinho');
    }
  };

  const handlePurchase = async () => {
    try {
      setPurchasing(true);
      const { data: { user } } = await supabase.auth.getUser();
      
      if (!user) {
        toast.error('Faça login para continuar');
        navigate('/login');
        return;
      }

      // Purchase all courses in cart
      for (const item of cartItems) {
        const { error } = await supabase
          .from('user_courses')
          .insert([
            { user_id: user.id, course_id: item.id }
          ]);

        if (error) {
          if (error.code === '23505') { // Unique violation
            toast.error(`Você já possui o curso: ${item.title}`);
            continue;
          }
          throw error;
        }
      }

      // Clear cart
      localStorage.removeItem('cart');
      setCartItems([]);
      
      // Dispatch storage event for cart count update
      window.dispatchEvent(new StorageEvent('storage', {
        key: 'cart',
        newValue: null
      }));
      
      toast.success('Compra realizada com sucesso!');
      navigate('/dashboard');
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao finalizar compra');
    } finally {
      setPurchasing(false);
    }
  };

  const total = cartItems.reduce((sum, item) => sum + item.price, 0);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando carrinho...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white rounded-lg shadow-lg overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center">
                <ShoppingCart className="h-6 w-6 text-indigo-600 mr-3" />
                <h2 className="text-2xl font-semibold text-gray-900">Carrinho</h2>
              </div>
              {cartItems.length > 0 && (
                <button
                  onClick={clearCart}
                  className="inline-flex items-center px-3 py-2 border border-transparent text-sm font-medium rounded-md text-red-700 bg-red-100 hover:bg-red-200"
                >
                  <X className="h-4 w-4 mr-2" />
                  Limpar Carrinho
                </button>
              )}
            </div>
          </div>

          {cartItems.length === 0 ? (
            <div className="p-6 text-center">
              <p className="text-gray-500">Seu carrinho está vazio</p>
              <button
                onClick={() => navigate('/')}
                className="mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Ver Cursos
              </button>
            </div>
          ) : (
            <>
              <div className="divide-y divide-gray-200">
                {cartItems.map((item) => (
                  <div key={item.id} className="p-6 flex items-center">
                    {item.image_url && (
                      <img
                        src={item.image_url}
                        alt={item.title}
                        className="w-24 h-24 object-cover rounded-lg"
                      />
                    )}
                    <div className="ml-6 flex-1">
                      <h3 className="text-lg font-medium text-gray-900">{item.title}</h3>
                      <p className="mt-1 text-sm text-gray-500">{item.description}</p>
                    </div>
                    <div className="ml-6">
                      <p className="text-lg font-medium text-gray-900">
                        R$ {item.price.toFixed(2)}
                      </p>
                      <button
                        onClick={() => removeFromCart(item.id)}
                        className="mt-2 flex items-center text-sm text-red-600 hover:text-red-800"
                      >
                        <Trash2 className="h-4 w-4 mr-1" />
                        Remover
                      </button>
                    </div>
                  </div>
                ))}
              </div>

              <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
                <div className="flex items-center justify-between">
                  <p className="text-lg font-medium text-gray-900">
                    Total: R$ {total.toFixed(2)}
                  </p>
                  <button
                    onClick={handlePurchase}
                    disabled={purchasing}
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50"
                  >
                    {purchasing ? 'Processando...' : 'Finalizar Compra'}
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}