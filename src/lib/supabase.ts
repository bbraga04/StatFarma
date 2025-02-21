import { createClient } from '@supabase/supabase-js';

// Get environment variables
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

// Validate configuration
if (!supabaseUrl) {
  throw new Error('VITE_SUPABASE_URL is required');
}

if (!supabaseAnonKey) {
  throw new Error('VITE_SUPABASE_ANON_KEY is required');
}

// URL validation helper with improved error handling
export const isValidUrl = (urlString: string | null | undefined): boolean => {
  if (!urlString) return false;
  
  // Handle special cases first
  if (urlString.startsWith('/')) return true; // Relative URLs
  if (urlString.startsWith('data:')) return true; // Data URLs
  if (urlString.startsWith('blob:')) return true; // Blob URLs
  if (urlString.startsWith(supabaseUrl)) return true; // Supabase storage URLs
  if (urlString.startsWith('https://www.youtube.com/embed/')) return true; // YouTube embeds
  if (urlString.startsWith('https://images.unsplash.com/')) return true; // Unsplash images
  
  try {
    // For regular URLs, try to construct a URL object
    new URL(urlString);
    return true;
  } catch {
    return false;
  }
};

// Helper function to format URLs with improved error handling
export const formatUrl = (url: string | null | undefined): string => {
  if (!url) return '';
  
  // Handle special cases first
  if (url.startsWith('/')) return url; // Relative URLs
  if (url.startsWith('data:')) return url; // Data URLs
  if (url.startsWith('blob:')) return url; // Blob URLs
  if (url.startsWith(supabaseUrl)) return url; // Supabase storage URLs
  if (url.startsWith('https://www.youtube.com/embed/')) return url; // YouTube embeds
  if (url.startsWith('https://images.unsplash.com/')) return url; // Unsplash images
  
  try {
    return new URL(url).toString();
  } catch {
    return '';
  }
};

// Create Supabase client with proper configuration
export const supabase = createClient(
  supabaseUrl.trim(),
  supabaseAnonKey.trim(),
  {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
      storage: localStorage,
      storageKey: 'supabase.auth.token',
      flowType: 'pkce'
    }
  }
);

// Function to get current user
export const getCurrentUser = async () => {
  try {
    const { data: { session }, error: sessionError } = await supabase.auth.getSession();
    
    if (sessionError) {
      console.error('Session error:', sessionError);
      return null;
    }

    if (!session) {
      return null;
    }

    return session.user;
  } catch (error) {
    console.error('Error getting user:', error);
    return null;
  }
};

// Function to check if user is admin
export const isUserAdmin = async () => {
  const user = await getCurrentUser();
  return user?.app_metadata?.is_admin ?? false;
};

// Function to get storage URL
export const getStorageUrl = (bucket: string, path: string): string => {
  return `${supabaseUrl}/storage/v1/object/public/${bucket}/${path}`;
};

// Function to upload course content
export const uploadCourseContent = async (
  file: File,
  courseId: string,
  moduleId: string,
  lessonId: string,
  contentType: 'video' | 'pdf' | 'presentation'
): Promise<string> => {
  let bucket = 'course-videos';
  if (contentType === 'pdf') {
    bucket = 'course-documents';
  } else if (contentType === 'presentation') {
    bucket = 'course-presentations';
  }

  const filePath = `${courseId}/${moduleId}/${lessonId}/${file.name}`;

  const { error: uploadError } = await supabase.storage
    .from(bucket)
    .upload(filePath, file, {
      cacheControl: '3600',
      upsert: true
    });

  if (uploadError) {
    throw uploadError;
  }

  const { data: { publicUrl } } = supabase.storage
    .from(bucket)
    .getPublicUrl(filePath);

  return publicUrl;
};

// Function to unenroll user from course
export const unenrollUserFromCourse = async (userId: string, courseId: string): Promise<void> => {
  try {
    // Check if course is completed
    const { data: progress } = await supabase
      .from('course_progress')
      .select('completed')
      .eq('user_id', userId)
      .eq('course_id', courseId)
      .single();

    // If course is completed, only remove enrollment but keep progress
    if (progress?.completed) {
      const { error: enrollmentError } = await supabase
        .from('user_courses')
        .delete()
        .eq('user_id', userId)
        .eq('course_id', courseId);

      if (enrollmentError) throw enrollmentError;
    } else {
      // If course is not completed, remove everything
      const { error: enrollmentError } = await supabase
        .from('user_courses')
        .delete()
        .eq('user_id', userId)
        .eq('course_id', courseId);

      if (enrollmentError) throw enrollmentError;

      // Delete course progress
      const { error: progressError } = await supabase
        .from('course_progress')
        .delete()
        .eq('user_id', userId)
        .eq('course_id', courseId);

      if (progressError) throw progressError;

      // Delete lesson progress
      const { error: lessonProgressError } = await supabase
        .from('lesson_progress')
        .delete()
        .eq('user_id', userId)
        .in('lesson_id', (
          await supabase
            .from('course_lessons')
            .select('id')
            .eq('course_id', courseId)
        ).data?.map(l => l.id) || []);

      if (lessonProgressError) throw lessonProgressError;
    }
  } catch (error: any) {
    console.error('Error:', error);
    throw new Error(error.message || 'Erro ao remover matrícula do curso');
  }
};