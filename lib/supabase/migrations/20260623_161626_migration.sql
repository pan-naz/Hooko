-- Schedule a daily cleanup of old rows in daily_analysis_usage.
-- Retention: keep today + yesterday + day-before-yesterday (i.e. delete rows
-- with usage_date strictly older than CURRENT_DATE - 2 days). The 2-day buffer
-- guarantees we never touch a row that could still be "today" for any
-- timezone on Earth, so the current-day counter is never affected.

-- Enable pg_cron (safe to run if already enabled).
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Remove any previous schedule with the same name to keep this migration idempotent.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'cleanup_daily_analysis_usage') THEN
    PERFORM cron.unschedule('cleanup_daily_analysis_usage');
  END IF;
END
$$;

-- Run every day at 03:00 UTC. Deletes rows older than 2 days.
SELECT cron.schedule(
  'cleanup_daily_analysis_usage',
  '0 3 * * *',
  $$DELETE FROM public.daily_analysis_usage WHERE usage_date < (CURRENT_DATE - INTERVAL '2 days')$$
);

-- Run cleanup once now so the table is trimmed immediately after applying this migration.
DELETE FROM public.daily_analysis_usage WHERE usage_date < (CURRENT_DATE - INTERVAL '2 days');
