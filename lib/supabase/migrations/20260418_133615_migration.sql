-- Migration: Change technique_id to technique_ids array (keep all other columns)

-- Step 1: Drop old technique_id foreign key and column
ALTER TABLE viral_examples DROP CONSTRAINT IF EXISTS viral_examples_technique_id_fkey;
ALTER TABLE viral_examples DROP COLUMN IF EXISTS technique_id;

-- Step 2: Add technique_ids as UUID array (supports 2-3 techniques per video)
ALTER TABLE viral_examples ADD COLUMN IF NOT EXISTS technique_ids uuid[] DEFAULT '{}';

-- Add comment for clarity
COMMENT ON COLUMN viral_examples.technique_ids IS 'Array of 2-3 technique UUIDs ordered by relevance';
