import React from 'react';
import { Calendar, Clock, User } from 'lucide-react';

const posts = [
  {
    id: 1,
    title: 'Como a Estatística está Revolucionando a Ciência de Dados',
    excerpt: 'Descubra como os conceitos estatísticos fundamentais são essenciais para o desenvolvimento da ciência de dados moderna.',
    author: 'Ana Silva',
    date: '15 Mar 2024',
    readTime: '5 min',
    image: 'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    category: 'Ciência de Dados'
  },
  {
    id: 2,
    title: 'Guia Completo sobre Testes de Hipóteses',
    excerpt: 'Um guia prático sobre como realizar e interpretar testes de hipóteses estatísticas em diferentes contextos.',
    author: 'Carlos Santos',
    date: '12 Mar 2024',
    readTime: '8 min',
    image: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    category: 'Metodologia'
  },
  {
    id: 3,
    title: 'Estatística Bayesiana na Prática',
    excerpt: 'Aplicações práticas de estatística bayesiana em problemas do mundo real e como implementá-las.',
    author: 'Maria Oliveira',
    date: '10 Mar 2024',
    readTime: '6 min',
    image: 'https://images.unsplash.com/photo-1509228627152-72ae9ae6848d?ixlib=rb-1.2.1&auto=format&fit=crop&w=1000&q=80',
    category: 'Análise Bayesiana'
  }
];

function Blog() {
  return (
    <div className="py-16 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            Blog EstatísticaPro
          </h2>
          <p className="mt-4 max-w-2xl mx-auto text-xl text-gray-500">
            Artigos, tutoriais e novidades sobre estatística e análise de dados
          </p>
        </div>

        <div className="mt-12 grid gap-8 lg:grid-cols-3">
          {posts.map((post) => (
            <article key={post.id} className="bg-white rounded-lg shadow-lg overflow-hidden">
              <img
                className="h-48 w-full object-cover"
                src={post.image}
                alt={post.title}
              />
              <div className="p-6">
                <div className="flex items-center text-sm text-gray-500 mb-4">
                  <span className="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-indigo-100 text-indigo-800">
                    {post.category}
                  </span>
                </div>
                <h3 className="text-xl font-semibold text-gray-900 mb-2">
                  {post.title}
                </h3>
                <p className="text-gray-600 mb-4">
                  {post.excerpt}
                </p>
                <div className="flex items-center text-sm text-gray-500 mt-4">
                  <User className="w-4 h-4 mr-1" />
                  <span className="mr-4">{post.author}</span>
                  <Calendar className="w-4 h-4 mr-1" />
                  <span className="mr-4">{post.date}</span>
                  <Clock className="w-4 h-4 mr-1" />
                  <span>{post.readTime}</span>
                </div>
                <button className="mt-4 text-indigo-600 hover:text-indigo-800 font-medium">
                  Ler mais →
                </button>
              </div>
            </article>
          ))}
        </div>
      </div>
    </div>
  );
}

export default Blog;