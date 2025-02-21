-- Drop existing policies
DROP POLICY IF EXISTS "Users can request their own certificates" ON certificate_requests;
DROP POLICY IF EXISTS "Users can view their own certificates" ON certificate_requests;
DROP POLICY IF EXISTS "Admins can manage all certificates" ON certificate_requests;

-- Create more specific policies
CREATE POLICY "Users can request certificates for completed courses"
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
  ) AND
  NOT EXISTS (
    SELECT 1 FROM certificate_requests cr
    WHERE cr.user_id = user_id
    AND cr.course_id = certificate_requests.course_id
    AND cr.status != 'rejected'
  )
);

CREATE POLICY "Users can view their own certificates"
ON certificate_requests
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.is_admin()
);

CREATE POLICY "Admins can update certificates"
ON certificate_requests
FOR UPDATE
TO authenticated
USING (auth.is_admin())
WITH CHECK (auth.is_admin());

-- Function to safely handle certificate requests
CREATE OR REPLACE FUNCTION request_certificate(
  p_course_id uuid,
  p_full_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id uuid;
  v_request_id uuid;
BEGIN
  -- Get current user
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- Verify course completion
  IF NOT EXISTS (
    SELECT 1 FROM course_progress
    WHERE user_id = v_user_id
    AND course_id = p_course_id
    AND completed = true
  ) THEN
    RAISE EXCEPTION 'Course not completed';
  END IF;

  -- Check for existing non-rejected request
  IF EXISTS (
    SELECT 1 FROM certificate_requests
    WHERE user_id = v_user_id
    AND course_id = p_course_id
    AND status != 'rejected'
  ) THEN
    RAISE EXCEPTION 'Certificate already requested';
  END IF;

  -- Create request
  INSERT INTO certificate_requests (
    id,
    user_id,
    course_id,
    status,
    full_name
  )
  VALUES (
    gen_random_uuid(),
    v_user_id,
    p_course_id,
    'pending',
    p_full_name
  )
  RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;

-- Revoke direct table access
REVOKE ALL ON certificate_requests FROM public, authenticated;

-- Grant execute on function
GRANT EXECUTE ON FUNCTION request_certificate TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION request_certificate IS 'Safely creates a certificate request for a completed course';