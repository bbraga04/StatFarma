-- Add status and visibility columns to courses
ALTER TABLE courses
ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
ADD COLUMN IF NOT EXISTS visible boolean NOT NULL DEFAULT false;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_courses_status_visible ON courses(status, visible);

-- Update policies to respect visibility
DROP POLICY IF EXISTS "Anyone can view published and visible courses" ON courses;
DROP POLICY IF EXISTS "All users can view courses" ON courses;

CREATE POLICY "Anyone can view published and visible courses"
ON courses
FOR SELECT
USING (
  (status = 'published' AND visible = true) OR
  auth.is_admin()
);

-- Add helpful comments
COMMENT ON COLUMN courses.status IS 'Course status: draft (in development), published (ready), or archived (no longer available)';
COMMENT ON COLUMN courses.visible IS 'Whether the course is visible in the store';