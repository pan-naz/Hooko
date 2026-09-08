-- Add slug column to techniques table
ALTER TABLE techniques 
ADD COLUMN slug text;

-- Populate slug from name (lowercase, replace spaces with hyphens)
UPDATE techniques 
SET slug = lower(replace(replace(replace(name, ' ', '-'), '''', ''), '"', ''));

-- Make slug NOT NULL and UNIQUE after populating
ALTER TABLE techniques 
ALTER COLUMN slug SET NOT NULL;

ALTER TABLE techniques 
ADD CONSTRAINT techniques_slug_unique UNIQUE (slug);

-- Create index for faster lookups
CREATE INDEX idx_techniques_slug ON techniques(slug);
