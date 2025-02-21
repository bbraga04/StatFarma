import React from 'react';
import { Helmet } from 'react-helmet-async';

interface SEOProps {
  title?: string;
  description?: string;
  image?: string;
  url?: string;
  type?: 'website' | 'article';
  publishedTime?: string;
  modifiedTime?: string;
  author?: string;
  keywords?: string[];
}

const defaultTitle = 'StatFarma | Cursos de Estatística para Profissionais da Saúde e Indústria Farmacêutica';
const defaultDescription = 'Cursos especializados em estatística aplicada para profissionais da saúde, farmacêuticos e indústria farmacêutica. Aprenda análise de dados, bioestatística e controle de qualidade com especialistas do setor.';
const defaultImage = 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?ixlib=rb-1.2.1&auto=format&fit=crop&w=1200&q=80';
const defaultUrl = 'https://statfarma.com';

export default function SEO({
  title = defaultTitle,
  description = defaultDescription,
  image = defaultImage,
  url = defaultUrl,
  type = 'website',
  publishedTime,
  modifiedTime,
  author = 'StatFarma',
  keywords = [
    'estatística farmacêutica',
    'bioestatística',
    'análise de dados farmacêuticos',
    'controle de qualidade',
    'validação de processos',
    'estatística para farmacêuticos',
    'cursos para indústria farmacêutica',
    'estatística aplicada',
    'análise estatística',
    'curso online farmácia',
    'GMP estatística',
    'validação de métodos analíticos',
    'controle estatístico de processo',
    'amostragem farmacêutica',
    'estudos de estabilidade',
    'validação de limpeza',
    'validação de processo',
    'controle em processo',
    'análise de risco',
    'qualificação de equipamentos'
  ]
}: SEOProps) {
  const schemaOrgJSONLD = {
    '@context': 'https://schema.org',
    '@type': type === 'article' ? 'Article' : 'WebSite',
    url,
    name: title,
    alternateName: 'StatFarma',
    headline: title,
    image: {
      '@type': 'ImageObject',
      url: image
    },
    description,
    author: {
      '@type': 'Organization',
      name: author
    },
    publisher: {
      '@type': 'Organization',
      name: 'StatFarma',
      logo: {
        '@type': 'ImageObject',
        url: `${defaultUrl}/logo.svg`
      }
    },
    mainEntityOfPage: {
      '@type': 'WebPage',
      '@id': url
    },
    sameAs: [
      'https://www.brardes.com.br',
      'https://www.facebook.com/statfarma',
      'https://www.instagram.com/statfarma',
      'https://www.linkedin.com/company/statfarma'
    ],
    inLanguage: 'pt-BR',
    copyrightYear: new Date().getFullYear(),
    offers: {
      '@type': 'Offer',
      priceCurrency: 'BRL',
      availability: 'https://schema.org/InStock',
      seller: {
        '@type': 'Organization',
        name: 'StatFarma'
      }
    }
  };

  if (publishedTime) {
    schemaOrgJSONLD.datePublished = publishedTime;
  }

  if (modifiedTime) {
    schemaOrgJSONLD.dateModified = modifiedTime;
  }

  return (
    <Helmet>
      {/* Primary Meta Tags */}
      <title>{title}</title>
      <meta name="title" content={title} />
      <meta name="description" content={description} />
      <meta name="keywords" content={keywords.join(', ')} />
      <meta name="author" content={author} />
      <meta name="robots" content="index, follow, max-image-preview:large" />
      <meta name="googlebot" content="index, follow, max-image-preview:large" />
      <meta name="format-detection" content="telephone=no" />
      <meta name="referrer" content="no-referrer-when-downgrade" />

      {/* Open Graph / Facebook */}
      <meta property="og:type" content={type} />
      <meta property="og:url" content={url} />
      <meta property="og:title" content={title} />
      <meta property="og:description" content={description} />
      <meta property="og:image" content={image} />
      <meta property="og:image:alt" content={title} />
      <meta property="og:locale" content="pt_BR" />
      <meta property="og:site_name" content="StatFarma" />

      {/* Twitter */}
      <meta property="twitter:card" content="summary_large_image" />
      <meta property="twitter:url" content={url} />
      <meta property="twitter:title" content={title} />
      <meta property="twitter:description" content={description} />
      <meta property="twitter:image" content={image} />
      <meta property="twitter:image:alt" content={title} />

      {/* Article Specific Meta Tags */}
      {publishedTime && <meta property="article:published_time" content={publishedTime} />}
      {modifiedTime && <meta property="article:modified_time" content={modifiedTime} />}
      {author && <meta property="article:author" content={author} />}

      {/* Schema.org JSON-LD */}
      <script type="application/ld+json">
        {JSON.stringify(schemaOrgJSONLD)}
      </script>

      {/* Additional Meta Tags */}
      <meta name="theme-color" content="#4F46E5" />
      <meta name="mobile-web-app-capable" content="yes" />
      <meta name="apple-mobile-web-app-capable" content="yes" />
      <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent" />
      <meta name="application-name" content="StatFarma" />
      <meta name="apple-mobile-web-app-title" content="StatFarma" />
      <meta name="msapplication-TileColor" content="#4F46E5" />
      <meta name="msapplication-config" content="/browserconfig.xml" />

      {/* Canonical URL */}
      <link rel="canonical" href={url} />

      {/* Link to related site */}
      <link rel="alternate" href="https://www.brardes.com.br" hrefLang="pt-BR" />

      {/* Preconnect to important domains */}
      <link rel="preconnect" href="https://fonts.googleapis.com" />
      <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
      <link rel="preconnect" href="https://images.unsplash.com" />
      <link rel="dns-prefetch" href="https://vetowoidnfuiwjtyvqcv.supabase.co" />
    </Helmet>
  );
}