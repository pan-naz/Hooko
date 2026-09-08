-- Add niche_name column to viral_examples table for easier viewing
ALTER TABLE viral_examples
ADD COLUMN niche_name TEXT;

-- Add comment for documentation
COMMENT ON COLUMN viral_examples.niche_name IS 'Denormalized niche name for easier viewing in admin/debug contexts';
