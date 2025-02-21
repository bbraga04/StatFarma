-- Create lesson_progress table
CREATE TABLE IF NOT EXISTS lesson_progress (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  lesson_id uuid REFERENCES course_lessons(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  last_position interval DEFAULT '0 seconds',
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, lesson_id)
);

-- Enable RLS
ALTER TABLE lesson_progress ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS "Users can manage their own lesson progress" ON lesson_progress;

-- Create policy for lesson progress
CREATE POLICY "Users can manage their own lesson progress"
  ON lesson_progress
  FOR ALL
  TO authenticated
  USING (
    auth.is_admin() OR
    auth.uid() = user_id
  )
  WITH CHECK (
    auth.is_admin() OR
    auth.uid() = user_id
  );

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_lesson_progress_user ON lesson_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_lesson_progress_lesson ON lesson_progress(lesson_id);

-- Add helpful comment
COMMENT ON TABLE lesson_progress IS 'Tracks user progress through individual lessons';