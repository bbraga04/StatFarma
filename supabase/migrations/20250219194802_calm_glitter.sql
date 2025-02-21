-- Add full_name column to certificate_requests
ALTER TABLE certificate_requests
ADD COLUMN IF NOT EXISTS full_name text NOT NULL;

-- Add helpful comment
COMMENT ON COLUMN certificate_requests.full_name IS 'Full name to appear on the certificate';

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_certificate_requests_user 
ON certificate_requests(user_id, course_id);

-- Add validation constraint
ALTER TABLE certificate_requests
ADD CONSTRAINT certificate_requests_full_name_length 
CHECK (char_length(full_name) BETWEEN 3 AND 255);

-- Update RLS policies to be more specific
DROP POLICY IF EXISTS "Users can request their own certificates" ON certificate_requests;
DROP POLICY IF EXISTS "Users can view their own certificates" ON certificate_requests;
DROP POLICY IF EXISTS "Admins can manage all certificates" ON certificate_requests;

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

-- Add helpful comments
COMMENT ON TABLE certificate_requests IS 'Certificate requests for completed courses';
COMMENT ON COLUMN certificate_requests.status IS 'Status of the certificate request: pending, approved, or rejected';
COMMENT ON COLUMN certificate_requests.certificate_url IS 'URL to download the generated certificate (when approved)';