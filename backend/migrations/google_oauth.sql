-- Migration SQL pour ajouter le support Google OAuth
-- Exécuter ce script pour mettre à jour la table users

-- 1. Rendre hashed_password nullable (pour les utilisateurs Google)
ALTER TABLE users ALTER COLUMN hashed_password DROP NOT NULL;

-- 2. Ajouter la colonne google_id
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR UNIQUE;

-- 3. Ajouter la colonne profile_picture
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_picture VARCHAR;

-- 4. Ajouter la colonne auth_provider
ALTER TABLE users ADD COLUMN IF NOT EXISTS auth_provider VARCHAR DEFAULT 'email';

-- 5. Créer un index sur google_id pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);

-- Vérifier les colonnes ajoutées
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users'
ORDER BY ordinal_position;
