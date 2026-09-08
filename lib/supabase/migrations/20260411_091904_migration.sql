-- Create techniques table
CREATE TABLE IF NOT EXISTS techniques (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text NOT NULL CHECK (type IN ('audio', 'visual', 'emotion')),
  category text NOT NULL,
  description text,
  created_at timestamp with time zone DEFAULT now()
);

-- Enable RLS
ALTER TABLE techniques ENABLE ROW LEVEL SECURITY;

-- Allow all users to read techniques (public content)
CREATE POLICY "techniques_select_policy" ON techniques
  FOR SELECT USING (true);

-- Allow authenticated users to manage techniques
CREATE POLICY "techniques_insert_policy" ON techniques
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "techniques_update_policy" ON techniques
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "techniques_delete_policy" ON techniques
  FOR DELETE TO authenticated USING (true);

-- =====================================================
-- INSERT AUDIO TECHNIQUES (58)
-- =====================================================

-- Voice Delivery (15)
INSERT INTO techniques (name, type, category, description) VALUES
('Whisper hook', 'audio', 'Voice Delivery', 'Speaking quietly to create intimacy and draw viewers in'),
('Frustrated rant', 'audio', 'Voice Delivery', 'Genuine venting with raw emotion about a relatable problem'),
('Excited reveal', 'audio', 'Voice Delivery', 'High energy "OMG you guys" style delivery'),
('Calm authority', 'audio', 'Voice Delivery', 'Slow, confident tone that commands trust'),
('Sarcastic tone', 'audio', 'Voice Delivery', 'Mocking or ironic delivery for humor'),
('Vulnerable confession', 'audio', 'Voice Delivery', 'Honest, exposed emotional sharing'),
('Storytelling voice', 'audio', 'Voice Delivery', 'Narrative tone like telling a friend a secret'),
('Aggressive call-out', 'audio', 'Voice Delivery', 'Direct, confrontational addressing of the viewer'),
('Deadpan delivery', 'audio', 'Voice Delivery', 'Flat, emotionless tone for comedic effect'),
('Valley girl uptalk', 'audio', 'Voice Delivery', 'Rising intonation at end of sentences'),
('ASMR whisper', 'audio', 'Voice Delivery', 'Extremely soft, tingly voice quality'),
('News anchor voice', 'audio', 'Voice Delivery', 'Professional, authoritative broadcast tone'),
('Motivational preacher', 'audio', 'Voice Delivery', 'Inspirational, sermon-like passionate delivery'),
('Conspiracy theorist', 'audio', 'Voice Delivery', 'Hushed, secretive "they don''t want you to know"'),
('Rapid fire listing', 'audio', 'Voice Delivery', 'Quick succession of points without pause');

-- Pacing & Timing (12)
INSERT INTO techniques (name, type, category, description) VALUES
('Dramatic pause', 'audio', 'Pacing & Timing', 'Strategic silence before key reveal'),
('Breathless urgency', 'audio', 'Pacing & Timing', 'Speaking fast as if running out of time'),
('Slow build', 'audio', 'Pacing & Timing', 'Gradually increasing intensity throughout'),
('Stutter effect', 'audio', 'Pacing & Timing', 'Intentional verbal stumble for authenticity'),
('Mid-sentence cut', 'audio', 'Pacing & Timing', 'Editing cuts between words for rhythm'),
('Jump cut pacing', 'audio', 'Pacing & Timing', 'Rapid cuts removing dead air'),
('One breath hook', 'audio', 'Pacing & Timing', 'Entire hook delivered without pause'),
('Countdown delivery', 'audio', 'Pacing & Timing', '"3...2...1..." tension building'),
('Echo repeat', 'audio', 'Pacing & Timing', 'Repeating key phrase for emphasis'),
('Cliffhanger pause', 'audio', 'Pacing & Timing', 'Stopping before the expected word'),
('Speed ramping', 'audio', 'Pacing & Timing', 'Alternating between fast and slow speech'),
('Beat matching', 'audio', 'Pacing & Timing', 'Syncing speech rhythm to background music');

-- Sound Effects & Music (16)
INSERT INTO techniques (name, type, category, description) VALUES
('Trending audio overlay', 'audio', 'Sound Effects', 'Using viral sound clips as background'),
('Sound effect punctuation', 'audio', 'Sound Effects', 'Ding, boom, whoosh to emphasize points'),
('Music drop sync', 'audio', 'Sound Effects', 'Key moment aligned with beat drop'),
('Record scratch', 'audio', 'Sound Effects', 'Sudden music stop for shock effect'),
('Bass boost effect', 'audio', 'Sound Effects', 'Deep bass on key words for impact'),
('Reverb echo', 'audio', 'Sound Effects', 'Echo effect on important phrases'),
('Notification sound', 'audio', 'Sound Effects', 'iPhone ding or message sound for attention'),
('Cash register ching', 'audio', 'Sound Effects', 'Money sound for financial content'),
('Suspense music', 'audio', 'Sound Effects', 'Tense background building anticipation'),
('Upbeat intro music', 'audio', 'Sound Effects', 'Energetic music setting positive tone'),
('Silence contrast', 'audio', 'Sound Effects', 'Sudden quiet after loud moment'),
('Voiceover duet', 'audio', 'Sound Effects', 'Speaking over another creator''s audio'),
('ASMR sounds', 'audio', 'Sound Effects', 'Tapping, scratching, crinkling sounds'),
('Distorted bass', 'audio', 'Sound Effects', 'Overdriven audio for emphasis'),
('Cartoon sound effects', 'audio', 'Sound Effects', 'Boing, splat, pop for humor'),
('Cinematic whoosh', 'audio', 'Sound Effects', 'Swoosh transitions between scenes');

-- Speech Patterns (15)
INSERT INTO techniques (name, type, category, description) VALUES
('Question hook', 'audio', 'Speech Patterns', 'Opening with a direct question to viewer'),
('Controversial statement', 'audio', 'Speech Patterns', 'Bold claim that triggers debate'),
('Number hook', 'audio', 'Speech Patterns', '"5 things you didn''t know..." format'),
('Challenge issued', 'audio', 'Speech Patterns', '"I bet you can''t..." or "prove me wrong"'),
('Secret reveal', 'audio', 'Speech Patterns', '"Nobody talks about this..." opener'),
('Story teaser', 'audio', 'Speech Patterns', '"So this happened..." narrative start'),
('Direct address', 'audio', 'Speech Patterns', '"YOU need to hear this" personal call'),
('Self-deprecating humor', 'audio', 'Speech Patterns', 'Making fun of yourself for relatability'),
('Hot take opener', 'audio', 'Speech Patterns', 'Unpopular opinion stated confidently'),
('Comparison hook', 'audio', 'Speech Patterns', '"X vs Y - which is better?"'),
('Before/after tease', 'audio', 'Speech Patterns', '"Wait till you see the end"'),
('Reaction prompt', 'audio', 'Speech Patterns', '"Comment if you agree" engagement bait'),
('Repetition emphasis', 'audio', 'Speech Patterns', 'Saying same phrase multiple times'),
('Incomplete sentence', 'audio', 'Speech Patterns', 'Trailing off to create curiosity'),
('Catchphrase opener', 'audio', 'Speech Patterns', 'Signature greeting or phrase');

-- =====================================================
-- INSERT VISUAL TECHNIQUES (52)
-- =====================================================

-- Camera Work (12)
INSERT INTO techniques (name, type, category, description) VALUES
('Extreme close-up', 'visual', 'Camera Work', 'Face filling entire frame for intensity'),
('Zoom out reveal', 'visual', 'Camera Work', 'Starting tight then revealing full scene'),
('Zoom in emphasis', 'visual', 'Camera Work', 'Punching in on key moment or object'),
('Shaky handheld', 'visual', 'Camera Work', 'Intentionally unstable for authenticity'),
('POV shot', 'visual', 'Camera Work', 'First-person perspective camera angle'),
('Low angle power shot', 'visual', 'Camera Work', 'Camera looking up at subject'),
('High angle vulnerability', 'visual', 'Camera Work', 'Camera looking down at subject'),
('Dutch angle', 'visual', 'Camera Work', 'Tilted frame for tension or unease'),
('Slow pan reveal', 'visual', 'Camera Work', 'Gradual horizontal movement to show scene'),
('Quick whip pan', 'visual', 'Camera Work', 'Fast camera movement between subjects'),
('Rack focus', 'visual', 'Camera Work', 'Shifting focus between foreground and background'),
('Mirror shot', 'visual', 'Camera Work', 'Filming reflection for creative framing');

-- Text & Graphics (12)
INSERT INTO techniques (name, type, category, description) VALUES
('Bold text overlay', 'visual', 'Text & Graphics', 'Large, attention-grabbing captions'),
('Word-by-word reveal', 'visual', 'Text & Graphics', 'Text appearing one word at a time'),
('Emoji explosion', 'visual', 'Text & Graphics', 'Multiple emojis appearing for emphasis'),
('Progress bar', 'visual', 'Text & Graphics', 'Visual tracker showing video timeline'),
('Arrow pointing', 'visual', 'Text & Graphics', 'Animated arrow directing attention'),
('Circle highlight', 'visual', 'Text & Graphics', 'Red circle around important detail'),
('Split screen comparison', 'visual', 'Text & Graphics', 'Side-by-side visual contrast'),
('Countdown timer', 'visual', 'Text & Graphics', 'On-screen numbers counting down'),
('Green screen background', 'visual', 'Text & Graphics', 'Custom or trending background replacement'),
('Meme format overlay', 'visual', 'Text & Graphics', 'Using recognizable meme templates'),
('Subtitles sync', 'visual', 'Text & Graphics', 'Perfectly timed text matching speech'),
('Glitch text effect', 'visual', 'Text & Graphics', 'Distorted, flickering text animation');

-- Subject Action (12)
INSERT INTO techniques (name, type, category, description) VALUES
('Product close-up', 'visual', 'Subject Action', 'Detailed shot of item being discussed'),
('Before/after transformation', 'visual', 'Subject Action', 'Visual contrast showing change'),
('Unboxing reveal', 'visual', 'Subject Action', 'Opening package on camera'),
('Get ready with me', 'visual', 'Subject Action', 'Routine demonstration format'),
('Taste test reaction', 'visual', 'Subject Action', 'Genuine response to trying something'),
('Point at camera', 'visual', 'Subject Action', 'Direct gesture toward viewer'),
('Hands demonstration', 'visual', 'Subject Action', 'Close-up of hands doing task'),
('Walking and talking', 'visual', 'Subject Action', 'Movement while delivering content'),
('Sitting confessional', 'visual', 'Subject Action', 'Static seated intimate delivery'),
('Cooking process', 'visual', 'Subject Action', 'Food preparation shown step by step'),
('Fitness demonstration', 'visual', 'Subject Action', 'Exercise or movement showcase'),
('Dance/trend participation', 'visual', 'Subject Action', 'Performing viral choreography');

-- Editing Techniques (10)
INSERT INTO techniques (name, type, category, description) VALUES
('Jump cut rhythm', 'visual', 'Editing', 'Rapid cuts removing pauses'),
('Speed ramp', 'visual', 'Editing', 'Alternating fast and slow motion'),
('Flash frame', 'visual', 'Editing', 'Brief white or color flash between cuts'),
('Freeze frame', 'visual', 'Editing', 'Pausing on key moment'),
('Rewind effect', 'visual', 'Editing', 'Playing footage backwards'),
('Picture-in-picture', 'visual', 'Editing', 'Small video overlay within main video'),
('Transition swipe', 'visual', 'Editing', 'Hand or object wipe between scenes'),
('Match cut', 'visual', 'Editing', 'Similar shapes/actions across cuts'),
('Loop seamless', 'visual', 'Editing', 'End matching beginning for infinite loop'),
('B-roll cutaway', 'visual', 'Editing', 'Supplementary footage over narration');

-- Scene & Setting (6)
INSERT INTO techniques (name, type, category, description) VALUES
('Car confessional', 'visual', 'Scene & Setting', 'Filming inside parked car'),
('Bathroom mirror', 'visual', 'Scene & Setting', 'Classic selfie location'),
('Kitchen setting', 'visual', 'Scene & Setting', 'Home kitchen as backdrop'),
('Outdoor natural light', 'visual', 'Scene & Setting', 'Outside with natural lighting'),
('Ring light face', 'visual', 'Scene & Setting', 'Professional front lighting setup'),
('Bed/cozy setting', 'visual', 'Scene & Setting', 'Intimate bedroom environment');

-- =====================================================
-- INSERT EMOTION TAGS (20)
-- =====================================================

-- Primary Emotions (8)
INSERT INTO techniques (name, type, category, description) VALUES
('Curiosity', 'emotion', 'Primary Emotions', '"Wait what?" intrigue that demands answers'),
('Shock', 'emotion', 'Primary Emotions', 'Genuine surprise or disbelief reaction'),
('Fear', 'emotion', 'Primary Emotions', 'Anxiety about missing out or danger'),
('Joy', 'emotion', 'Primary Emotions', 'Pure happiness and positive energy'),
('Anger', 'emotion', 'Primary Emotions', 'Frustration or outrage that resonates'),
('Sadness', 'emotion', 'Primary Emotions', 'Emotional vulnerability that connects'),
('Disgust', 'emotion', 'Primary Emotions', 'Repulsion that creates strong reaction'),
('Anticipation', 'emotion', 'Primary Emotions', 'Excitement about what comes next');

-- Social Emotions (7)
INSERT INTO techniques (name, type, category, description) VALUES
('FOMO', 'emotion', 'Social Emotions', 'Fear of missing out on trend or information'),
('Relatability', 'emotion', 'Social Emotions', '"This is so me" connection feeling'),
('Envy', 'emotion', 'Social Emotions', 'Wanting what someone else has'),
('Pride', 'emotion', 'Social Emotions', 'Achievement or accomplishment showcase'),
('Embarrassment', 'emotion', 'Social Emotions', 'Cringe or secondhand shame'),
('Belonging', 'emotion', 'Social Emotions', 'Community and inclusion feeling'),
('Nostalgia', 'emotion', 'Social Emotions', 'Longing for past memories');

-- Motivation Emotions (5)
INSERT INTO techniques (name, type, category, description) VALUES
('Inspiration', 'emotion', 'Motivation Emotions', 'Motivated to take action or improve'),
('Validation', 'emotion', 'Motivation Emotions', 'Feeling understood and seen'),
('Empowerment', 'emotion', 'Motivation Emotions', 'Feeling capable and strong'),
('Hope', 'emotion', 'Motivation Emotions', 'Optimism about future possibilities'),
('Determination', 'emotion', 'Motivation Emotions', 'Resolve to overcome challenges');
