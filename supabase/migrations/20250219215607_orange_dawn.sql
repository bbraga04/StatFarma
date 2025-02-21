-- Function to generate certificate URL
CREATE OR REPLACE FUNCTION generate_certificate_url(
  p_user_id uuid,
  p_course_id uuid,
  p_full_name text
)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_bucket_id text := 'certificates';
  v_file_name text;
  v_url text;
BEGIN
  -- Generate unique file name
  v_file_name := p_user_id || '-' || p_course_id || '.pdf';
  
  -- Generate signed URL for the certificate
  v_url := storage.fget_signed_url(
    v_bucket_id,
    v_file_name,
    3600 -- URL expires in 1 hour
  );

  RETURN v_url;
END;
$$;

-- Function to approve certificate and generate URL
CREATE OR REPLACE FUNCTION approve_certificate_request(
  p_request_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_request certificate_requests;
  v_url text;
BEGIN
  -- Get request details
  SELECT * INTO v_request
  FROM certificate_requests
  WHERE id = p_request_id
  AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Certificate request not found or not pending';
  END IF;

  -- Generate certificate URL
  v_url := generate_certificate_url(
    v_request.user_id,
    v_request.course_id,
    v_request.full_name
  );

  -- Update request status and URL
  UPDATE certificate_requests
  SET 
    status = 'approved',
    certificate_url = v_url,
    updated_at = now()
  WHERE id = p_request_id;
END;
$$;

-- Create certificates bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('certificates', 'certificates', true)
ON CONFLICT (id) DO NOTHING;

-- Policies for certificates bucket
CREATE POLICY "Anyone can read certificates"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'certificates');

CREATE POLICY "Only system can create certificates"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'certificates'
  AND auth.is_admin()
);

-- Add helpful comments
COMMENT ON FUNCTION generate_certificate_url IS 'Generates a signed URL for a certificate PDF';
COMMENT ON FUNCTION approve_certificate_request IS 'Approves a certificate request and generates the certificate URL';