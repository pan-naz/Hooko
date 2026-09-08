-- Daily analysis usage tracking
--
-- Tracks how many analyses each user has completed on a given local date.
-- Keyed by RevenueCat `appUserId` (an anonymous, device-stable identifier)
-- rather than auth.uid so the limit follows the subscription across the
-- user's devices (RC restores appUserId on the same Apple ID).
--
-- One row per (app_user_id, usage_date). The unique constraint lets us
-- upsert atomically and prevents duplicate rows for the same day.

CREATE TABLE IF NOT EXISTS daily_analysis_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  app_user_id text NOT NULL,
  usage_date date NOT NULL,
  count integer NOT NULL DEFAULT 0,
  tier text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT daily_analysis_usage_user_date_unique UNIQUE (app_user_id, usage_date)
);

CREATE INDEX IF NOT EXISTS idx_daily_analysis_usage_user_date
  ON daily_analysis_usage (app_user_id, usage_date);

ALTER TABLE daily_analysis_usage ENABLE ROW LEVEL SECURITY;

-- Per project policy: authenticated users can perform all operations.
-- (App uses anonymous Supabase auth on launch, so every client is authenticated.)
CREATE POLICY "Authenticated users can manage daily usage"
  ON daily_analysis_usage
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);
