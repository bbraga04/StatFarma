-- Drop existing certificate_requests table
DROP TABLE IF EXISTS certificate_requests CASCADE;

-- Recreate certificate_requests table with proper relationships
CREATE TABLE certificate_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
  certificate_url text,
  full_name text NOT NULL CHECK (char_length(full_name) BETWEEN 3 AND 255),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE certificate_requests ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can request their own certificates"
ON certificate_requests
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id AND
  EXISTS (
    SELECT 1 FROM course_progress cp
    WHERE cp.user_id = user_id
    AND cp.course_id = certificate_requests.course_id
    AND cp.completed = true
  )
);

CREATE POLICY "Users can view their own certificates"
ON certificate_requests
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all certificates"
ON certificate_requests
FOR ALL
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

-- Create indexes
CREATE INDEX idx_certificate_requests_user ON certificate_requests(user_id);
CREATE INDEX idx_certificate_requests_course ON certificate_requests(course_id);
CREATE INDEX idx_certificate_requests_status ON certificate_requests(status);

-- Add helpful comments
COMMENT ON TABLE certificate_requests IS 'Certificate requests for completed courses';
COMMENT ON COLUMN certificate_requests.status IS 'Status of the certificate request: pending, approved, or rejected';
COMMENT ON COLUMN certificate_requests.certificate_url IS 'URL to download the generated certificate (when approved)';
COMMENT ON COLUMN certificate_requests.full_name IS 'Full name to appear on the certificate';