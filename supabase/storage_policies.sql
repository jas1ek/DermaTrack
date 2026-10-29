
-- DermaTrack - Supabase Storage RLS
-- Prywatny bucket: lesion-photos
-- Dostep do fotografii tylko dla ich wlascicieli

BEGIN;

-- 1. Pacjent moze przesylac zdjecia tylko do folderu ze swoim UUID

CREATE POLICY "Patient upload own photos"
ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
    bucket_id = 'lesion-photos'
    AND (storage.foldername(name))[1] =
        (SELECT auth.uid())::text
    AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

-- 2. Pacjent moze pobierac tylko swoje fotografie

CREATE POLICY "Patient read own photos"
ON storage.objects
FOR SELECT TO authenticated
USING (
    bucket_id = 'lesion-photos'
    AND (storage.foldername(name))[1] =
        (SELECT auth.uid())::text
    AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

-- 3. Pacjent moze usuwac tylko swoje fotografie

CREATE POLICY "Patient delete own photos"
ON storage.objects
FOR DELETE TO authenticated
USING (
    bucket_id = 'lesion-photos'
    AND (storage.foldername(name))[1] =
        (SELECT auth.uid())::text
    AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE id = (SELECT auth.uid())
          AND role = 'patient'
    )
);

COMMIT;
