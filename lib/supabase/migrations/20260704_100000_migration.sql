-- Lock down public.daily_analysis_usage so the Flutter client can no longer
-- read/write it directly via PostgREST. All access now goes through the
-- track-daily-usage edge function, which uses the service role key and
-- bypasses RLS.
--
-- The table itself, its data, and the existing cron cleanup job are left
-- untouched. We just remove the "authenticated can manage" policy.

-- Drop the prior permissive policy (if present).
DROP POLICY IF EXISTS "Authenticated users can manage daily usage"
  ON public.daily_analysis_usage;

-- Defensive: drop the older per-user policies if any are still lingering.
DROP POLICY IF EXISTS "daily_usage_select_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_insert_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_update_own" ON public.daily_analysis_usage;
DROP POLICY IF EXISTS "daily_usage_delete_own" ON public.daily_analysis_usage;

-- RLS stays enabled. With no policies present, authenticated/anon roles
-- have NO access. Only the service_role (used by the edge function) can
-- read/write the table.
ALTER TABLE public.daily_analysis_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_analysis_usage FORCE ROW LEVEL SECURITY;
