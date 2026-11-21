
-- Create the onboarding function
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
BEGIN
    -- Create the user profile
    INSERT INTO public.profiles (
        id,
        email,
        full_name
    )
    VALUES (
        NEW.id,
        NEW.email,
        NULLIF(NEW.raw_user_meta_data ->> 'full_name', '')
    );

    -- Seed default system categories
    INSERT INTO public.categories (
        user_id,
        name,
        type,
        scope,
        is_system,
        is_archived
    )
    VALUES
        (NEW.id, 'Penjualan', 'income', 'business', TRUE, FALSE),
        (NEW.id, 'Kulakan', 'expense', 'business', TRUE, FALSE),
        (NEW.id, 'Operasional', 'expense', 'business', TRUE, FALSE),
        (NEW.id, 'Gaji', 'expense', 'business', TRUE, FALSE),
        (NEW.id, 'Prive', 'expense', 'personal', TRUE, FALSE),
        (NEW.id, 'Belanja Harian', 'expense', 'personal', TRUE, FALSE),
        (NEW.id, 'Tagihan', 'expense', 'both', TRUE, FALSE),
        (NEW.id, 'Selisih Kas Masuk', 'income', 'both', TRUE, FALSE),
        (NEW.id, 'Selisih Kas Keluar', 'expense', 'both', TRUE, FALSE);

    RETURN NEW;
END;
$$;

-- Create the auth user trigger
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_user();
