-- Add niche_name column to viral_examples table for easy viewing
-- This allows checking videos and their connected niches without joining tables

ALTER TABLE viral_examples 
ADD COLUMN IF NOT EXISTS niche_name TEXT;

-- Add comment explaining purpose
COMMENT ON COLUMN viral_examples.niche_name IS 'Denormalized niche name for easy viewing/debugging';
