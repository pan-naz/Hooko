-- =========================================================================
-- Make the 'Videos' storage bucket PRIVATE.
--
-- Why this is safe for the analysis flow:
--   • The Flutter client only UPLOADS to this bucket (with an authenticated
--     anonymous session) and never reads objects back via public URLs.
--   • The edge function `analyze-video` downloads the uploaded clip using
--     the SERVICE_ROLE key, which bypasses bucket privacy and RLS entirely.
--   • The edge function also deletes the object after analysis completes.
--
-- Effect:
--   • storage.buckets.public is flipped to false.
--   • Object URLs from getPublicUrl() will no longer return the file content
--     (none of the client code uses that for videos, so no flow breaks).
--   • RLS policies on storage.objects continue to govern who can INSERT /
--     UPDATE / DELETE / SELECT through the storage API.
--   • Resolves the Supabase advisor warning about a public bucket.
-- =========================================================================

UPDATE storage.buckets
SET public = false
WHERE id = 'Videos';
