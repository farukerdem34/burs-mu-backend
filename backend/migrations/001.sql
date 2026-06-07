-- ============================================================
-- Full Schema: Burs Eşleştirme Sistemi
-- ============================================================

-- 1. ENUM TYPES
CREATE TYPE user_role AS ENUM ('student', 'donor', 'admin');
CREATE TYPE match_status AS ENUM ('matched', 'applied', 'under_review', 'approved', 'rejected');

-- 2. REFERENCE TABLES (Foreign key hedefleri)
CREATE TABLE public.cities (
    name TEXT PRIMARY KEY
);

INSERT INTO public.cities (name) VALUES
('Adana'), ('Adıyaman'), ('Afyon'), ('Ağrı'), ('Aksaray'), ('Amasya'),
('Ankara'), ('Antalya'), ('Ardahan'), ('Artvin'), ('Aydın'), ('Balıkesir'),
('Bartın'), ('Batman'), ('Bayburt'), ('Bilecik'), ('Bingöl'), ('Bitlis'),
('Bolu'), ('Burdur'), ('Bursa'), ('Çanakkale'), ('Çankırı'), ('Çorum'),
('Denizli'), ('Diyarbakır'), ('Düzce'), ('Edirne'), ('Elazığ'), ('Erzincan'),
('Erzurum'), ('Eskişehir'), ('Gaziantep'), ('Giresun'), ('Gümüşhane'),
('Hakkari'), ('Hatay'), ('Iğdır'), ('Isparta'), ('İstanbul'), ('İzmir'),
('Kahramanmaraş'), ('Karabük'), ('Karaman'), ('Kars'), ('Kastamonu'),
('Kayseri'), ('Kırıkkale'), ('Kırklareli'), ('Kırşehir'), ('Kilis'),
('Kocaeli'), ('Konya'), ('Kütahya'), ('Malatya'), ('Manisa'), ('Mardin'),
('Mersin'), ('Muğla'), ('Muş'), ('Nevşehir'), ('Niğde'), ('Ordu'),
('Osmaniye'), ('Rize'), ('Sakarya'), ('Samsun'), ('Siirt'), ('Sinop'),
('Sivas'), ('Şanlıurfa'), ('Şırnak'), ('Tekirdağ'), ('Tokat'), ('Trabzon'),
('Tunceli'), ('Uşak'), ('Van'), ('Yalova'), ('Yozgat'), ('Zonguldak');

ALTER TABLE public.cities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read cities" ON public.cities FOR SELECT USING (true);


CREATE TABLE public.departments (
    name TEXT PRIMARY KEY
);

ALTER TABLE public.departments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read departments" ON public.departments FOR SELECT USING (true);


CREATE TABLE public.income_levels (
    value SMALLINT PRIMARY KEY
);

ALTER TABLE public.income_levels ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read income_levels" ON public.income_levels FOR SELECT USING (true);

INSERT INTO public.income_levels (value) VALUES (0), (1), (2);


CREATE TABLE public.user_roles (
    name TEXT PRIMARY KEY
);

INSERT INTO public.user_roles (name) VALUES ('student'), ('donor'), ('admin');

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read user_roles" ON public.user_roles FOR SELECT USING (true);


-- 3. PROFILES (Supabase Auth ile senkronize)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- profiles.role sadece user_roles tablosundaki değerleri alabilir
CREATE FUNCTION check_user_role(role user_role) RETURNS boolean AS $$
    SELECT role::text IN (SELECT name FROM public.user_roles);
$$ LANGUAGE sql;

ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check CHECK (check_user_role(role));


-- 4. STUDENTS
CREATE TABLE public.students (
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    gpa NUMERIC(3,2) CHECK (gpa >= 0.00 AND gpa <= 4.00),
    city TEXT NOT NULL REFERENCES public.cities(name),
    department TEXT NOT NULL REFERENCES public.departments(name),
    income_status SMALLINT NOT NULL CHECK (income_status IN (0, 1, 2)),
    about TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Students can view their own data" ON public.students FOR SELECT USING (auth.uid() = profile_id);


-- 5. DONORS
CREATE TABLE public.donors (
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT,
    is_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.donors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Everyone can read donors" ON public.donors FOR SELECT USING (true);

-- 6. SCHOLARSHIPS
CREATE TABLE public.scholarships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    donor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    quota INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    min_gpa NUMERIC(3,2) DEFAULT 0.00 CHECK (min_gpa >= 0.00 AND min_gpa <= 4.00),
    target_cities TEXT[] DEFAULT '{}',
    target_departments TEXT[] DEFAULT '{}',
    target_income_levels SMALLINT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.scholarships ENABLE ROW LEVEL SECURITY;

-- Array elemanları için FK-benzeri kontrol fonksiyonları
CREATE FUNCTION check_cities(cities text[]) RETURNS boolean AS $$
    SELECT CASE WHEN cities IS NULL OR array_length(cities, 1) IS NULL THEN true
           ELSE (SELECT bool_and(city IN (SELECT name FROM public.cities)) FROM unnest(cities) AS city)
           END;
$$ LANGUAGE sql;

CREATE FUNCTION check_departments(deps text[]) RETURNS boolean AS $$
    SELECT CASE WHEN deps IS NULL OR array_length(deps, 1) IS NULL THEN true
           ELSE (SELECT bool_and(dep IN (SELECT name FROM public.departments)) FROM unnest(deps) AS dep)
           END;
$$ LANGUAGE sql;

ALTER TABLE public.scholarships ADD CONSTRAINT scholarships_target_cities_check CHECK (check_cities(target_cities));
ALTER TABLE public.scholarships ADD CONSTRAINT scholarships_target_departments_check CHECK (check_departments(target_departments));


-- 7. MATCHES
CREATE TABLE public.matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    scholarship_id UUID REFERENCES public.scholarships(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(profile_id) ON DELETE CASCADE,
    status match_status DEFAULT 'matched',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(scholarship_id, student_id)
);

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;


-- 8. INDEXES
CREATE INDEX idx_students_city ON public.students(city);
CREATE INDEX idx_students_department ON public.students(department);
CREATE INDEX idx_students_income ON public.students(income_status);
CREATE INDEX idx_scholarships_cities ON public.scholarships USING GIN (target_cities);
CREATE INDEX idx_scholarships_departments ON public.scholarships USING GIN (target_departments);


-- 9. SEED DATA

-- Auth users
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES
('00000000-0000-0000-0000-000000000001', 'student1@test.com', '$2a$10$x', now(), now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
('00000000-0000-0000-0000-000000000002', 'student2@test.com', '$2a$10$x', now(), now(), '{}'::jsonb, '{}'::jsonb, now(), now()),
('00000000-0000-0000-0000-000000000003', 'donor1@test.com', '$2a$10$x', now(), now(), '{}'::jsonb, '{}'::jsonb, now(), now())
ON CONFLICT (id) DO NOTHING;

-- Profiles
INSERT INTO public.profiles (id, role) VALUES
('00000000-0000-0000-0000-000000000001', 'student'),
('00000000-0000-0000-0000-000000000002', 'student'),
('00000000-0000-0000-0000-000000000003', 'donor')
ON CONFLICT (id) DO NOTHING;

-- Common departments
INSERT INTO public.departments (name) VALUES
('Bilgisayar Mühendisliği'),
('Elektrik Mühendisliği'),
('Makine Mühendisliği')
ON CONFLICT (name) DO NOTHING;

-- Students
INSERT INTO public.students (profile_id, gpa, city, department, income_status) VALUES
('00000000-0000-0000-0000-000000000001', 3.50, 'İstanbul', 'Bilgisayar Mühendisliği', 0),
('00000000-0000-0000-0000-000000000002', 2.80, 'Ankara', 'Elektrik Mühendisliği', 1)
ON CONFLICT (profile_id) DO NOTHING;

-- Donors
INSERT INTO public.donors (profile_id, name, is_verified) VALUES
('00000000-0000-0000-0000-000000000003', 'Test Donor', TRUE)
ON CONFLICT (profile_id) DO NOTHING;

-- Scholarships
INSERT INTO public.scholarships (id, donor_id, title, quota, is_active, min_gpa, target_cities, target_departments, target_income_levels) VALUES
('c690e7fd-51ff-4081-8cc9-c66161078275', '00000000-0000-0000-0000-000000000003', 'İstanbul Teknoloji Bursu', 5, TRUE, 2.5,
 ARRAY['İstanbul']::text[],
 ARRAY['Bilgisayar Mühendisliği', 'Elektrik Mühendisliği']::text[],
 ARRAY[0, 1]::SMALLINT[]),
('9ff2c06e-09c7-4e00-829b-9a03472460a6', '00000000-0000-0000-0000-000000000003', 'Ankara Mühendislik Bursu', 3, TRUE, 3.0,
 ARRAY['Ankara']::text[],
 ARRAY['Elektrik Mühendisliği', 'Makine Mühendisliği']::text[],
 ARRAY[0]::SMALLINT[]),
('324eb1e6-da6c-47e4-9e2d-1008f06191af', '00000000-0000-0000-0000-000000000003', 'Genel Başarı Bursu', 10, TRUE, 0.0,
 ARRAY[]::text[],
 ARRAY[]::text[],
 ARRAY[]::SMALLINT[]),
('ab29ff54-4777-45ae-9c43-823115c22b6e', '00000000-0000-0000-0000-000000000003', 'Yüksek GPA Bursu', 2, TRUE, 3.5,
 ARRAY[]::text[],
 ARRAY[]::text[],
 ARRAY[]::SMALLINT[])
ON CONFLICT (id) DO NOTHING;
