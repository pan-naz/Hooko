-- Add tags and hashtags columns to viral_examples table
-- For storing YouTube video metadata for better niche/technique verification

-- YouTube tags (set by video creator)
ALTER TABLE viral_examples 
ADD COLUMN IF NOT EXISTS tags text[] DEFAULT '{}';

-- Hashtags extracted from video description
ALTER TABLE viral_examples 
ADD COLUMN IF NOT EXISTS hashtags text[] DEFAULT '{}';

-- Add comment for documentation
COMMENT ON COLUMN viral_examples.tags IS 'YouTube tags set by the video creator';
COMMENT ON COLUMN viral_examples.hashtags IS 'Hashtags extracted from video description (#fitness, #shorts, etc)';
