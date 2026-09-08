-- Remove unnecessary write policies from techniques table (static data)
-- Only keep SELECT policy for public read access

DROP POLICY IF EXISTS "techniques_insert_policy" ON techniques;
DROP POLICY IF EXISTS "techniques_update_policy" ON techniques;
DROP POLICY IF EXISTS "techniques_delete_policy" ON techniques;
