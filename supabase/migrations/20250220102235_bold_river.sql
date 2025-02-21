-- Create function to approve certificates
CREATE OR REPLACE FUNCTION approve_certificate_request(p_request_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Update certificate request status
  UPDATE certificate_requests
  SET 
    status = 'approved',
    updated_at = now()
  WHERE id = p_request_id;
END;
$$;

-- Grant execute permission
REVOKE ALL ON FUNCTION approve_certificate_request(uuid) FROM public;
GRANT EXECUTE ON FUNCTION approve_certificate_request(uuid) TO authenticated;

-- Add helpful comment
COMMENT ON FUNCTION approve_certificate_request IS 'Approves a pending certificate request';