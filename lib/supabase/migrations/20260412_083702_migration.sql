-- Create viral_examples table for storing curated YouTube Shorts
-- that match specific niches and hook techniques

CREATE TABLE IF NOT EXISTS public.viral_examples (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    youtube_video_id TEXT NOT NULL,
    niche_id UUID NOT NULL REFERENCES public.niches(id) ON DELETE CASCADE,
    hook_technique TEXT NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Create index for faster lookups by niche and technique
CREATE INDEX idx_viral_examples_niche_technique 
ON public.viral_examples(niche_id, hook_technique);

-- Enable Row Level Security
ALTER TABLE public.viral_examples ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read viral examples
CREATE POLICY "Allow authenticated read access on viral_examples"
ON public.viral_examples
FOR SELECT
TO authenticated
USING (true);

-- Allow anonymous users to read viral examples (for demo mode)
CREATE POLICY "Allow anonymous read access on viral_examples"
ON public.viral_examples
FOR SELECT
TO anon
USING (true);
