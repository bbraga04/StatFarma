-- Add last_accessed_at column to lesson_progress
ALTER TABLE lesson_progress
ADD COLUMN IF NOT EXISTS last_accessed_at timestamptz DEFAULT now();

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_lesson_progress_last_accessed 
ON lesson_progress(user_id, last_accessed_at DESC);

-- Update trigger to maintain last_accessed_at
CREATE OR REPLACE FUNCTION update_lesson_progress_timestamp()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  NEW.last_accessed_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'update_lesson_progress_timestamp_trigger'
  ) THEN
    CREATE TRIGGER update_lesson_progress_timestamp_trigger
      BEFORE UPDATE ON lesson_progress
      FOR EACH ROW
      EXECUTE FUNCTION update_lesson_progress_timestamp();
  END IF;
END $$;

-- Add helpful comment
COMMENT ON COLUMN lesson_progress.last_accessed_at IS 'When the user last accessed this lesson';