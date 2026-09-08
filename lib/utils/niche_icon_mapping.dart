import 'package:flutter/material.dart';

/// Utility class for mapping niche names and categories to appropriate icons.
/// Uses pattern matching with ordered lists for priority-based icon resolution.
class NicheIconMapping {
  NicheIconMapping._();

  /// Returns the appropriate icon for a niche based on its name and category.
  static IconData getIcon(String? nicheName, String? category) {
    if (nicheName == null && category == null) return Icons.category;

    final name = (nicheName ?? '').toLowerCase();

    // Try name-based matching first
    for (final entry in _nichePatterns) {
      for (final pattern in entry.patterns) {
        if (name.contains(pattern)) return entry.icon;
      }
    }

    // Fallback to category-based matching
    final cat = (category ?? '').toLowerCase();
    for (final entry in _categoryPatterns) {
      for (final pattern in entry.patterns) {
        if (cat.contains(pattern)) return entry.icon;
      }
    }

    return Icons.category;
  }

  /// Niche name patterns ordered by specificity
  static final List<_IconPattern> _nichePatterns = [
    // Tattoo
    _IconPattern(['tattoo', 'ink'], Icons.brush),

    // Fishing & Hunting
    _IconPattern(['fish'], Icons.phishing),
    _IconPattern(['hunt'], Icons.gps_fixed),

    // Outdoor & Nature
    _IconPattern(['hiking', 'trail'], Icons.terrain),
    _IconPattern(['camping', 'bushcraft'], Icons.cabin),
    _IconPattern(['backpack'], Icons.backpack),
    _IconPattern(['garden'], Icons.yard),
    _IconPattern(['bird'], Icons.flutter_dash),
    _IconPattern(['wildlife', 'animal fact'], Icons.forest),
    _IconPattern(['forag', 'wild plant'], Icons.eco),
    _IconPattern(['off-grid'], Icons.nature_people),
    _IconPattern(['stargazing', 'astronomy'], Icons.nightlight),

    // Travel
    _IconPattern(['flight', 'airport'], Icons.flight),
    _IconPattern(['road trip'], Icons.directions_car),
    _IconPattern(['hotel', 'resort'], Icons.hotel),
    _IconPattern(['city guide', 'hidden gem', 'hidden place', 'secret spot'], Icons.explore),
    _IconPattern(['travel', 'scenic'], Icons.luggage),
    _IconPattern(['van life', 'nomad'], Icons.airport_shuttle),
    _IconPattern(['digital nomad'], Icons.laptop_mac),

    // Gaming
    _IconPattern(['competitive', 'clutch'], Icons.sports_esports), // Before 'pet' to avoid "competitive" matching "pet"
    _IconPattern(['gaming', 'game'], Icons.sports_esports),
    _IconPattern(['minecraft', 'sandbox'], Icons.grid_view),
    _IconPattern(['vr', 'ar experience'], Icons.view_in_ar),
    _IconPattern(['pc build', 'setup'], Icons.computer),
    _IconPattern(['streamer'], Icons.live_tv),

    // Sports
    _IconPattern(['basketball'], Icons.sports_basketball),
    _IconPattern(['football', 'soccer'], Icons.sports_soccer),
    _IconPattern(['boxing', 'mma', 'martial art', 'combat', 'wrestling'], Icons.sports_mma),
    _IconPattern(['golf'], Icons.sports_golf),
    _IconPattern(['tennis'], Icons.sports_tennis),
    _IconPattern(['hockey'], Icons.sports_hockey),
    _IconPattern(['volleyball'], Icons.sports_volleyball),
    _IconPattern(['gymnast', 'acrobat'], Icons.sports_gymnastics),
    _IconPattern(['running', 'marathon', 'track and field'], Icons.directions_run),
    _IconPattern(['cycling', 'bike'], Icons.directions_bike),
    _IconPattern(['skateboard', 'bmx'], Icons.skateboarding),
    _IconPattern(['rock climb', 'boulder'], Icons.landscape),
    _IconPattern(['surf', 'water sport'], Icons.surfing),
    _IconPattern(['swim', 'aquatic'], Icons.pool),
    _IconPattern(['skincare'], Icons.face_2), // Must be before 'ski' pattern!
    _IconPattern(['skiing', 'snowboard', 'winter sport'], Icons.downhill_skiing),
    _IconPattern(['adventure sport', 'extreme', 'stunt', 'trick shot'], Icons.sports_kabaddi),
    _IconPattern(['horse', 'equestrian'], Icons.pets),

    // Fitness & Health
    _IconPattern(['gym', 'workout', 'fitness'], Icons.fitness_center),
    _IconPattern(['fat-loss', 'body transformation', 'glow-up'], Icons.trending_down),
    _IconPattern(['nutrition', 'meal'], Icons.restaurant_menu),
    _IconPattern(['supplement', 'wellness product'], Icons.medication),
    _IconPattern(['mental health', 'self-regulation'], Icons.psychology),
    _IconPattern(['habit', 'discipline'], Icons.checklist),
    _IconPattern(['self-improvement', 'productivity'], Icons.trending_up),

    // Food & Cooking
    _IconPattern(['cook', 'recipe', 'chef', 'kitchen'], Icons.restaurant),
    _IconPattern(['baking', 'dessert'], Icons.cake),
    _IconPattern(['coffee', 'barista', 'drink'], Icons.local_cafe),
    _IconPattern(['food review', 'taste test', 'street food'], Icons.fastfood),
    _IconPattern(['meal prep'], Icons.lunch_dining),

    // Music & Dance
    _IconPattern(['beat', 'production', 'dj', 'turntable'], Icons.music_note),
    _IconPattern(['beatbox'], Icons.mic),
    _IconPattern(['sing', 'cover'], Icons.mic_external_on),
    _IconPattern(['freestyle', 'rap'], Icons.record_voice_over),
    _IconPattern(['instrument', 'music education'], Icons.piano),
    _IconPattern(['mashup', 'remix'], Icons.library_music),
    _IconPattern(['dance', 'choreograph'], Icons.nightlife),
    _IconPattern(['concert', 'festival', 'rave'], Icons.celebration),

    // Beauty & Fashion
    _IconPattern(['makeup'], Icons.face_retouching_natural),
    _IconPattern(['hair'], Icons.content_cut),
    _IconPattern(['nail'], Icons.brush),
    _IconPattern(['fashion', 'outfit', 'styling'], Icons.checkroom),
    _IconPattern(['grwm', 'routine'], Icons.watch_later),

    // Tech & AI
    _IconPattern(['ai tool', 'ai '], Icons.smart_toy),
    _IconPattern(['automation', 'no-code'], Icons.settings_suggest),
    _IconPattern(['coding', 'programming'], Icons.code),
    _IconPattern(['cybersecurity'], Icons.security),
    _IconPattern(['gadget', 'unboxing'], Icons.unarchive),
    _IconPattern(['smartphone'], Icons.smartphone),
    _IconPattern(['smart home'], Icons.home_max),
    _IconPattern(['tech review', 'app', 'software'], Icons.devices),
    _IconPattern(['drone'], Icons.flight_takeoff),

    // Cars & Vehicles
    _IconPattern(['car ', 'car review', 'car spot', 'car transform'], Icons.directions_car),
    _IconPattern(['motorcycle'], Icons.two_wheeler),
    _IconPattern(['truck', 'off-road'], Icons.local_shipping),
    _IconPattern(['motorsport'], Icons.sports_motorsports),
    _IconPattern(['mechanic', 'repair'], Icons.build),
    _IconPattern(['detail', 'power wash'], Icons.cleaning_services),

    // Home & DIY
    _IconPattern(['diy', 'craft'], Icons.handyman),
    _IconPattern(['room makeover', 'interior'], Icons.weekend),
    _IconPattern(['cleaning', 'organization'], Icons.cleaning_services),
    _IconPattern(['home buy', 'rent'], Icons.house),
    _IconPattern(['real estate'], Icons.apartment),
    _IconPattern(['restoration'], Icons.auto_fix_high),

    // Business & Finance
    _IconPattern(['entrepreneur', 'startup', 'founder'], Icons.rocket_launch),
    _IconPattern(['investing', 'market'], Icons.show_chart),
    _IconPattern(['finance', 'money'], Icons.attach_money),
    _IconPattern(['side hustle', 'make money'], Icons.monetization_on),
    _IconPattern(['sales', 'persuasion'], Icons.handshake),
    _IconPattern(['career', 'workplace'], Icons.work),

    // Education & Learning
    _IconPattern(['book', 'booktok'], Icons.menu_book),
    _IconPattern(['study'], Icons.school),
    _IconPattern(['language'], Icons.translate),
    _IconPattern(['history'], Icons.history_edu),
    _IconPattern(['science'], Icons.science),
    _IconPattern(['psychology'], Icons.psychology_alt),

    // Entertainment & Comedy
    _IconPattern(['comedy', 'skit', 'funny', 'pov'], Icons.mood),
    _IconPattern(['meme'], Icons.sentiment_very_satisfied),
    _IconPattern(['movie', 'tv review'], Icons.movie),
    _IconPattern(['anime', 'manga'], Icons.animation),
    _IconPattern(['celebrity', 'gossip', 'pop culture'], Icons.stars),
    _IconPattern(['drama', 'internet culture'], Icons.forum),
    _IconPattern(['podcast'], Icons.podcasts),
    _IconPattern(['reaction', 'duet'], Icons.reviews),
    _IconPattern(['hot take', 'opinion'], Icons.campaign),

    // Relationships & Lifestyle
    _IconPattern(['dating'], Icons.favorite_border),
    _IconPattern(['couple', 'relationship', 'marriage'], Icons.favorite),
    _IconPattern(['breakup', 'healing'], Icons.healing),
    _IconPattern(['long-distance'], Icons.connect_without_contact),
    _IconPattern(['friendship', 'social'], Icons.people),
    _IconPattern(['confession', 'vulnerable', 'storytime'], Icons.auto_stories),
    _IconPattern(['life update', 'vlog', 'day in'], Icons.videocam),
    _IconPattern(['luxury', 'aesthetic'], Icons.diamond),
    _IconPattern(['red-flag', 'green-flag'], Icons.flag),

    // Family & Parenting
    _IconPattern(['baby', 'newborn'], Icons.child_friendly),
    _IconPattern(['pregnancy'], Icons.pregnant_woman),
    _IconPattern(['parenting', 'parent', 'mom hack', 'dad hack'], Icons.family_restroom),
    _IconPattern(['family'], Icons.groups),
    _IconPattern(['kid', 'teen', 'homeschool'], Icons.child_care),

    // Pets & Animals
    _IconPattern(['pet', 'cute pet', 'funny pet'], Icons.pets),
    _IconPattern(['dog'], Icons.cruelty_free),
    _IconPattern(['aquarium'], Icons.water),
    _IconPattern(['exotic pet'], Icons.pest_control),
    _IconPattern(['rescue', 'adoption'], Icons.volunteer_activism),

    // Art & Design
    _IconPattern(['calligraphy', 'handwriting'], Icons.edit),
    _IconPattern(['digital art', 'traditional art'], Icons.brush),
    _IconPattern(['animation', 'motion design'], Icons.movie_filter),
    _IconPattern(['graphic design', 'logo', 'brand'], Icons.design_services),
    _IconPattern(['pottery', 'clay'], Icons.emoji_objects),
    _IconPattern(['photo', 'photography'], Icons.camera_alt),
    _IconPattern(['editing', 'creator tool'], Icons.photo_filter),

    // ASMR & Satisfying
    _IconPattern(['asmr', 'calming', 'ambience'], Icons.spa),
    _IconPattern(['satisfying', 'kinetic', 'sand'], Icons.auto_awesome),
    _IconPattern(['soap', 'slime', 'texture'], Icons.water_drop),

    // Stories & Transformation
    _IconPattern(['transformation', 'before', 'after'], Icons.compare),
    _IconPattern(['comeback', 'failure lesson'], Icons.emoji_events),
    _IconPattern(['behind-the-scenes', 'creator story'], Icons.visibility),
  ];

  /// Category fallback patterns
  static final List<_IconPattern> _categoryPatterns = [
    _IconPattern(['entertainment', 'humor'], Icons.mood),
    _IconPattern(['storytelling', 'narrative'], Icons.auto_stories),
    _IconPattern(['lifestyle', 'relationship'], Icons.favorite),
    _IconPattern(['beauty', 'fashion'], Icons.checkroom),
    _IconPattern(['fitness', 'health', 'wellness'], Icons.fitness_center),
    _IconPattern(['food', 'cooking', 'beverage'], Icons.restaurant),
    _IconPattern(['education', 'knowledge', 'improvement'], Icons.school),
    _IconPattern(['business', 'money', 'career'], Icons.business_center),
    _IconPattern(['tech', 'ai', 'digital'], Icons.computer),
    _IconPattern(['gaming'], Icons.sports_esports),
    _IconPattern(['travel'], Icons.flight),
    _IconPattern(['outdoor', 'nature'], Icons.park),
    _IconPattern(['home', 'diy', 'real estate'], Icons.home),
    _IconPattern(['car', 'motorsport', 'machine'], Icons.directions_car),
    _IconPattern(['music', 'dance', 'performance'], Icons.music_note),
    _IconPattern(['art', 'design', 'creative'], Icons.palette),
    _IconPattern(['parenting', 'kids', 'family'], Icons.family_restroom),
    _IconPattern(['pets', 'animal'], Icons.pets),
    _IconPattern(['sports', 'physical'], Icons.sports),
    _IconPattern(['asmr', 'satisfying', 'sensory'], Icons.spa),
  ];
}

class _IconPattern {
  final List<String> patterns;
  final IconData icon;

  const _IconPattern(this.patterns, this.icon);
}
