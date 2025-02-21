/*
  # Storage Configuration for Course Images

  1. Setup
    - Creates bucket for course images
    - Configures public access
    - Sets up security policies

  2. Security
    - Only admins can upload images
    - Public read access for all images
    - File type restrictions (PNG, JPG, JPEG, GIF, WebP)
    - Size limit enforced client-side
*/

-- Create storage schema if it doesn't exist
CREATE SCHEMA IF NOT EXISTS storage;

-- Create storage extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create bucket for course images if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('course-images', 'course-images', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can upload course images" ON storage.objects;
DROP POLICY IF EXISTS "Anyone can view course images" ON storage.objects;
DROP POLICY IF EXISTS "Admins can delete course images" ON storage.objects;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy for admin uploads
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