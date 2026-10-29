
-- DermaTrack - Database Schema
-- Poczatkowy model bazy danych (Z2)

-- 1. Profile uzytkownikow

CREATE TABLE public.profiles (
    id UUID PRIMARY KEY
        REFERENCES auth.users(id) ON DELETE CASCADE,

    display_name TEXT,

    role TEXT NOT NULL DEFAULT 'patient'
        CHECK (role IN ('patient', 'dermatologist')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Znamiona pacjentow

CREATE TABLE public.lesions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    user_id UUID NOT NULL
        REFERENCES auth.users(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    body_location TEXT NOT NULL,
    description TEXT,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Metadane fotografii znamion

CREATE TABLE public.lesion_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    lesion_id UUID NOT NULL
        REFERENCES public.lesions(id) ON DELETE CASCADE,

    storage_path TEXT NOT NULL UNIQUE,
    captured_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Indeksy

CREATE INDEX lesions_user_id_idx
ON public.lesions(user_id);

CREATE INDEX lesion_photos_lesion_id_idx
ON public.lesion_photos(lesion_id);

CREATE INDEX lesion_photos_captured_at_idx
ON public.lesion_photos(captured_at DESC);
