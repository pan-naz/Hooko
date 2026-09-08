-- Fix: analysis upload was returning 403 ("Permission denied") after the
-- previous security-hardening migration removed the broad SELECT policy on
-- the Videos bucket and didn't add an UPDATE policy.
--
-- The Flutter client uploads with `upsert: true`, which causes Supabase
-- Storage to require BOTH insert AND update privileges on storage.objects.
-- Without an UPDATE policy the upload is rejected even for brand new files.
--
-- We also re-add a narrow SELECT policy so the storage SDK can stat objects
-- it just uploaded (used internally by `uploadBinary`). The bucket itself
-- can remain public for object URL access; this policy only governs API
-- list/get calls via storage.objects.

-- =========================================================================
-- 1) Allow authenticated users to UPDATE objects in the Videos bucket.
--    Required for `upsert: true` uploads to succeed.
-- =========================================================================
DROP POLICY IF EXISTS "videos_update" ON storage.objects;
CREATE POLICY "videos_update"
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (bucket_id = 'Videos')
  WITH CHECK (bucket_id = 'Videos');

-- =========================================================================
-- 2) Re-add a scoped SELECT policy on the Videos bucket so the storage SDK
--    can read object metadata after upload. This only allows authenticated
--    users (incl. anonymous sign-ins) to read objects in this bucket via
--    the storage API; it does not expose listing to truly anonymous (no
--    JWT) requests, which is what the advisor warning was about.
-- =========================================================================
DROP POLICY IF EXISTS "videos_select" ON storage.objects;
CREATE POLICY "videos_select"
  ON storage.objects
  FOR SELECT
  TO authenticated
  USING (bucket_id = 'Videos');
