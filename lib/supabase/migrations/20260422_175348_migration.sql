-- Migration: Add niche_name column for debugging/review purposes
-- This column stores the niche name alongside niche_id for easier manual inspection

ALTER TABLE viral_examples 
ADD COLUMN IF NOT EXISTS niche_name text;

-- Add comment for documentation
COMMENT ON COLUMN viral_examples.niche_name IS 'Cached niche name for debugging - populated from niches table during insert';
