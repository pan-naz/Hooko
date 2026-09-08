-- Add engagement columns to niches table
ALTER TABLE niches ADD COLUMN IF NOT EXISTS tiktok_engagement DECIMAL(4,2);
ALTER TABLE niches ADD COLUMN IF NOT EXISTS instagram_engagement DECIMAL(4,2);
ALTER TABLE niches ADD COLUMN IF NOT EXISTS youtube_engagement DECIMAL(4,2);
ALTER TABLE niches ADD COLUMN IF NOT EXISTS avg_engagement DECIMAL(4,2);

-- Update all niches with realistic engagement values
-- Formula: avg_engagement = (avg_hook_score - 50) / 10
-- TikTok is typically higher, YouTube is typically lower

-- Score 79 niches (avg_engagement = 2.9)
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.9, youtube_engagement = 2.2, avg_engagement = 2.9 WHERE slug = 'power_washing';
UPDATE niches SET tiktok_engagement = 3.8, instagram_engagement = 2.8, youtube_engagement = 2.1, avg_engagement = 2.9 WHERE slug = 'beatboxing';
UPDATE niches SET tiktok_engagement = 3.7, instagram_engagement = 2.9, youtube_engagement = 2.1, avg_engagement = 2.9 WHERE slug = 'animal_rescue_stories';
UPDATE niches SET tiktok_engagement = 3.9, instagram_engagement = 2.7, youtube_engagement = 2.1, avg_engagement = 2.9 WHERE slug = 'gymnastics_acrobatics';

-- Score 78 niches (avg_engagement = 2.8)
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.7, youtube_engagement = 2.1, avg_engagement = 2.8 WHERE slug = 'skateboarding_bmx';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.8, youtube_engagement = 2.1, avg_engagement = 2.8 WHERE slug = 'standup_comedy_clips';
UPDATE niches SET tiktok_engagement = 3.7, instagram_engagement = 2.7, youtube_engagement = 2.0, avg_engagement = 2.8 WHERE slug = 'festival_rave_content';
UPDATE niches SET tiktok_engagement = 3.8, instagram_engagement = 2.6, youtube_engagement = 2.0, avg_engagement = 2.8 WHERE slug = 'dance_trend_participation';
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.8, youtube_engagement = 2.0, avg_engagement = 2.8 WHERE slug = 'satisfying_process_videos';

-- Score 77 niches (avg_engagement = 2.7)
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.6, youtube_engagement = 2.0, avg_engagement = 2.7 WHERE slug = 'extreme_stunts_trick_shots';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.7, youtube_engagement = 2.0, avg_engagement = 2.7 WHERE slug = 'hidden_gems_secret_spots';
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'surfing_water_sports';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.7, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'kinetic_sand';
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'funny_pet_behavior';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.8, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'exotic_pets';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.7, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'relatable_pov_comedy';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.7, youtube_engagement = 2.0, avg_engagement = 2.7 WHERE slug = 'drone_content';
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'glow_up_makeover';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.7, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'transformation_story';
UPDATE niches SET tiktok_engagement = 3.6, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.7 WHERE slug = 'oddly_satisfying_cutting_crushing';

-- Score 76 niches (avg_engagement = 2.6)
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.6 WHERE slug = 'off_grid_living';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.5, youtube_engagement = 1.9, avg_engagement = 2.6 WHERE slug = 'make_money_online';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'backpacking_adventures';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'red_flag_green_flag_discourse';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'restoration_cleaning_reveals';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.7, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'confession_vulnerable_storytelling';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'baby_milestones';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.6, youtube_engagement = 1.9, avg_engagement = 2.6 WHERE slug = 'winter_sports';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'meme_remixes_trend_formats';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'dj_turntablism';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'makeup_transformation';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'cute_pet_clips';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.7, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'boxing_mma_training';
UPDATE niches SET tiktok_engagement = 3.5, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'soap_cutting';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.6 WHERE slug = 'celebrity_gossip_news';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.7, youtube_engagement = 1.9, avg_engagement = 2.6 WHERE slug = 'pc_building_setup';

-- Score 75 niches (avg_engagement = 2.5)
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.5 WHERE slug = 'music_reaction_review';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'rescue_adoption_stories';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.6, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'road_trip_content';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'hockey_highlights';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'dating_advice';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'skits_character_comedy';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.6, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'street_food_food_hunt';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'before_vs_after_narrative';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'drama_commentary_internet_culture';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.6, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'anime_manga_discussion';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.5 WHERE slug = 'rock_climbing_bouldering';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.5 WHERE slug = 'vr_ar_experiences';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.6, youtube_engagement = 1.8, avg_engagement = 2.5 WHERE slug = 'wildlife_photography';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'ai_tool_demos';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'family_traditions_activities';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.5, youtube_engagement = 1.8, avg_engagement = 2.5 WHERE slug = 'camping_bushcraft';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.6, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'pottery_clay_work';
UPDATE niches SET tiktok_engagement = 3.4, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'fat_loss_story_body_transformation';
UPDATE niches SET tiktok_engagement = 3.3, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.5 WHERE slug = 'room_makeover';

-- Score 74 niches (avg_engagement = 2.4)
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'beat_making_production';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.3, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'combat_sports_martial_arts';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'soap_slime_texture_content';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'swimming_aquatics';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'foraging_wild_plants';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'fashion_haul_try_on';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'hiking_trails';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.5, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'calligraphy_handwriting';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'reaction_duet_commentary';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'fast_recipe_demo';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.5, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'baking_dessert_reveal';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'smartphone_reviews';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'side_hustles';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'storytime';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'horseback_riding_equestrian';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'digital_nomad_lifestyle';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.5, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'hotel_resort_reviews';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'breakup_healing_content';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'car_transformations';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.5, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'movie_tv_reviews';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'choreography_showcase';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.4, youtube_engagement = 1.7, avg_engagement = 2.4 WHERE slug = 'wrestling';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'relationship_stories';
UPDATE niches SET tiktok_engagement = 3.2, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.4 WHERE slug = 'funny_kid_moments';

-- Score 73 niches (avg_engagement = 2.3)
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'astronomy_stargazing';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'hidden_places_recommendations';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'football_soccer_highlights';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.4, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'home_organization';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'failure_lesson_comeback_story';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'hot_takes_opinion_clips';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'tennis_highlights';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'smart_home_tech';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'podcast_clips';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'motorsport_highlights';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.4, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'food_review_taste_test';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'fishing';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'mashups_remixes';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.4, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'long_distance_relationship';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'sales_persuasion_tips';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'volleyball';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.4, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'automation_no_code_workflows';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.4, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'single_parent_life';
UPDATE niches SET tiktok_engagement = 3.1, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.3 WHERE slug = 'horror_game_reactions';
UPDATE niches SET tiktok_engagement = 3.0, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.3 WHERE slug = 'pet_grooming';

-- Score 72 niches (avg_engagement = 2.2)
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'detailing_cleaning';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'cycling_bike_culture';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'marriage_relationship_tips';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'aquarium_fish_keeping';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'personal_finance_basics';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'mental_health_self_regulation_tips';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.3, youtube_engagement = 1.4, avg_engagement = 2.2 WHERE slug = 'asmr_whisper_triggers';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.3, youtube_engagement = 1.4, avg_engagement = 2.2 WHERE slug = 'outfit_ideas_styling';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'teen_parenting';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'entrepreneurship_lessons';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'travel_hacks_budget_tips';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'creator_tools_editing_apps';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'photo_video_editing_tutorials';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'book_summaries_booktok';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'flight_airport_tips';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'celebrity_pop_culture_recap';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'adventure_sports';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.3, youtube_engagement = 1.4, avg_engagement = 2.2 WHERE slug = 'makeup_tutorial';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'cleaning_motivation';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'hunting';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'pregnancy_journey';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'digital_art_timelapse';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'couples_content';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'psychology_explainers';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.3, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'gadget_demo_unboxing';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'golf_tips_highlights';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.3, youtube_engagement = 1.6, avg_engagement = 2.2 WHERE slug = 'coding_programming_tutorials';
UPDATE niches SET tiktok_engagement = 2.9, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.2 WHERE slug = 'basketball_highlights';

-- Score 71 niches (avg_engagement = 2.1)
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'animal_facts_wildlife';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'friendship_social_dynamics';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.2, youtube_engagement = 1.3, avg_engagement = 2.1 WHERE slug = 'hair_tutorial_styling';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'habit_building_discipline_content';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'cooking_tips_kitchen_hacks';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'self_improvement_advice';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'science_explainers';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.1, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'startup_founder_journey';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.1, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'career_advice_workplace_tips';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'app_software_tutorial';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'funny_gaming_moments';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'city_guides_local_recs';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'diy_craft_hacks';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'real_estate_tours';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'motorcycle_content';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'freestyle_rap_performance';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'logo_branding_critique';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'animation_motion_design';
UPDATE niches SET tiktok_engagement = 2.8, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'mom_hacks_dad_hacks';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'running_marathon_training';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.2, youtube_engagement = 1.4, avg_engagement = 2.1 WHERE slug = 'track_and_field';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.1, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'homeschooling_tips';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.2, youtube_engagement = 1.5, avg_engagement = 2.1 WHERE slug = 'bird_watching';

-- Score 70 niches (avg_engagement = 2.0)
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.0, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'productivity_systems';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'history_facts_mini_lessons';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'pet_training_tips';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.1, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'traditional_art_process';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.0, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'van_life_nomad_life';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'investing_markets';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.1, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'travel_mini_vlog';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'streamer_clip_edits';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'tech_review';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.0, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'beginner_fitness_advice';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'cybersecurity_tips';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'concert_live_performance_clips';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.1, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'routine_grwm';
UPDATE niches SET tiktok_engagement = 2.7, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'singing_covers';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.1, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'coffee_drinks_barista_content';
UPDATE niches SET tiktok_engagement = 2.6, instagram_engagement = 2.1, youtube_engagement = 1.3, avg_engagement = 2.0 WHERE slug = 'skincare_advice';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'car_review';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.1, youtube_engagement = 1.4, avg_engagement = 2.0 WHERE slug = 'photography_tips';

-- Score 69 niches (avg_engagement = 1.9)
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'skill_tutorials_drills';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.0, youtube_engagement = 1.2, avg_engagement = 1.9 WHERE slug = 'parenting_tips';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.0, youtube_engagement = 1.2, avg_engagement = 1.9 WHERE slug = 'crafting_handmade_builds';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'behind_the_scenes_creator_story';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'graphic_design_tips';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.0, youtube_engagement = 1.2, avg_engagement = 1.9 WHERE slug = 'instrument_performance';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'mechanic_repair_tips';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'car_spotting_edits';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.0, youtube_engagement = 1.2, avg_engagement = 1.9 WHERE slug = 'interior_styling';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'camping_hiking_outdoor_skills';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'game_lore_news';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'language_learning';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'study_tips';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'slow_recipe_chef_process';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'workout_tips_form_corrections';
UPDATE niches SET tiktok_engagement = 2.5, instagram_engagement = 2.0, youtube_engagement = 1.2, avg_engagement = 1.9 WHERE slug = 'nails_beauty_detail_work';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 2.0, youtube_engagement = 1.3, avg_engagement = 1.9 WHERE slug = 'luxury_lifestyle';

-- Score 68 niches (avg_engagement = 1.8)
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 1.8, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'minecraft_sandbox_creativity';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'meal_prep';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 1.9, youtube_engagement = 1.1, avg_engagement = 1.8 WHERE slug = 'calming_ambience_loops';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'nutrition_tips_meal_guidance';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 1.8, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'family_moments';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'fishing_hunting_outdoorsman';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 1.8, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'newborn_baby_routines';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'pet_care_advice';
UPDATE niches SET tiktok_engagement = 2.4, instagram_engagement = 1.8, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'competitive_clutch_plays';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'coding_tips';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'scenic_cinematic_travel';
UPDATE niches SET tiktok_engagement = 2.2, instagram_engagement = 1.9, youtube_engagement = 1.3, avg_engagement = 1.8 WHERE slug = 'home_buying_renting_advice';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.9, youtube_engagement = 1.2, avg_engagement = 1.8 WHERE slug = 'trucks_off_road_rigs';

-- Score 67 niches (avg_engagement = 1.7)
UPDATE niches SET tiktok_engagement = 2.2, instagram_engagement = 1.8, youtube_engagement = 1.1, avg_engagement = 1.7 WHERE slug = 'music_education';
UPDATE niches SET tiktok_engagement = 2.2, instagram_engagement = 1.7, youtube_engagement = 1.2, avg_engagement = 1.7 WHERE slug = 'family_routines';
UPDATE niches SET tiktok_engagement = 2.3, instagram_engagement = 1.7, youtube_engagement = 1.1, avg_engagement = 1.7 WHERE slug = 'life_update_personal_recap';
UPDATE niches SET tiktok_engagement = 2.2, instagram_engagement = 1.8, youtube_engagement = 1.1, avg_engagement = 1.7 WHERE slug = 'gaming_tips_strategy';
UPDATE niches SET tiktok_engagement = 2.2, instagram_engagement = 1.8, youtube_engagement = 1.1, avg_engagement = 1.7 WHERE slug = 'aesthetic_lifestyle';
UPDATE niches SET tiktok_engagement = 2.1, instagram_engagement = 1.8, youtube_engagement = 1.2, avg_engagement = 1.7 WHERE slug = 'gardening';

-- Score 66 niches (avg_engagement = 1.6)
UPDATE niches SET tiktok_engagement = 2.1, instagram_engagement = 1.7, youtube_engagement = 1.0, avg_engagement = 1.6 WHERE slug = 'day_in_my_life_mini_vlog';
UPDATE niches SET tiktok_engagement = 2.0, instagram_engagement = 1.7, youtube_engagement = 1.1, avg_engagement = 1.6 WHERE slug = 'supplements_wellness_products';
UPDATE niches SET tiktok_engagement = 2.1, instagram_engagement = 1.6, youtube_engagement = 1.1, avg_engagement = 1.6 WHERE slug = 'gym_motivation_edits';

-- Score 64 niches (avg_engagement = 1.4)
UPDATE niches SET tiktok_engagement = 1.9, instagram_engagement = 1.4, youtube_engagement = 0.9, avg_engagement = 1.4 WHERE slug = 'raw_gameplay_highlights';
