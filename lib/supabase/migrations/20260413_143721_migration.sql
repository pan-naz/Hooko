-- Add additional metadata columns to viral_examples table
-- These columns store YouTube video metadata for better display

ALTER TABLE public.viral_examples
ADD COLUMN IF NOT EXISTS title TEXT,
ADD COLUMN IF NOT EXISTS channel_name TEXT,
ADD COLUMN IF NOT EXISTS view_count BIGINT DEFAULT 0,
ADD COLUMN IF NOT EXISTS like_count BIGINT DEFAULT 0,
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- Add service role policy for edge function to insert data
CREATE POLICY "Allow service role full access on viral_examples"
ON public.viral_examples
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
