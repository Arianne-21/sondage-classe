-- Run as neondb_owner on the production branch with database neondb selected.
-- This creates sondage_app without login; set its password in Neon Roles before using it.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'sondage_app') THEN
        CREATE ROLE sondage_app NOLOGIN NOBYPASSRLS;
    END IF;
END
$$;

CREATE TABLE IF NOT EXISTS public.reponses (
    id SERIAL PRIMARY KEY,
    prenom VARCHAR(50) NOT NULL
        CHECK (char_length(btrim(prenom)) BETWEEN 2 AND 50),
    filiere TEXT NOT NULL
        CHECK (filiere IN ('Informatique', 'Mathématiques', 'Physique', 'Lettres', 'Autre')),
    niveau TEXT NOT NULL
        CHECK (niveau IN ('Débutant', 'Intermédiaire', 'Avancé')),
    techno TEXT NOT NULL
        CHECK (techno IN ('Python', 'JavaScript', 'PHP', 'Java', 'Autre')),
    avis VARCHAR(300),
    cree_le TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS reponses_techno_idx ON public.reponses (techno);

REVOKE ALL ON TABLE public.reponses FROM PUBLIC;
REVOKE ALL ON SEQUENCE public.reponses_id_seq FROM PUBLIC;
GRANT CONNECT ON DATABASE neondb TO sondage_app;
GRANT USAGE ON SCHEMA public TO sondage_app;
GRANT SELECT, INSERT ON TABLE public.reponses TO sondage_app;
GRANT USAGE, SELECT ON SEQUENCE public.reponses_id_seq TO sondage_app;

ALTER TABLE public.reponses ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS reponses_app_select ON public.reponses;
CREATE POLICY reponses_app_select ON public.reponses
    FOR SELECT TO sondage_app USING (true);
DROP POLICY IF EXISTS reponses_app_insert ON public.reponses;
CREATE POLICY reponses_app_insert ON public.reponses
    FOR INSERT TO sondage_app WITH CHECK (true);
