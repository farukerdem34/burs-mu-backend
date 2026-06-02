-- 1. ENUM TİPLERİ (Veri bütünlüğünü sağlamak ve hızlı filtreleme için)
-- Öğrenci ve bağışçı profillerini ayırmak için
CREATE TYPE user_role AS ENUM ('student', 'donor');

-- Gelir durumunu standardize etmek için (Örn: 1 en düşük, 3 en yüksek vb. gibi düşünülebilir)
CREATE TYPE income_level AS ENUM ('low', 'medium', 'high');

-- Başvuru/Eşleşme durumları
CREATE TYPE match_status AS ENUM ('matched', 'applied', 'under_review', 'approved', 'rejected');


-- 2. PROFİLLER TABLOSU (Supabase Auth ile senkronize çalışır)
CREATE TABLE public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);


-- 3. ÖĞRENCİ TABLOSU (Sadece eşleştirmede kullanılacak KANITLANABİLİR metrikler)
CREATE TABLE public.students (
    profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE PRIMARY KEY,
    gpa NUMERIC(3,2) CHECK (gpa >= 0.00 AND gpa <= 4.00), -- 0 ile 4 arası not ortalaması
    city TEXT NOT NULL, -- Okuduğu şehir
    department TEXT NOT NULL, -- Okuduğu bölüm
    income_status income_level NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE, -- Belgeleri onaylanmış mı? (Güven için kritik)
    -- İsim, soyisim gibi kişisel veriler eşleştirmeyi ilgilendirmediği için bu aşamada eklenmedi. (İzolasyon prensibi)
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 4. BURSLAR / KRİTERLER TABLOSU (Bağışçının aradığı özellikler)
CREATE TABLE public.scholarships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    donor_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    quota INTEGER NOT NULL DEFAULT 1, -- Kaç öğrenciye verilecek
    is_active BOOLEAN DEFAULT TRUE,
    
    -- EŞLEŞTİRME KRİTERLERİ (Filtreleme Motorunun Kalbi)
    -- Array (Dizi) kullanımı çok önemlidir. Bağışçı birden fazla şehir veya bölüm seçebilir.
    min_gpa NUMERIC(3,2) DEFAULT 0.00,
    target_cities TEXT[] DEFAULT '{}', -- Boş ise tüm şehirler geçerli
    target_departments TEXT[] DEFAULT '{}', -- Boş ise tüm bölümler geçerli
    target_income_levels income_level[] DEFAULT '{}', -- Hangi gelir gruplarına verilecek?
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- 5. EŞLEŞMELER / BAŞVURULAR TABLOSU
CREATE TABLE public.matches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    scholarship_id UUID REFERENCES public.scholarships(id) ON DELETE CASCADE,
    student_id UUID REFERENCES public.students(profile_id) ON DELETE CASCADE,
    status match_status DEFAULT 'matched',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(scholarship_id, student_id) -- Bir öğrenci bir bursa sadece bir kez eşleşebilir/başvurabilir
);


-- 6. INDEXLER (Milisaniyelik arama performansı için)
-- PostgreSQL GIN indexleri, Array içinde arama yaparken inanılmaz hızlıdır.
CREATE INDEX idx_students_city ON public.students(city);
CREATE INDEX idx_students_department ON public.students(department);
CREATE INDEX idx_students_income ON public.students(income_status);
CREATE INDEX idx_scholarships_cities ON public.scholarships USING GIN (target_cities);
CREATE INDEX idx_scholarships_departments ON public.scholarships USING GIN (target_departments);


-- 7. ROW LEVEL SECURITY (RLS) POLİTİKALARI (Güvenlik)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scholarships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

-- Örnek Güvenlik Kuralı: Bir öğrenci sadece kendi verisini görebilir
CREATE POLICY "Students can view their own data" 
ON public.students FOR SELECT 
USING (auth.uid() = profile_id);
