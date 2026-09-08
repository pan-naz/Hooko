-- Migration: Update viral_examples table and add population_state tracking
-- Purpose: Change hook_technique (text) to technique_id (UUID FK) and track population progress

-- Step 1: Drop the old hook_technique column
ALTER TABLE viral_examples DROP COLUMN IF EXISTS hook_technique;

-- Step 2: Add technique_id as UUID foreign key to techniques table
ALTER TABLE viral_examples ADD COLUMN technique_id UUID REFERENCES techniques(id);

-- Step 3: Create indexes for faster lookups
CREATE INDEX IF NOT EXISTS idx_viral_examples_technique_id ON viral_examples(technique_id);
CREATE INDEX IF NOT EXISTS idx_viral_examples_niche_id ON viral_examples(niche_id);

-- Step 4: Create population_state table to track progress between runs
CREATE TABLE IF NOT EXISTS population_state (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  last_niche_offset INTEGER NOT NULL DEFAULT 0,
  last_run_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  total_niches_processed INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 5: Enable RLS on population_state
ALTER TABLE population_state ENABLE ROW LEVEL SECURITY;

-- Step 6: Create policy for service role access (edge functions use service role)
CREATE POLICY "Service role can manage population_state"
  ON population_state
  FOR ALL
  USING (true)
  WITH CHECK (true);

-- Step 7: Insert initial state row if not exists
INSERT INTO population_state (id, last_niche_offset, total_niches_processed)
VALUES (gen_random_uuid(), 0, 0);
