-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.cities (
  name text NOT NULL,
  CONSTRAINT cities_pkey PRIMARY KEY (name)
);
CREATE TABLE public.departments (
  name text NOT NULL,
  CONSTRAINT departments_pkey PRIMARY KEY (name)
);
CREATE TABLE public.income_levels (
  value integer NOT NULL,
  CONSTRAINT income_levels_pkey PRIMARY KEY (value)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  role USER-DEFINED NOT NULL CHECK (check_user_role(role)),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.students (
  profile_id uuid NOT NULL,
  gpa numeric CHECK (gpa >= 0.00 AND gpa <= 4.00),
  city text NOT NULL,
  department text NOT NULL,
  income_status smallint NOT NULL CHECK (income_status = ANY (ARRAY[0, 1, 2])),
  created_at timestamp with time zone DEFAULT now(),
  about text,
  semester smallint CHECK (semester >= 1 AND semester <= 12),
  family_income numeric CHECK (family_income >= 0::numeric),
  household_size smallint CHECK (household_size >= 1),
  num_siblings_in_education smallint DEFAULT 0 CHECK (num_siblings_in_education >= 0),
  has_disability boolean DEFAULT false,
  is_orphan boolean DEFAULT false,
  is_refugee boolean DEFAULT false,
  academic_standing text DEFAULT 'good'::text CHECK (academic_standing = ANY (ARRAY['probation'::text, 'good'::text, 'honor'::text, 'high_honor'::text])),
  extracurricular_score smallint DEFAULT 0 CHECK (extracurricular_score >= 0 AND extracurricular_score <= 10),
  CONSTRAINT students_pkey PRIMARY KEY (profile_id),
  CONSTRAINT students_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id),
  CONSTRAINT students_city_fkey FOREIGN KEY (city) REFERENCES public.cities(name),
  CONSTRAINT students_department_fkey FOREIGN KEY (department) REFERENCES public.departments(name)
);
CREATE TABLE public.scholarships (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  donor_id uuid,
  title text NOT NULL,
  quota integer NOT NULL DEFAULT 1,
  is_active boolean DEFAULT true,
  min_gpa numeric DEFAULT 0.00 CHECK (min_gpa >= 0.00 AND min_gpa <= 4.00),
  target_cities ARRAY DEFAULT '{}'::text[] CHECK (check_cities(target_cities)),
  target_departments ARRAY DEFAULT '{}'::text[] CHECK (check_departments(target_departments)),
  target_income_levels ARRAY DEFAULT '{}'::smallint[],
  created_at timestamp with time zone DEFAULT now(),
  amount_per_year numeric CHECK (amount_per_year >= 0::numeric),
  duration_months integer DEFAULT 12 CHECK (duration_months >= 1),
  scholarship_type text DEFAULT 'partial_tuition'::text CHECK (scholarship_type = ANY (ARRAY['full_tuition'::text, 'partial_tuition'::text, 'living_stipend'::text, 'one_time'::text])),
  preferred_gender text CHECK (preferred_gender = ANY (ARRAY['male'::text, 'female'::text])),
  requires_essay boolean DEFAULT false,
  requires_interview boolean DEFAULT false,
  accepts_disability boolean DEFAULT true,
  accepts_orphan boolean DEFAULT true,
  accepts_refugee boolean DEFAULT true,
  max_semester smallint CHECK (max_semester >= 1 AND max_semester <= 12),
  min_extracurricular_score smallint DEFAULT 0 CHECK (min_extracurricular_score >= 0 AND min_extracurricular_score <= 10),
  max_household_income numeric CHECK (max_household_income >= 0::numeric),
  CONSTRAINT scholarships_pkey PRIMARY KEY (id),
  CONSTRAINT scholarships_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.matches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  scholarship_id uuid,
  student_id uuid,
  status USER-DEFINED DEFAULT 'matched'::match_status,
  created_at timestamp with time zone DEFAULT now(),
  score_breakdown jsonb,
  score_components jsonb,
  CONSTRAINT matches_pkey PRIMARY KEY (id),
  CONSTRAINT matches_scholarship_id_fkey FOREIGN KEY (scholarship_id) REFERENCES public.scholarships(id),
  CONSTRAINT matches_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(profile_id)
);
CREATE TABLE public.user_roles (
  name text NOT NULL,
  CONSTRAINT user_roles_pkey PRIMARY KEY (name)
);
CREATE TABLE public.donors (
  profile_id uuid NOT NULL,
  is_verified boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  name text,
  CONSTRAINT donors_pkey PRIMARY KEY (profile_id),
  CONSTRAINT donors_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.scholarship_applications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  scholarship_id uuid NOT NULL,
  student_id uuid NOT NULL,
  essay_text text,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'reviewed'::text, 'shortlisted'::text, 'accepted'::text, 'rejected'::text])),
  interview_score smallint CHECK (interview_score >= 0 AND interview_score <= 100),
  essay_score smallint CHECK (essay_score >= 0 AND essay_score <= 100),
  applied_at timestamp with time zone DEFAULT now(),
  CONSTRAINT scholarship_applications_pkey PRIMARY KEY (id),
  CONSTRAINT scholarship_applications_scholarship_id_fkey FOREIGN KEY (scholarship_id) REFERENCES public.scholarships(id),
  CONSTRAINT scholarship_applications_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.students(profile_id)
);
