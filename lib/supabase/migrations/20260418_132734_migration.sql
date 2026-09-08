-- Add technique_ids column to store 2-3 techniques per viral example
ALTER TABLE viral_examples
ADD COLUMN technique_ids uuid[] DEFAULT '{}';

-- Copy existing technique_id to technique_ids array for backward compatibility
UPDATE viral_examples 
SET technique_ids = ARRAY[technique_id]::uuid[]
WHERE technique_id IS NOT NULL;
