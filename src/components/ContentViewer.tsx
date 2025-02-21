import React from 'react';
import { FileText, Play } from 'lucide-react';
import { isValidUrl } from '../lib/supabase';

interface ContentViewerProps {
  type: 'video' | 'pdf' | 'presentation';
  url: string;
  title: string;
}

export default function ContentViewer({ type, url, title }: ContentViewerProps) {
  // Validate URL first
  if (!url || !isValidUrl(url)) {
    return (
      <div className="w-full aspect-video bg-gray-100 rounded-lg flex items-center justify-center">
        <div className="text-center text-gray-500">
          <FileText className="w-12 h-12 mx-auto mb-2" />
          <p>URL inválida ou indisponível</p>
        </div>
      </div>
    );
  }

  if (type === 'video') {
    return (
      <div className="w-full aspect-video bg-black rounded-lg overflow-hidden">
        <video
          src={url}
          title={title}
          controls
          className="w-full h-full"
          controlsList="nodownload"
          onContextMenu={(e) => e.preventDefault()}
        >
          <source src={url} type="video/mp4" />
          <p>Seu navegador não suporta a reprodução de vídeos.</p>
        </video>
      </div>
    );
  }

  if (type === 'pdf' || type === 'presentation') {
    return (
      <div className="w-full aspect-video bg-white rounded-lg overflow-hidden">
        <embed
          src={url}
          type={type === 'pdf' ? 'application/pdf' : 'application/vnd.ms-powerpoint'}
          className="w-full h-full"
        />
      </div>
    );
  }

  return null;
}