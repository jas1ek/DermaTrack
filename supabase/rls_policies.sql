
-- DermaTrack - PostgreSQL RLS Policies
-- Kontrola dostepu do danych pacjentow (Z3)

BEGIN;

-- 1. Wlaczenie RLS

ALTER TABLE public.profiles
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.lesions
ENABLE ROW LEVEL SECURITY;

ALTER TABLE public.lesion_photos
ENABLE ROW LEVEL SECURITY;

-- 2. Uprawnienia tabel

REVOKE ALL ON public.profiles
FROM anon, authenticated;

REVOKE ALL ON public.lesions
FROM anon, authenticated;

REVOKE ALL ON public.lesion_photos
FROM anon, authenticated;

GRANT SELECT, INSERT
ON public.profiles TO authenticated;

-- Uzytkownik nie moze edytowac kolumny role
GRANT UPDATE (display_name)
ON public.profiles TO authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE
ON public.lesions TO authenticated;

GRANT SELECT, INSERT, DELETE
ON public.lesion_photos TO authenticated;

-- 3. Polityki profiles

CREATE POLICY "Read own profile"
ON public.profiles
FOR SELECT TO authenticated
USING (
    id = (SELECT auth.uid())
);

CREATE POLICY "Create patient profile"
ON public.profiles
FOR INSERT TO authenticated
WITH CHECK (
    id = (SELECT auth.uid())
    AND role = 'patient'
);

CREATE POLICY "Update own profile"
ON public.profiles
FOR UPDATE TO authenticated
USING (
    id = (SELECT auth.uid())
)
WITH CHECK (
    id = (SELECT auth.uid())
);

-- 4. Polityki lesions
-- Pacjent moze operowac tylko na swoich znamionach

CREATE POLICY "Read own lesions"
ON public.lesions
FOR SELECT TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

CREATE POLICY "Create own lesions"
ON public.lesions
FOR INSERT TO authenticated
WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

CREATE POLICY "Update own lesions"
ON public.lesions
FOR UPDATE TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
)
WITH CHECK (
    user_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

CREATE POLICY "Delete own lesions"
ON public.lesions
FOR DELETE TO authenticated
USING (
    user_id = (SELECT auth.uid())
    AND EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

-- 5. Polityki lesion_photos
-- Dostep przez powiazanie fotografii ze znamieniem

CREATE POLICY "Read own photos"
ON public.lesion_photos
FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.lesions
        WHERE lesions.id = lesion_photos.lesion_id
          AND lesions.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY "Create own photos"
ON public.lesion_photos
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.lesions
        WHERE lesions.id = lesion_photos.lesion_id
          AND lesions.user_id = (SELECT auth.uid())
    )
);

CREATE POLICY "Delete own photos"
ON public.lesion_photos
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.lesions
        WHERE lesions.id = lesion_photos.lesion_id
          AND lesions.user_id = (SELECT auth.uid())
    )
);

COMMIT;
