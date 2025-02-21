import React from 'react';
import { Mail, Linkedin, GraduationCap } from 'lucide-react';

const teachers = [
  {
    id: 1,
    name: 'Dra. Ana Silva',
    role: 'Professora de Estatística Básica',
    image: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
    bio: 'Doutora em Estatística pela USP com mais de 10 anos de experiência em ensino.',
    specialties: ['Estatística Descritiva', 'Probabilidade', 'Análise Exploratória'],
    linkedin: 'https://linkedin.com',
    email: 'ana.silva@estatisticapro.com'
  },
  {
    id: 2,
    name: 'Dr. Carlos Santos',
    role: 'Professor de Análise de Regressão',
    image: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
    bio: 'Pesquisador e professor com foco em modelos estatísticos avançados.',
    specialties: ['Regressão Linear', 'Regressão Múltipla', 'Séries Temporais'],
    linkedin: 'https://linkedin.com',
    email: 'carlos.santos@estatisticapro.com'
  },
  {
    id: 3,
    name: 'Dra. Maria Oliveira',
    role: 'Professora de Estatística Bayesiana',
    image: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80',
    bio: 'Especialista em inferência bayesiana e modelagem probabilística.',
    specialties: ['Inferência Bayesiana', 'Modelagem Hierárquica', 'MCMC'],
    linkedin: 'https://linkedin.com',
    email: 'maria.oliveira@estatisticapro.com'
  }
];

function Teachers() {
  return (
    <div className="py-16 bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-gray-900 sm:text-4xl">
            Nossos Professores
          </h2>
          <p className="mt-4 max-w-2xl mx-auto text-xl text-gray-500">
            Conheça nossa equipe de especialistas dedicados ao seu aprendizado
          </p>
        </div>

        <div className="mt-16 grid gap-8 lg:grid-cols-3 lg:gap-x-8">
          {teachers.map((teacher) => (
            <div key={teacher.id} className="bg-white rounded-2xl shadow-lg overflow-hidden">
              <div className="p-6">
                <img
                  className="h-40 w-40 rounded-full mx-auto object-cover"
                  src={teacher.image}
                  alt={teacher.name}
                />
                <div className="mt-6 text-center">
                  <h3 className="text-2xl font-bold text-gray-900">{teacher.name}</h3>
                  <p className="mt-1 text-lg font-medium text-indigo-600">{teacher.role}</p>
                </div>
                <p className="mt-4 text-gray-600">{teacher.bio}</p>
                <div className="mt-6">
                  <h4 className="font-semibold text-gray-900 flex items-center gap-2">
                    <GraduationCap className="w-5 h-5" />
                    Especialidades
                  </h4>
                  <ul className="mt-2 space-y-1">
                    {teacher.specialties.map((specialty, index) => (
                      <li key={index} className="text-gray-600">
                        • {specialty}
                      </li>
                    ))}
                  </ul>
                </div>
                <div className="mt-6 flex justify-center space-x-4">
                  <a
                    href={teacher.linkedin}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-gray-600 hover:text-indigo-600"
                  >
                    <Linkedin className="w-6 h-6" />
                  </a>
                  <a
                    href={`mailto:${teacher.email}`}
                    className="text-gray-600 hover:text-indigo-600"
                  >
                    <Mail className="w-6 h-6" />
                  </a>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default Teachers;