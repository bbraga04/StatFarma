-- Create quiz tables
CREATE TABLE course_quizzes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id uuid REFERENCES course_modules(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  passing_score integer NOT NULL DEFAULT 70,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE quiz_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_id uuid REFERENCES course_quizzes(id) ON DELETE CASCADE,
  question text NOT NULL,
  options jsonb NOT NULL,
  correct_answer text NOT NULL,
  created_at timestamptz DEFAULT now()
);

CREATE TABLE quiz_attempts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  quiz_id uuid REFERENCES course_quizzes(id) ON DELETE CASCADE,
  score integer NOT NULL,
  passed boolean NOT NULL,
  answers jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, quiz_id)
);

-- Enable RLS
ALTER TABLE course_quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Admins can manage quizzes"
  ON course_quizzes
  FOR ALL
  TO authenticated
  USING (auth.is_admin())
  WITH CHECK (auth.is_admin());

CREATE POLICY "Users can view quizzes of purchased courses"
  ON course_quizzes
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM course_modules cm
      JOIN user_courses uc ON uc.course_id = cm.course_id
      WHERE cm.id = course_quizzes.module_id
      AND uc.user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can manage quiz questions"
  ON quiz_questions
  FOR ALL
  TO authenticated
  USING (auth.is_admin())
  WITH CHECK (auth.is_admin());

CREATE POLICY "Users can view quiz questions of purchased courses"
  ON quiz_questions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM course_quizzes cq
      JOIN course_modules cm ON cm.id = cq.module_id
      JOIN user_courses uc ON uc.course_id = cm.course_id
      WHERE cq.id = quiz_questions.quiz_id
      AND uc.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can manage their own quiz attempts"
  ON quiz_attempts
  FOR ALL
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Add certificate request table
CREATE TABLE certificate_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  course_id uuid REFERENCES courses(id) ON DELETE CASCADE,
  status text NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')),
  certificate_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE certificate_requests ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can request their own certificates"
  ON certificate_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

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

-- Function to check course completion
CREATE OR REPLACE FUNCTION check_course_completion(p_user_id uuid, p_course_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_total_modules integer;
  v_completed_modules integer;
  v_completion_rate numeric;
BEGIN
  -- Count total modules
  SELECT COUNT(DISTINCT cm.id)
  INTO v_total_modules
  FROM course_modules cm
  WHERE cm.course_id = p_course_id;

  -- Count completed modules (all lessons completed and quiz passed)
  SELECT COUNT(DISTINCT cm.id)
  INTO v_completed_modules
  FROM course_modules cm
  WHERE cm.course_id = p_course_id
  AND NOT EXISTS (
    -- Check for incomplete lessons
    SELECT 1 FROM course_lessons cl
    LEFT JOIN lesson_progress lp ON lp.lesson_id = cl.id AND lp.user_id = p_user_id
    WHERE cl.module_id = cm.id
    AND (lp.id IS NULL OR NOT lp.completed)
  )
  AND NOT EXISTS (
    -- Check for failed or missing quizzes
    SELECT 1 FROM course_quizzes cq
    LEFT JOIN quiz_attempts qa ON qa.quiz_id = cq.id AND qa.user_id = p_user_id
    WHERE cq.module_id = cm.id
    AND (qa.id IS NULL OR NOT qa.passed)
  );

  -- Calculate completion rate
  v_completion_rate := CASE 
    WHEN v_total_modules = 0 THEN 0
    ELSE (v_completed_modules::numeric / v_total_modules) * 100
  END;

  RETURN v_completion_rate >= 100;
END;
$$;

-- Function to get course completion rate
CREATE OR REPLACE FUNCTION get_course_completion_rate(p_user_id uuid, p_course_id uuid)
RETURNS numeric
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_total_modules integer;
  v_completed_modules integer;
BEGIN
  -- Count total modules
  SELECT COUNT(DISTINCT cm.id)
  INTO v_total_modules
  FROM course_modules cm
  WHERE cm.course_id = p_course_id;

  -- Count completed modules
  SELECT COUNT(DISTINCT cm.id)
  INTO v_completed_modules
  FROM course_modules cm
  WHERE cm.course_id = p_course_id
  AND NOT EXISTS (
    SELECT 1 FROM course_lessons cl
    LEFT JOIN lesson_progress lp ON lp.lesson_id = cl.id AND lp.user_id = p_user_id
    WHERE cl.module_id = cm.id
    AND (lp.id IS NULL OR NOT lp.completed)
  )
  AND NOT EXISTS (
    SELECT 1 FROM course_quizzes cq
    LEFT JOIN quiz_attempts qa ON qa.quiz_id = cq.id AND qa.user_id = p_user_id
    WHERE cq.module_id = cm.id
    AND (qa.id IS NULL OR NOT qa.passed)
  );

  RETURN CASE 
    WHEN v_total_modules = 0 THEN 0
    ELSE (v_completed_modules::numeric / v_total_modules) * 100
  END;
END;
$$;

-- Add helpful comments
COMMENT ON TABLE course_quizzes IS 'Quizzes for course modules';
COMMENT ON TABLE quiz_questions IS 'Questions for each quiz';
COMMENT ON TABLE quiz_attempts IS 'User attempts at quizzes';
COMMENT ON TABLE certificate_requests IS 'Certificate requests for completed courses';
COMMENT ON FUNCTION check_course_completion IS 'Checks if a user has completed all modules and passed all quizzes';
COMMENT ON FUNCTION get_course_completion_rate IS 'Calculates the course completion rate for a user';