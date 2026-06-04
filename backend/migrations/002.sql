-- Add new columns to students table
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS semester SMALLINT,
  ADD COLUMN IF NOT EXISTS family_income DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS household_size SMALLINT,
  ADD COLUMN IF NOT EXISTS num_siblings_in_education SMALLINT,
  ADD COLUMN IF NOT EXISTS has_disability BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_orphan BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_refugee BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS academic_standing TEXT DEFAULT 'good',
  ADD COLUMN IF NOT EXISTS extracurricular_score SMALLINT DEFAULT 0;

-- Add new columns to scholarships table
ALTER TABLE public.scholarships
  ADD COLUMN IF NOT EXISTS amount_per_year DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS duration_months INTEGER DEFAULT 12,
  ADD COLUMN IF NOT EXISTS scholarship_type TEXT DEFAULT 'partial_tuition',
  ADD COLUMN IF NOT EXISTS preferred_gender TEXT,
  ADD COLUMN IF NOT EXISTS requires_essay BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS requires_interview BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS accepts_disability BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS accepts_orphan BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS accepts_refugee BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS max_semester SMALLINT,
  ADD COLUMN IF NOT EXISTS min_extracurricular_score SMALLINT DEFAULT 0,
  ADD COLUMN IF NOT EXISTS max_household_income DOUBLE PRECISION;

-- Create scholarship_applications table if not exists
CREATE TABLE IF NOT EXISTS public.scholarship_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    scholarship_id UUID NOT NULL REFERENCES public.scholarships(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES public.students(profile_id) ON DELETE CASCADE,
    essay_text TEXT,
    status TEXT DEFAULT 'pending',
    interview_score SMALLINT,
    essay_score SMALLINT,
    applied_at TIMESTAMPTZ DEFAULT NOW()
);
