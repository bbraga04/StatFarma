/*
  # Storage Configuration Fix

  1. Changes
    - Reconfigure storage bucket with proper settings
    - Update storage policies with correct permissions
    - Fix metadata handling for uploads

  2. Security
    - Enable RLS on storage.objects
    - Add policies for admin uploads and public viewing
    - Add size and type restrictions
*/

-- Create storage schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS storage;

-- Create storage extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing bucket if it exists
DELETE FROM storage.buckets WHERE id = 'course-images';

-- Create bucket for course images with proper configuration
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types, owner)
VALUES (
  'course-images',
  'course-images',
  true,
  5242880, -- 5MB in bytes
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp']::text[],
  NULL
);

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can upload course images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view course images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete course images" ON storage.objects;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy for admin uploads with proper metadata handling
CREATE POLICY "Admins can upload course images"
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'course-images'
  AND auth.is_admin() = true
  AND (
    LOWER(RIGHT(name, 4)) IN ('.png', '.jpg', '.gif') OR
    LOWER(RIGHT(name, 5)) IN ('.jpeg', '.webp')
  )
);

-- Policy for public viewing
CREATE POLICY "Anyone can view course images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'course-images');

-- Policy for admin deletions
CREATE POLICY "Admins can delete course images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'course-images'
  AND auth.is_admin() = true
);

-- Grant necessary permissions
GRANT ALL ON SCHEMA storage TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA storage TO authenticated;