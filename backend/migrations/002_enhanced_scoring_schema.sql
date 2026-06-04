-- ============================================================
-- Migration 002: Enhanced Scoring System
-- Adds new columns for advanced scholarship matching scoring
-- ============================================================

-- 1. STUDENTS — yeni alanlar
ALTER TABLE public.students
  ADD COLUMN IF NOT EXISTS semester SMALLINT CHECK (semester >= 1 AND semester <= 12),
  ADD COLUMN IF NOT EXISTS family_income NUMERIC(10,2) CHECK (family_income >= 0),
  ADD COLUMN IF NOT EXISTS household_size SMALLINT CHECK (household_size >= 1),
  ADD COLUMN IF NOT EXISTS num_siblings_in_education SMALLINT DEFAULT 0 CHECK (num_siblings_in_education >= 0),
  ADD COLUMN IF NOT EXISTS has_disability BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_orphan BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS is_refugee BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS academic_standing TEXT DEFAULT 'good' CHECK (academic_standing IN ('probation', 'good', 'honor', 'high_honor')),
  ADD COLUMN IF NOT EXISTS extracurricular_score SMALLINT DEFAULT 0 CHECK (extracurricular_score >= 0 AND extracurricular_score <= 10);

-- 2. SCHOLARSHIPS — yeni alanlar
ALTER TABLE public.scholarships
  ADD COLUMN IF NOT EXISTS amount_per_year NUMERIC(10,2) CHECK (amount_per_year >= 0),
  ADD COLUMN IF NOT EXISTS duration_months INTEGER DEFAULT 12 CHECK (duration_months >= 1),
  ADD COLUMN IF NOT EXISTS scholarship_type TEXT DEFAULT 'partial_tuition' CHECK (scholarship_type IN ('full_tuition', 'partial_tuition', 'living_stipend', 'one_time')),
  ADD COLUMN IF NOT EXISTS preferred_gender TEXT CHECK (preferred_gender IN ('male', 'female')),
  ADD COLUMN IF NOT EXISTS requires_essay BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS requires_interview BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS accepts_disability BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS accepts_orphan BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS accepts_refugee BOOLEAN DEFAULT TRUE,
  ADD COLUMN IF NOT EXISTS max_semester SMALLINT CHECK (max_semester >= 1 AND max_semester <= 12),
  ADD COLUMN IF NOT EXISTS min_extracurricular_score SMALLINT DEFAULT 0 CHECK (min_extracurricular_score >= 0 AND min_extracurricular_score <= 10),
  ADD COLUMN IF NOT EXISTS max_household_income NUMERIC(10,2) CHECK (max_household_income >= 0);

-- 3. SCHOLARSHIP APPLICATIONS (başvuru tablosu)
CREATE TABLE IF NOT EXISTS public.scholarship_applications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    scholarship_id UUID REFERENCES public.scholarships(id) ON DELETE CASCADE NOT NULL,
    student_id UUID REFERENCES public.students(profile_id) ON DELETE CASCADE NOT NULL,
    essay_text TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'shortlisted', 'accepted', 'rejected')),
    interview_score SMALLINT CHECK (interview_score >= 0 AND interview_score <= 100),
    essay_score SMALLINT CHECK (essay_score >= 0 AND essay_score <= 100),
    applied_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.scholarship_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students can view own applications" ON public.scholarship_applications
  FOR SELECT USING (auth.uid() = student_id);
CREATE POLICY "Admins can view all applications" ON public.scholarship_applications
  FOR SELECT USING (auth.uid() IN (SELECT id FROM public.profiles WHERE role = 'admin'));

-- 4. MATCHES — skor detayları
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS score_breakdown JSONB,
  ADD COLUMN IF NOT EXISTS score_components JSONB;

-- 5. INDEXES
CREATE INDEX IF NOT EXISTS idx_students_semester ON public.students(semester);
CREATE INDEX IF NOT EXISTS idx_students_academic_standing ON public.students(academic_standing);
CREATE INDEX IF NOT EXISTS idx_students_extracurricular ON public.students(extracurricular_score);
CREATE INDEX IF NOT EXISTS idx_scholarships_type ON public.scholarships(scholarship_type);
CREATE INDEX IF NOT EXISTS idx_scholarships_amount ON public.scholarships(amount_per_year);
CREATE INDEX IF NOT EXISTS idx_scholarship_applications_scholarship ON public.scholarship_applications(scholarship_id);
CREATE INDEX IF NOT EXISTS idx_scholarship_applications_student ON public.scholarship_applications(student_id);

-- 6. SEED DATA GÜNCELLEME — yeni kolonları doldur
UPDATE public.students SET
  semester = 3,
  academic_standing = 'good',
  extracurricular_score = 5
WHERE semester IS NULL;

UPDATE public.scholarships SET
  amount_per_year = 12000,
  duration_months = 12,
  scholarship_type = 'partial_tuition',
  max_semester = 8,
  min_extracurricular_score = 0,
  max_household_income = 500000
WHERE amount_per_year IS NULL;
