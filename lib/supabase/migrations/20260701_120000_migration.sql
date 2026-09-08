-- Security hardening migration
-- Addresses Supabase advisor warnings:
--   1) daily_analysis_usage RLS policy was permissive (USING true)
--   2) Public 'Videos' bucket had a broad SELECT policy allowing listing
--   3) public.rls_auto_enable() SECURITY DEFINER was executable by anon/authenticated
--   4) niches / techniques / viral_examples allowed anon role access

-- =========================================================================
-- 1) daily_analysis_usage: scope RLS to the calling auth user
-- =========================================================================

-- Add auth.uid()-bound column so each row is owned by the signed-in user.
-- Default lets existing client code keep working without changes; the
-- upsert conflict target (app_user_id, usage_date) ensures the original
-- owner's auth_uid is preserved on subsequent increments.
ALTER TABLE public.daily_analysis_usage
  ADD COLUMN IF NOT EXISTS auth_uid uuid DEFAULT auth.uid();

-- Backfill any pre-existing rows with the current caller's uid is not
-- possible (migration runs as superuser). Leave NULLs; policies below
-- treat NULL auth_uid as inaccessible going forward.

-- Drop the old permissive policy
DROP POLICY IF EXISTS "Authenticated users can manage daily usage"
  ON public.daily_analysis_usage;

-- Replace with per-user scoped policies
CREATE POLICY "daily_usage_select_own"
  ON public.daily_analysis_usage
  FOR SELECT
  TO authenticated
  USING (auth_uid = auth.uid());

CREATE POLICY "daily_usage_insert_own"
  ON public.daily_analysis_usage
  FOR INSERT
  TO authenticated
  WITH CHECK (auth_uid = auth.uid() OR auth_uid IS NULL);

CREATE POLICY "daily_usage_update_own"
  ON public.daily_analysis_usage
  FOR UPDATE
  TO authenticated
  USING (auth_uid = auth.uid())
  WITH CHECK (auth_uid = auth.uid());

CREATE POLICY "daily_usage_delete_own"
  ON public.daily_analysis_usage
  FOR DELETE
  TO authenticated
  USING (auth_uid = auth.uid());

-- =========================================================================
-- 2) Storage: remove broad SELECT policy on the public 'Videos' bucket.
--    Public buckets serve object URLs without a SELECT policy; removing it
--    prevents clients from listing all files in the bucket.
-- =========================================================================

DROP POLICY IF EXISTS "videos_select" ON storage.objects;

-- Keep INSERT/DELETE policies intact (clients still need to upload + clean up
-- their own temp files). Optionally scope them tighter:
DROP POLICY IF EXISTS "videos_insert" ON storage.objects;
CREATE POLICY "videos_insert"
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'Videos');

DROP POLICY IF EXISTS "videos_delete" ON storage.objects;
CREATE POLICY "videos_delete"
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (bucket_id = 'Videos');

-- =========================================================================
-- 3) Revoke EXECUTE on the SECURITY DEFINER housekeeping function from
--    client-facing roles. It is an event-trigger helper and should not be
--    callable via the REST API.
-- =========================================================================

REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM anon;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM authenticated;

-- =========================================================================
-- 4) Restrict read-only catalog tables to authenticated role only.
--    The app signs users in anonymously on launch, so 'authenticated' still
--    covers all real clients; this just stops fully unauthenticated requests.
-- =========================================================================

-- niches
DROP POLICY IF EXISTS "Anyone can read niches" ON public.niches;
CREATE POLICY "Authenticated can read niches"
  ON public.niches
  FOR SELECT
  TO authenticated
  USING (true);

-- techniques
DROP POLICY IF EXISTS "techniques_select_policy" ON public.techniques;
CREATE POLICY "techniques_select_policy"
  ON public.techniques
  FOR SELECT
  TO authenticated
  USING (true);

-- viral_examples
DROP POLICY IF EXISTS "Allow authenticated read access on viral_examples"
  ON public.viral_examples;
CREATE POLICY "Authenticated can read viral_examples"
  ON public.viral_examples
  FOR SELECT
  TO authenticated
  USING (true);
