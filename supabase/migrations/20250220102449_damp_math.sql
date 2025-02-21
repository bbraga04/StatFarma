-- Add course_id to course_lessons for easier querying
ALTER TABLE course_lessons
ADD COLUMN IF NOT EXISTS course_id uuid REFERENCES courses(id);

-- Update existing lessons with course_id
UPDATE course_lessons cl
SET course_id = cm.course_id
FROM course_modules cm
WHERE cl.module_id = cm.id;

-- Create trigger to maintain course_id
CREATE OR REPLACE FUNCTION maintain_lesson_course_id()
RETURNS trigger AS $$
BEGIN
  SELECT course_id INTO NEW.course_id
  FROM course_modules
  WHERE id = NEW.module_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER maintain_lesson_course_id_trigger
  BEFORE INSERT OR UPDATE ON course_lessons
  FOR EACH ROW
  EXECUTE FUNCTION maintain_lesson_course_id();

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_course_lessons_course_id ON course_lessons(course_id);

-- Add helpful comment
COMMENT ON COLUMN course_lessons.course_id IS 'Reference to parent course for easier querying';