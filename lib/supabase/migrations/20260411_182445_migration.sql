-- Add 68 new niches to expand coverage

INSERT INTO niches (category, name, slug, avg_hook_score) VALUES

-- Sports & Physical Skill (15 new)
('Sports & Physical Skill', 'Swimming / aquatics', 'swimming_aquatics', 74),
('Sports & Physical Skill', 'Golf tips / highlights', 'golf_tips_highlights', 72),
('Sports & Physical Skill', 'Tennis highlights', 'tennis_highlights', 73),
('Sports & Physical Skill', 'Running / marathon training', 'running_marathon_training', 71),
('Sports & Physical Skill', 'Skateboarding / BMX', 'skateboarding_bmx', 78),
('Sports & Physical Skill', 'Surfing / water sports', 'surfing_water_sports', 77),
('Sports & Physical Skill', 'Rock climbing / bouldering', 'rock_climbing_bouldering', 75),
('Sports & Physical Skill', 'Boxing / MMA training', 'boxing_mma_training', 76),
('Sports & Physical Skill', 'Gymnastics / acrobatics', 'gymnastics_acrobatics', 79),
('Sports & Physical Skill', 'Cycling / bike culture', 'cycling_bike_culture', 72),
('Sports & Physical Skill', 'Winter sports (skiing/snowboarding)', 'winter_sports', 76),
('Sports & Physical Skill', 'Wrestling', 'wrestling', 74),
('Sports & Physical Skill', 'Track and field', 'track_and_field', 71),
('Sports & Physical Skill', 'Volleyball', 'volleyball', 73),
('Sports & Physical Skill', 'Hockey highlights', 'hockey_highlights', 75),

-- Music, Dance & Performance (6 new)
('Music, Dance & Performance', 'DJ / turntablism', 'dj_turntablism', 76),
('Music, Dance & Performance', 'Beat making / production', 'beat_making_production', 74),
('Music, Dance & Performance', 'Singing covers', 'singing_covers', 77),
('Music, Dance & Performance', 'Beatboxing', 'beatboxing', 79),
('Music, Dance & Performance', 'Music reaction / review', 'music_reaction_review', 75),
('Music, Dance & Performance', 'Festival / rave content', 'festival_rave_content', 78),

-- Entertainment, Humor & Commentary (5 new)
('Entertainment, Humor & Commentary', 'Celebrity gossip / news', 'celebrity_gossip_news', 76),
('Entertainment, Humor & Commentary', 'Movie / TV reviews', 'movie_tv_reviews', 74),
('Entertainment, Humor & Commentary', 'Anime / manga discussion', 'anime_manga_discussion', 75),
('Entertainment, Humor & Commentary', 'Podcast clips', 'podcast_clips', 73),
('Entertainment, Humor & Commentary', 'Stand-up comedy clips', 'standup_comedy_clips', 78),

-- Travel & Adventure (6 new)
('Travel & Adventure', 'Hidden gems / secret spots', 'hidden_gems_secret_spots', 77),
('Travel & Adventure', 'Hotel / resort reviews', 'hotel_resort_reviews', 74),
('Travel & Adventure', 'Flight / airport tips', 'flight_airport_tips', 72),
('Travel & Adventure', 'Road trip content', 'road_trip_content', 75),
('Travel & Adventure', 'Digital nomad lifestyle', 'digital_nomad_lifestyle', 74),
('Travel & Adventure', 'Backpacking adventures', 'backpacking_adventures', 76),

-- Pets & Animals (6 new)
('Pets & Animals', 'Exotic pets', 'exotic_pets', 77),
('Pets & Animals', 'Pet grooming', 'pet_grooming', 73),
('Pets & Animals', 'Animal rescue stories', 'animal_rescue_stories', 79),
('Pets & Animals', 'Wildlife photography', 'wildlife_photography', 75),
('Pets & Animals', 'Aquarium / fish keeping', 'aquarium_fish_keeping', 72),
('Pets & Animals', 'Horseback riding / equestrian', 'horseback_riding_equestrian', 74),

-- Parenting & Family (6 new)
('Parenting & Family', 'Pregnancy journey', 'pregnancy_journey', 74),
('Parenting & Family', 'Baby milestones', 'baby_milestones', 76),
('Parenting & Family', 'Homeschooling tips', 'homeschooling_tips', 71),
('Parenting & Family', 'Teen parenting', 'teen_parenting', 72),
('Parenting & Family', 'Single parent life', 'single_parent_life', 73),
('Parenting & Family', 'Family traditions / activities', 'family_traditions_activities', 75),

-- Technology & Gadgets (6 new)
('Technology & Gadgets', 'Smartphone reviews', 'smartphone_reviews', 74),
('Technology & Gadgets', 'PC building / setup', 'pc_building_setup', 76),
('Technology & Gadgets', 'Smart home tech', 'smart_home_tech', 73),
('Technology & Gadgets', 'Drone content', 'drone_content', 77),
('Technology & Gadgets', 'VR / AR experiences', 'vr_ar_experiences', 75),
('Technology & Gadgets', 'Coding / programming tutorials', 'coding_programming_tutorials', 72),

-- ASMR, Satisfying & Sensory (5 new)
('ASMR, Satisfying & Sensory', 'Soap cutting', 'soap_cutting', 76),
('ASMR, Satisfying & Sensory', 'Kinetic sand', 'kinetic_sand', 77),
('ASMR, Satisfying & Sensory', 'Power washing', 'power_washing', 79),
('ASMR, Satisfying & Sensory', 'Calligraphy / handwriting', 'calligraphy_handwriting', 74),
('ASMR, Satisfying & Sensory', 'Pottery / clay work', 'pottery_clay_work', 75),

-- Outdoor & Nature (8 new - NEW CATEGORY)
('Outdoor & Nature', 'Camping / bushcraft', 'camping_bushcraft', 75),
('Outdoor & Nature', 'Hiking trails', 'hiking_trails', 74),
('Outdoor & Nature', 'Fishing', 'fishing', 73),
('Outdoor & Nature', 'Hunting', 'hunting', 72),
('Outdoor & Nature', 'Bird watching', 'bird_watching', 71),
('Outdoor & Nature', 'Foraging / wild plants', 'foraging_wild_plants', 74),
('Outdoor & Nature', 'Off-grid living', 'off_grid_living', 76),
('Outdoor & Nature', 'Astronomy / stargazing', 'astronomy_stargazing', 73),

-- Relationships & Dating (5 new - NEW CATEGORY)
('Relationships & Dating', 'Dating advice', 'dating_advice', 76),
('Relationships & Dating', 'Couple challenges / pranks', 'couple_challenges_pranks', 79),
('Relationships & Dating', 'Long-distance relationship', 'long_distance_relationship', 73),
('Relationships & Dating', 'Marriage / relationship tips', 'marriage_relationship_tips', 72),
('Relationships & Dating', 'Breakup / healing content', 'breakup_healing_content', 74);
