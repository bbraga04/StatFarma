import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { ChevronLeft, AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import toast from 'react-hot-toast';

interface Quiz {
  id: string;
  title: string;
  description: string;
  passing_score: number;
}

interface Question {
  id: string;
  question: string;
  options: string[];
  correct_answer: string;
}

export default function Quiz() {
  const { moduleId } = useParams();
  const navigate = useNavigate();
  const [quiz, setQuiz] = useState<Quiz | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [submitted, setSubmitted] = useState(false);
  const [score, setScore] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (moduleId) {
      fetchQuiz();
    }
  }, [moduleId]);

  const fetchQuiz = async () => {
    try {
      // Fetch quiz
      const { data: quizData, error: quizError } = await supabase
        .from('course_quizzes')
        .select('*')
        .eq('module_id', moduleId)
        .single();

      if (quizError) throw quizError;
      setQuiz(quizData);

      // Fetch questions
      const { data: questionData, error: questionError } = await supabase
        .from('quiz_questions')
        .select('*')
        .eq('quiz_id', quizData.id);

      if (questionError) throw questionError;
      setQuestions(questionData || []);
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao carregar quiz');
    } finally {
      setLoading(false);
    }
  };

  const handleSubmit = async () => {
    if (!quiz) return;

    try {
      // Calculate score
      let correct = 0;
      questions.forEach(question => {
        if (answers[question.id] === question.correct_answer) {
          correct++;
        }
      });

      const scorePercentage = (correct / questions.length) * 100;
      const passed = scorePercentage >= quiz.passing_score;

      // Save attempt
      const { error } = await supabase
        .from('quiz_attempts')
        .upsert({
          quiz_id: quiz.id,
          user_id: (await supabase.auth.getUser()).data.user?.id,
          score: scorePercentage,
          passed,
          answers
        });

      if (error) throw error;

      setScore(scorePercentage);
      setSubmitted(true);

      if (passed) {
        toast.success('Parabéns! Você passou no quiz!');
      } else {
        toast.error('Você não atingiu a pontuação mínima. Tente novamente!');
      }
    } catch (error) {
      console.error('Error:', error);
      toast.error('Erro ao enviar respostas');
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Carregando quiz...</p>
        </div>
      </div>
    );
  }

  if (!quiz) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <p className="text-xl text-gray-600 mb-4">Quiz não encontrado</p>
          <button
            onClick={() => navigate(-1)}
            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
          >
            <ChevronLeft className="w-4 h-4 mr-2" />
            Voltar
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="mb-8">
          <button
            onClick={() => navigate(-1)}
            className="inline-flex items-center text-indigo-600 hover:text-indigo-700"
          >
            <ChevronLeft className="w-4 h-4 mr-1" />
            Voltar
          </button>
          <h1 className="text-3xl font-bold text-gray-900 mt-4">{quiz.title}</h1>
          {quiz.description && (
            <p className="mt-2 text-gray-600">{quiz.description}</p>
          )}
        </div>

        <div className="bg-white rounded-lg shadow-sm p-6">
          <div className="mb-6 flex items-center text-sm text-gray-500">
            <AlertCircle className="w-4 h-4 mr-2" />
            <span>Pontuação mínima para aprovação: {quiz.passing_score}%</span>
          </div>

          {questions.map((question, index) => (
            <div
              key={question.id}
              className={`mb-8 ${
                submitted ? 'pointer-events-none opacity-75' : ''
              }`}
            >
              <p className="text-lg font-medium text-gray-900 mb-4">
                {index + 1}. {question.question}
              </p>
              <div className="space-y-3">
                {question.options.map((option, optionIndex) => (
                  <label
                    key={optionIndex}
                    className={`flex items-center p-4 border rounded-lg cursor-pointer transition-colors ${
                      answers[question.id] === option
                        ? 'border-indigo-500 bg-indigo-50'
                        : 'border-gray-200 hover:bg-gray-50'
                    }`}
                  >
                    <input
                      type="radio"
                      name={question.id}
                      value={option}
                      checked={answers[question.id] === option}
                      onChange={(e) =>
                        setAnswers((prev) => ({
                          ...prev,
                          [question.id]: e.target.value,
                        }))
                      }
                      className="h-4 w-4 text-indigo-600 focus:ring-indigo-500"
                    />
                    <span className="ml-3">{option}</span>
                    {submitted && (
                      <>
                        {option === question.correct_answer && (
                          <CheckCircle className="ml-auto h-5 w-5 text-green-500" />
                        )}
                        {answers[question.id] === option &&
                          option !== question.correct_answer && (
                            <XCircle className="ml-auto h-5 w-5 text-red-500" />
                          )}
                      </>
                    )}
                  </label>
                ))}
              </div>
            </div>
          ))}

          {!submitted ? (
            <button
              onClick={handleSubmit}
              disabled={Object.keys(answers).length !== questions.length}
              className="w-full mt-6 px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Enviar Respostas
            </button>
          ) : (
            <div className="mt-6 text-center">
              <p className="text-xl font-semibold mb-2">
                Sua pontuação: {score.toFixed(1)}%
              </p>
              {score >= quiz.passing_score ? (
                <div className="text-green-600 flex items-center justify-center">
                  <CheckCircle className="w-5 h-5 mr-2" />
                  <span>Aprovado!</span>
                </div>
              ) : (
                <div className="text-red-600 flex items-center justify-center">
                  <XCircle className="w-5 h-5 mr-2" />
                  <span>Não atingiu a pontuação mínima</span>
                </div>
              )}
              <button
                onClick={() => {
                  setSubmitted(false);
                  setAnswers({});
                  setScore(0);
                }}
                className="mt-4 px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
              >
                Tentar Novamente
              </button>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}