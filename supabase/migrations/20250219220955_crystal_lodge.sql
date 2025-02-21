-- Drop existing policies
DROP POLICY IF EXISTS "Users can request certificates for completed courses" ON certificate_requests;
DROP POLICY IF EXISTS "Users can view their own certificates" ON certificate_requests;
DROP POLICY IF EXISTS "Admins can update certificates" ON certificate_requests;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT ALL ON certificate_requests TO authenticated;

-- Create more permissive policies
CREATE POLICY "Anyone can view certificates"
ON certificate_requests
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Users can request certificates"
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

CREATE POLICY "Admins can manage certificates"
ON certificate_requests
FOR ALL
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

-- Grant execute on function
REVOKE ALL ON FUNCTION request_certificate FROM public;
GRANT EXECUTE ON FUNCTION request_certificate TO authenticated;

-- Add helpful comments
COMMENT ON FUNCTION request_certificate IS 'Safely creates a certificate request for a completed course';