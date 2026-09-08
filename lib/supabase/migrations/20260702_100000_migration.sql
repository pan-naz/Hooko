-- Fix: cross-device / cross-reinstall daily usage counter
--
-- The previous hardening migration (20260701_120000) scoped
-- public.daily_analysis_usage RLS to auth.uid(). That broke the product
-- requirement: the counter must follow the user's subscription across
-- devices AND across reinstalls.
--
-- The cross-device stable key is RevenueCat's `originalAppUserId`
-- (stored as app_user_id). Supabase anonymous auth.uid() is NOT stable
-- across reinstalls and is per-device, so it cannot be used as the row
-- owner here.
--
-- We restore a single "authenticated can manage" policy. The table stays
-- protected against fully unauthenticated requests (which was the actual
-- advisor warning), while the client continues to scope reads/writes by
-- app_user_id.

-- 1) Drop the per-user policies introduced by the previous migration.
DROP POLICY IF EXISTS "daily_usage_select_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_insert_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_update_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_delete_own" ON public.daily_analysis_usage;

-- 2) Drop the auth_uid column (no longer used; was causing upsert conflicts
--    on reinstall because the existing row's auth_uid != new auth.uid()).
ALTER TABLE public.daily_analysis_usage
  DROP COLUMN IF EXISTS auth_uid;

-- 3) Restore a single policy that allows any authenticated (anonymous)
--    Supabase user to read/write the table. The client scopes by
--    app_user_id (RevenueCat originalAppUserId) which is the actual
--    cross-device identity.
CREATE POLICY "Authenticated users can manage daily usage"
  ON public.daily_analysis_usage
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
