-- ============================================================
-- Migration 002: Admin role and authentication support
-- ============================================================

-- 1. Add 'admin' to the user_role enum
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_enum
        WHERE enumlabel = 'admin'
        AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'user_role')
    ) THEN
        ALTER TYPE user_role ADD VALUE 'admin';
    END IF;
END
$$;

-- 2. Add admin to user_roles reference table
INSERT INTO public.user_roles (name) VALUES ('admin')
ON CONFLICT (name) DO NOTHING;

-- 3. Create a default admin user
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at)
VALUES (
    '00000000-0000-0000-0000-000000000000',
    'admin@burs.com',
    crypt('admin123', gen_salt('bf')),
    now(),
    now(),
    '{}'::jsonb,
    '{}'::jsonb,
    now(),
    now()
)
ON CONFLICT (id) DO NOTHING;

-- 4. Create admin profile
INSERT INTO public.profiles (id, role) VALUES ('00000000-0000-0000-0000-000000000000', 'admin')
ON CONFLICT (id) DO NOTHING;
