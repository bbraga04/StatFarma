-- Update URL validation function
CREATE OR REPLACE FUNCTION is_valid_url(url text)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
  -- Handle null or empty URLs
  IF url IS NULL OR url = '' THEN
    RETURN false;
  END IF;

  -- Handle special cases
  IF url LIKE '/%' THEN -- Relative URLs
    RETURN true;
  END IF;

  IF url LIKE 'data:%' THEN -- Data URLs
    RETURN true;
  END IF;

  IF url LIKE 'blob:%' THEN -- Blob URLs
    RETURN true;
  END IF;

  -- Handle YouTube embeds
  IF url LIKE 'https://www.youtube.com/embed/%' THEN
    RETURN true;
  END IF;

  -- Handle Supabase storage URLs
  IF url LIKE current_setting('supabase_url') || '/storage/v1/object/public/%' THEN
    RETURN true;
  END IF;

  -- Basic URL validation
  RETURN url ~ '^https?://[^\s/$.?#].[^\s]*$';
END;
$$;

-- Add helpful comment
COMMENT ON FUNCTION is_valid_url IS 'Validates if a string is a valid URL';