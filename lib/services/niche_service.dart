import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hooko_v20/models/niche.dart';

/// Service for fetching niche benchmark data from Supabase
class NicheService {
  static final NicheService _instance = NicheService._internal();
  factory NicheService() => _instance;
  NicheService._internal();

  final _supabase = Supabase.instance.client;
  
  // Cache niches to avoid repeated queries
  final Map<String, Niche> _cache = {};

  /// Fetch a niche by its slug
  Future<Niche> getNicheBySlug(String slug) async {
    // Check cache first
    if (_cache.containsKey(slug)) {
      return _cache[slug]!;
    }

    try {
      final response = await _supabase
          .from('niches')
          .select()
          .eq('slug', slug)
          .single();

      final niche = Niche.fromJson(response);
      _cache[slug] = niche;
      return niche;
    } catch (e) {
      debugPrint('Error fetching niche by slug "$slug": $e');
      return Niche.defaultNiche;
    }
  }

  /// Fetch all niches (for potential future use)
  Future<List<Niche>> getAllNiches() async {
    try {
      final response = await _supabase
          .from('niches')
          .select()
          .order('category')
          .order('name');

      return (response as List).map((e) => Niche.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching all niches: $e');
      return [];
    }
  }

  /// Clear cache (useful for testing or refresh)
  void clearCache() {
    _cache.clear();
  }
}
