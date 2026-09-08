-- Create niches table for storing content niche benchmarks
CREATE TABLE IF NOT EXISTS public.niches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category TEXT NOT NULL,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  avg_hook_score INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create index on slug for fast lookups during analysis
CREATE INDEX IF NOT EXISTS idx_niches_slug ON public.niches(slug);
CREATE INDEX IF NOT EXISTS idx_niches_category ON public.niches(category);

-- Enable RLS
ALTER TABLE public.niches ENABLE ROW LEVEL SECURITY;

-- Allow anyone to read niches (public benchmark data)
CREATE POLICY "Anyone can read niches" ON public.niches
  FOR SELECT USING (true);

-- Insert all niche data

-- Entertainment, Humor & Commentary
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Entertainment, Humor & Commentary', 'Meme remixes / trend formats', 'meme_remixes_trend_formats', 76),
('Entertainment, Humor & Commentary', 'Skits / character comedy', 'skits_character_comedy', 75),
('Entertainment, Humor & Commentary', 'Relatable POV comedy', 'relatable_pov_comedy', 77),
('Entertainment, Humor & Commentary', 'Reaction / duet commentary', 'reaction_duet_commentary', 74),
('Entertainment, Humor & Commentary', 'Drama commentary / internet culture', 'drama_commentary_internet_culture', 75),
('Entertainment, Humor & Commentary', 'Hot takes / opinion clips', 'hot_takes_opinion_clips', 73),
('Entertainment, Humor & Commentary', 'Celebrity / pop culture recap', 'celebrity_pop_culture_recap', 72),
('Entertainment, Humor & Commentary', 'Red-flag / green-flag discourse', 'red_flag_green_flag_discourse', 76);

-- Storytelling & Personal Narrative
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Storytelling & Personal Narrative', 'Storytime', 'storytime', 74),
('Storytelling & Personal Narrative', 'Confession / vulnerable storytelling', 'confession_vulnerable_storytelling', 76),
('Storytelling & Personal Narrative', 'Transformation story', 'transformation_story', 77),
('Storytelling & Personal Narrative', 'Before-vs-after narrative', 'before_vs_after_narrative', 75),
('Storytelling & Personal Narrative', 'Failure lesson / comeback story', 'failure_lesson_comeback_story', 73),
('Storytelling & Personal Narrative', 'Day in my life / mini vlog', 'day_in_my_life_mini_vlog', 66),
('Storytelling & Personal Narrative', 'Life update / personal recap', 'life_update_personal_recap', 67),
('Storytelling & Personal Narrative', 'Behind-the-scenes creator story', 'behind_the_scenes_creator_story', 69);

-- Lifestyle, Relationships & Social Identity
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Lifestyle, Relationships & Social Identity', 'Dating advice', 'dating_advice', 75),
('Lifestyle, Relationships & Social Identity', 'Relationship stories', 'relationship_stories', 74),
('Lifestyle, Relationships & Social Identity', 'Friendship / social dynamics', 'friendship_social_dynamics', 71),
('Lifestyle, Relationships & Social Identity', 'Family moments', 'family_moments', 68),
('Lifestyle, Relationships & Social Identity', 'Couples content', 'couples_content', 72),
('Lifestyle, Relationships & Social Identity', 'Routine / GRWM', 'routine_grwm', 70),
('Lifestyle, Relationships & Social Identity', 'Aesthetic lifestyle', 'aesthetic_lifestyle', 67),
('Lifestyle, Relationships & Social Identity', 'Luxury lifestyle', 'luxury_lifestyle', 69);

-- Beauty, Fashion & Personal Care
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Beauty, Fashion & Personal Care', 'Makeup tutorial', 'makeup_tutorial', 72),
('Beauty, Fashion & Personal Care', 'Makeup transformation', 'makeup_transformation', 76),
('Beauty, Fashion & Personal Care', 'Skincare advice', 'skincare_advice', 70),
('Beauty, Fashion & Personal Care', 'Hair tutorial / styling', 'hair_tutorial_styling', 71),
('Beauty, Fashion & Personal Care', 'Outfit ideas / styling', 'outfit_ideas_styling', 72),
('Beauty, Fashion & Personal Care', 'Fashion haul / try-on', 'fashion_haul_try_on', 74),
('Beauty, Fashion & Personal Care', 'Glow-up / makeover', 'glow_up_makeover', 77),
('Beauty, Fashion & Personal Care', 'Nails / beauty detail work', 'nails_beauty_detail_work', 69);

-- Fitness, Health & Wellness
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Fitness, Health & Wellness', 'Gym motivation edits', 'gym_motivation_edits', 66),
('Fitness, Health & Wellness', 'Workout tips / form corrections', 'workout_tips_form_corrections', 69),
('Fitness, Health & Wellness', 'Fat-loss story / body transformation', 'fat_loss_story_body_transformation', 75),
('Fitness, Health & Wellness', 'Beginner fitness advice', 'beginner_fitness_advice', 70),
('Fitness, Health & Wellness', 'Nutrition tips / meal guidance', 'nutrition_tips_meal_guidance', 68),
('Fitness, Health & Wellness', 'Supplements / wellness products', 'supplements_wellness_products', 66),
('Fitness, Health & Wellness', 'Mental health / self-regulation tips', 'mental_health_self_regulation_tips', 72),
('Fitness, Health & Wellness', 'Habit-building / discipline content', 'habit_building_discipline_content', 71);

-- Food, Cooking & Beverage
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Food, Cooking & Beverage', 'Fast recipe demo', 'fast_recipe_demo', 74),
('Food, Cooking & Beverage', 'Slow recipe / chef process', 'slow_recipe_chef_process', 69),
('Food, Cooking & Beverage', 'Street food / food hunt', 'street_food_food_hunt', 75),
('Food, Cooking & Beverage', 'Food review / taste test', 'food_review_taste_test', 73),
('Food, Cooking & Beverage', 'Cooking tips / kitchen hacks', 'cooking_tips_kitchen_hacks', 71),
('Food, Cooking & Beverage', 'Meal prep', 'meal_prep', 68),
('Food, Cooking & Beverage', 'Baking / dessert reveal', 'baking_dessert_reveal', 74),
('Food, Cooking & Beverage', 'Coffee / drinks / barista content', 'coffee_drinks_barista_content', 70);

-- Education, Knowledge & Self-Improvement
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Education, Knowledge & Self-Improvement', 'Study tips', 'study_tips', 69),
('Education, Knowledge & Self-Improvement', 'Productivity systems', 'productivity_systems', 70),
('Education, Knowledge & Self-Improvement', 'Psychology explainers', 'psychology_explainers', 72),
('Education, Knowledge & Self-Improvement', 'Self-improvement advice', 'self_improvement_advice', 71),
('Education, Knowledge & Self-Improvement', 'History facts / mini lessons', 'history_facts_mini_lessons', 70),
('Education, Knowledge & Self-Improvement', 'Science explainers', 'science_explainers', 71),
('Education, Knowledge & Self-Improvement', 'Language learning', 'language_learning', 69),
('Education, Knowledge & Self-Improvement', 'Book summaries / BookTok', 'book_summaries_booktok', 72);

-- Business, Money & Career
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Business, Money & Career', 'Make money online', 'make_money_online', 76),
('Business, Money & Career', 'Side hustles', 'side_hustles', 74),
('Business, Money & Career', 'Entrepreneurship lessons', 'entrepreneurship_lessons', 72),
('Business, Money & Career', 'Startup / founder journey', 'startup_founder_journey', 71),
('Business, Money & Career', 'Sales / persuasion tips', 'sales_persuasion_tips', 73),
('Business, Money & Career', 'Personal finance basics', 'personal_finance_basics', 72),
('Business, Money & Career', 'Investing / markets', 'investing_markets', 70),
('Business, Money & Career', 'Career advice / workplace tips', 'career_advice_workplace_tips', 71);

-- Tech, AI & Digital Tools
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Tech, AI & Digital Tools', 'AI tool demos', 'ai_tool_demos', 75),
('Tech, AI & Digital Tools', 'App / software tutorial', 'app_software_tutorial', 71),
('Tech, AI & Digital Tools', 'Tech review', 'tech_review', 70),
('Tech, AI & Digital Tools', 'Gadget demo / unboxing', 'gadget_demo_unboxing', 72),
('Tech, AI & Digital Tools', 'Coding tips', 'coding_tips', 68),
('Tech, AI & Digital Tools', 'Automation / no-code workflows', 'automation_no_code_workflows', 73),
('Tech, AI & Digital Tools', 'Cybersecurity tips', 'cybersecurity_tips', 70),
('Tech, AI & Digital Tools', 'Creator tools / editing apps', 'creator_tools_editing_apps', 72);

-- Gaming
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Gaming', 'Raw gameplay highlights', 'raw_gameplay_highlights', 64),
('Gaming', 'Funny gaming moments', 'funny_gaming_moments', 71),
('Gaming', 'Competitive / clutch plays', 'competitive_clutch_plays', 68),
('Gaming', 'Gaming tips / strategy', 'gaming_tips_strategy', 67),
('Gaming', 'Game lore / news', 'game_lore_news', 69),
('Gaming', 'Horror game reactions', 'horror_game_reactions', 73),
('Gaming', 'Minecraft / sandbox creativity', 'minecraft_sandbox_creativity', 68),
('Gaming', 'Streamer clip edits', 'streamer_clip_edits', 70);

-- Travel, Outdoor & Place-Based
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Travel, Outdoor & Place-Based', 'Travel mini vlog', 'travel_mini_vlog', 70),
('Travel, Outdoor & Place-Based', 'Travel hacks / budget tips', 'travel_hacks_budget_tips', 72),
('Travel, Outdoor & Place-Based', 'Hidden places / recommendations', 'hidden_places_recommendations', 73),
('Travel, Outdoor & Place-Based', 'Scenic cinematic travel', 'scenic_cinematic_travel', 68),
('Travel, Outdoor & Place-Based', 'Van life / nomad life', 'van_life_nomad_life', 70),
('Travel, Outdoor & Place-Based', 'Camping / hiking / outdoor skills', 'camping_hiking_outdoor_skills', 69),
('Travel, Outdoor & Place-Based', 'City guides / local recs', 'city_guides_local_recs', 71),
('Travel, Outdoor & Place-Based', 'Adventure sports', 'adventure_sports', 72);

-- Home, DIY, Real Estate & Organization
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Home, DIY, Real Estate & Organization', 'Home organization', 'home_organization', 73),
('Home, DIY, Real Estate & Organization', 'Cleaning motivation', 'cleaning_motivation', 72),
('Home, DIY, Real Estate & Organization', 'DIY / craft hacks', 'diy_craft_hacks', 71),
('Home, DIY, Real Estate & Organization', 'Interior styling', 'interior_styling', 69),
('Home, DIY, Real Estate & Organization', 'Room makeover', 'room_makeover', 75),
('Home, DIY, Real Estate & Organization', 'Real estate tours', 'real_estate_tours', 71),
('Home, DIY, Real Estate & Organization', 'Home buying / renting advice', 'home_buying_renting_advice', 68),
('Home, DIY, Real Estate & Organization', 'Gardening', 'gardening', 67);

-- Cars, Motorsports & Machines
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Cars, Motorsports & Machines', 'Car spotting / edits', 'car_spotting_edits', 69),
('Cars, Motorsports & Machines', 'Car review', 'car_review', 70),
('Cars, Motorsports & Machines', 'Car transformations', 'car_transformations', 74),
('Cars, Motorsports & Machines', 'Detailing / cleaning', 'detailing_cleaning', 72),
('Cars, Motorsports & Machines', 'Mechanic / repair tips', 'mechanic_repair_tips', 69),
('Cars, Motorsports & Machines', 'Motorcycle content', 'motorcycle_content', 71),
('Cars, Motorsports & Machines', 'Motorsport highlights', 'motorsport_highlights', 73),
('Cars, Motorsports & Machines', 'Trucks / off-road rigs', 'trucks_off_road_rigs', 68);

-- Music, Dance & Performance
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Music, Dance & Performance', 'Dance trend participation', 'dance_trend_participation', 78),
('Music, Dance & Performance', 'Choreography showcase', 'choreography_showcase', 74),
('Music, Dance & Performance', 'Singing covers', 'singing_covers', 70),
('Music, Dance & Performance', 'Instrument performance', 'instrument_performance', 69),
('Music, Dance & Performance', 'Mashups / remixes', 'mashups_remixes', 73),
('Music, Dance & Performance', 'Freestyle / rap performance', 'freestyle_rap_performance', 71),
('Music, Dance & Performance', 'Concert / live performance clips', 'concert_live_performance_clips', 70),
('Music, Dance & Performance', 'Music education', 'music_education', 67);

-- Art, Design & Creative Process
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Art, Design & Creative Process', 'Digital art timelapse', 'digital_art_timelapse', 72),
('Art, Design & Creative Process', 'Traditional art process', 'traditional_art_process', 70),
('Art, Design & Creative Process', 'Graphic design tips', 'graphic_design_tips', 69),
('Art, Design & Creative Process', 'Logo / branding critique', 'logo_branding_critique', 71),
('Art, Design & Creative Process', 'Photography tips', 'photography_tips', 70),
('Art, Design & Creative Process', 'Photo / video editing tutorials', 'photo_video_editing_tutorials', 72),
('Art, Design & Creative Process', 'Crafting / handmade builds', 'crafting_handmade_builds', 69),
('Art, Design & Creative Process', 'Animation / motion design', 'animation_motion_design', 71);

-- Parenting, Kids & Family Life
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Parenting, Kids & Family Life', 'Parenting tips', 'parenting_tips', 69),
('Parenting, Kids & Family Life', 'Funny kid moments', 'funny_kid_moments', 74),
('Parenting, Kids & Family Life', 'Newborn / baby routines', 'newborn_baby_routines', 68),
('Parenting, Kids & Family Life', 'Mom hacks / dad hacks', 'mom_hacks_dad_hacks', 71),
('Parenting, Kids & Family Life', 'Family routines', 'family_routines', 67),
('Parenting, Kids & Family Life', 'Pregnancy journey', 'pregnancy_journey', 72);

-- Pets & Animals
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Pets & Animals', 'Cute pet clips', 'cute_pet_clips', 76),
('Pets & Animals', 'Funny pet behavior', 'funny_pet_behavior', 77),
('Pets & Animals', 'Pet training tips', 'pet_training_tips', 70),
('Pets & Animals', 'Pet care advice', 'pet_care_advice', 68),
('Pets & Animals', 'Animal facts / wildlife', 'animal_facts_wildlife', 71),
('Pets & Animals', 'Rescue / adoption stories', 'rescue_adoption_stories', 75);

-- Sports & Physical Skill
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('Sports & Physical Skill', 'Basketball highlights', 'basketball_highlights', 72),
('Sports & Physical Skill', 'Football / soccer highlights', 'football_soccer_highlights', 73),
('Sports & Physical Skill', 'Combat sports / martial arts', 'combat_sports_martial_arts', 74),
('Sports & Physical Skill', 'Skill tutorials / drills', 'skill_tutorials_drills', 69),
('Sports & Physical Skill', 'Fishing / hunting / outdoorsman', 'fishing_hunting_outdoorsman', 68),
('Sports & Physical Skill', 'Extreme stunts / trick shots', 'extreme_stunts_trick_shots', 77);

-- ASMR, Satisfying & Sensory
INSERT INTO public.niches (category, name, slug, avg_hook_score) VALUES
('ASMR, Satisfying & Sensory', 'ASMR whisper / triggers', 'asmr_whisper_triggers', 72),
('ASMR, Satisfying & Sensory', 'Satisfying process videos', 'satisfying_process_videos', 78),
('ASMR, Satisfying & Sensory', 'Restoration / cleaning reveals', 'restoration_cleaning_reveals', 76),
('ASMR, Satisfying & Sensory', 'Oddly satisfying cutting / crushing', 'oddly_satisfying_cutting_crushing', 77),
('ASMR, Satisfying & Sensory', 'Soap / slime / texture content', 'soap_slime_texture_content', 74),
('ASMR, Satisfying & Sensory', 'Calming / ambience loops', 'calming_ambience_loops', 68);
