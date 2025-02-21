import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { User, Mail, Save } from 'lucide-react';
import toast from 'react-hot-toast';

interface UserProfile {
  id: string;
  name: string;
  email?: string;
  created_at: string;
}

export default function Profile() {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState('');

  useEffect(() => {
    fetchProfile();
  }, []);

  const fetchProfile = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Usuário não encontrado');

      const { data: profileData, error: profileError } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

      if (profileError) throw profileError;

      setProfile({
        ...profileData,
        email: user.email
      });
      setName(profileData.name);
    } catch (error: any) {
      toast.error('Erro ao carregar perfil');
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleUpdateProfile = async () => {
    if (!profile) return;

    try {
      const { error } = await supabase
        .from('profiles')
        .update({ name })
        .eq('id', profile.id);

      if (error) throw error;

      setProfile(prev => prev ? { ...prev, name } : null);
      setEditing(false);
      toast.success('Perfil atualizado com sucesso');
    } catch (error: any) {
      toast.error('Erro ao atualizar perfil');
      console.error('Error:', error);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando perfil...</p>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-xl text-gray-600">Perfil não encontrado</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white shadow rounded-lg">
          {/* Header */}
          <div className="px-6 py-4 border-b border-gray-200">
            <h2 className="text-2xl font-semibold text-gray-900">Meu Perfil</h2>
          </div>

          {/* Profile Content */}
          <div className="px-6 py-6">
            {/* Avatar and Basic Info */}
            <div className="flex items-center mb-8">
              <div className="h-20 w-20 rounded-full bg-indigo-100 flex items-center justify-center">
                <User className="h-10 w-10 text-indigo-600" />
              </div>
              <div className="ml-6">
                <h3 className="text-xl font-semibold text-gray-900">{profile.name}</h3>
                <div className="flex items-center mt-1 text-gray-500">
                  <Mail className="h-4 w-4 mr-2" />
                  <span>{profile.email}</span>
                </div>
              </div>
            </div>

            {/* Profile Form */}
            <div className="space-y-6">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                  Nome
                </label>
                {editing ? (
                  <div className="mt-1 flex rounded-md shadow-sm">
                    <input
                      type="text"
                      id="name"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="flex-1 min-w-0 block w-full px-3 py-2 rounded-md border-gray-300 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                ) : (
                  <div className="mt-1 text-gray-900">{profile.name}</div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Email
                </label>
                <div className="mt-1 text-gray-900">{profile.email}</div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Membro desde
                </label>
                <div className="mt-1 text-gray-900">
                  {new Date(profile.created_at).toLocaleDateString('pt-BR')}
                </div>
              </div>

              <div className="flex justify-end">
                {editing ? (
                  <div className="space-x-3">
                    <button
                      onClick={() => {
                        setEditing(false);
                        setName(profile.name);
                      }}
                      className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50"
                    >
                      Cancelar
                    </button>
                    <button
                      onClick={handleUpdateProfile}
                      className="inline-flex items-center px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700"
                    >
                      <Save className="h-4 w-4 mr-2" />
                      Salvar Alterações
                    </button>
                  </div>
                ) : (
                  <button
                    onClick={() => setEditing(true)}
                    className="px-4 py-2 text-sm font-medium text-white bg-indigo-600 border border-transparent rounded-md hover:bg-indigo-700"
                  >
                    Editar Perfil
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}