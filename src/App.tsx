import React from 'react';
import { BrowserRouter as Router, Routes, Route, Link, Navigate } from 'react-router-dom';
import { Calculator, LogOut, ShoppingCart } from 'lucide-react';
import { Toaster } from 'react-hot-toast';
import { supabase } from './lib/supabase';
import Home from './pages/Home';
import CourseDetails from './pages/CourseDetails';
import CourseLessons from './pages/CourseLessons';
import Cart from './pages/Cart';
import Login from './pages/Login';
import Register from './pages/Register';
import Dashboard from './pages/Dashboard';
import Profile from './pages/Profile';
import Admin from './pages/Admin';
import CourseEditor from './pages/CourseEditor';

function App() {
  const [user, setUser] = React.useState<any>(null);
  const [loading, setLoading] = React.useState(true);
  const [isAdmin, setIsAdmin] = React.useState(false);
  const [cartCount, setCartCount] = React.useState(0);

  React.useEffect(() => {
    const getUser = async () => {
      const { data: { user } } = await supabase.auth.getUser();
      setUser(user);
      setIsAdmin(user?.app_metadata?.is_admin ?? false);
      setLoading(false);
    };
    getUser();

    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      setUser(session?.user ?? null);
      setIsAdmin(session?.user?.app_metadata?.is_admin ?? false);
    });

    // Initialize cart count
    const cartData = localStorage.getItem('cart');
    if (cartData) {
      const items = JSON.parse(cartData);
      setCartCount(items.length);
    }

    // Listen for cart changes
    window.addEventListener('storage', handleStorageChange);

    return () => {
      subscription.unsubscribe();
      window.removeEventListener('storage', handleStorageChange);
    };
  }, []);

  const handleStorageChange = (e: StorageEvent) => {
    if (e.key === 'cart') {
      const cartData = e.newValue;
      if (cartData) {
        const items = JSON.parse(cartData);
        setCartCount(items.length);
      } else {
        setCartCount(0);
      }
    }
  };

  const handleLogout = async () => {
    try {
      await supabase.auth.signOut();
      setUser(null);
      setIsAdmin(false);
      window.location.href = '/';
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
    <Router>
      <div className="min-h-screen bg-gray-50">
        <header className="bg-indigo-600 text-white">
          <div className="max-w-7xl mx-auto px-4 py-6 sm:px-6 lg:px-8">
            <div className="flex items-center justify-between">
              <Link to="/" className="flex items-center space-x-3">
                <Calculator className="w-8 h-8" />
                <h1 className="text-2xl font-bold">StatFarma</h1>
              </Link>
              <nav className="hidden md:flex items-center space-x-8">
                <Link to="/" className="hover:text-indigo-200">Cursos</Link>
                <Link to="/carrinho" className="relative hover:text-indigo-200">
                  <ShoppingCart className="w-6 h-6" />
                  {cartCount > 0 && (
                    <span className="absolute -top-2 -right-2 bg-red-500 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center">
                      {cartCount}
                    </span>
                  )}
                </Link>
                {user ? (
                  <>
                    <Link to="/dashboard" className="hover:text-indigo-200">Minha Área</Link>
                    <Link to="/perfil" className="hover:text-indigo-200">Meu Perfil</Link>
                    {isAdmin && (
                      <Link to="/admin" className="hover:text-indigo-200">Admin</Link>
                    )}
                    <button
                      onClick={handleLogout}
                      className="flex items-center space-x-2 text-white hover:text-indigo-200 transition-colors"
                    >
                      <LogOut className="w-5 h-5" />
                      <span>Sair</span>
                    </button>
                  </>
                ) : (
                  <Link to="/login" className="hover:text-indigo-200">Entrar</Link>
                )}
              </nav>
            </div>
          </div>
        </header>

        <Toaster position="top-right" />

        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/curso/:id" element={<CourseDetails />} />
          <Route path="/curso/:id/aulas" element={user ? <CourseLessons /> : <Navigate to="/login" />} />
          <Route path="/carrinho" element={<Cart />} />
          <Route path="/login" element={!user ? <Login /> : <Navigate to="/dashboard" />} />
          <Route path="/register" element={!user ? <Register /> : <Navigate to="/dashboard" />} />
          <Route path="/dashboard" element={user ? <Dashboard /> : <Navigate to="/login" />} />
          <Route path="/perfil" element={user ? <Profile /> : <Navigate to="/login" />} />
          <Route path="/admin" element={isAdmin ? <Admin /> : <Navigate to="/" />} />
          <Route path="/admin/curso/:id" element={isAdmin ? <CourseEditor /> : <Navigate to="/" />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;