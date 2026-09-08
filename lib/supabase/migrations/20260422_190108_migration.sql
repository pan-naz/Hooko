-- Add search_keywords column to niches table for more specific YouTube searches
ALTER TABLE niches
ADD COLUMN search_keywords TEXT;

-- Add comment explaining the column
COMMENT ON COLUMN niches.search_keywords IS 'Specific YouTube search terms for this niche. Falls back to niche name if empty.';
