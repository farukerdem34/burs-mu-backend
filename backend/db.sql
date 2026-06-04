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
  name text NOT NULL,
  CONSTRAINT income_levels_pkey PRIMARY KEY (name)
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
  income_status USER-DEFINED NOT NULL CHECK (check_income_level(income_status)),
  created_at timestamp with time zone DEFAULT now(),
  about text,
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
  min_gpa numeric DEFAULT 0.00,
  target_cities ARRAY DEFAULT '{}'::text[] CHECK (check_cities(target_cities)),
  target_departments ARRAY DEFAULT '{}'::text[] CHECK (check_departments(target_departments)),
  target_income_levels ARRAY DEFAULT '{}'::income_level[] CHECK (check_income_levels(target_income_levels)),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT scholarships_pkey PRIMARY KEY (id),
  CONSTRAINT scholarships_donor_id_fkey FOREIGN KEY (donor_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.matches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  scholarship_id uuid,
  student_id uuid,
  status USER-DEFINED DEFAULT 'matched'::match_status,
  created_at timestamp with time zone DEFAULT now(),
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
  CONSTRAINT donors_pkey PRIMARY KEY (profile_id),
  CONSTRAINT donors_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES public.profiles(id)
);
