import 'package:hooko_v20/utils/app_constants.dart';

/// Niche model representing benchmark data from Supabase
class Niche {
  final String id;
  final String category;
  final String name;
  final String slug;
  final int avgHookScore;
  final double? tiktokEngagement;
  final double? instagramEngagement;
  final double? youtubeEngagement;
  final double? avgEngagement;
  final DateTime createdAt;

  const Niche({
    required this.id,
    required this.category,
    required this.name,
    required this.slug,
    required this.avgHookScore,
    this.tiktokEngagement,
    this.instagramEngagement,
    this.youtubeEngagement,
    this.avgEngagement,
    required this.createdAt,
  });

  factory Niche.fromJson(Map<String, dynamic> json) {
    return Niche(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      avgHookScore: json['avg_hook_score'] ?? AppDefaultNiche.avgHookScore,
      tiktokEngagement: (json['tiktok_engagement'] as num?)?.toDouble(),
      instagramEngagement: (json['instagram_engagement'] as num?)?.toDouble(),
      youtubeEngagement: (json['youtube_engagement'] as num?)?.toDouble(),
      avgEngagement: (json['avg_engagement'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'name': name,
        'slug': slug,
        'avg_hook_score': avgHookScore,
        'tiktok_engagement': tiktokEngagement,
        'instagram_engagement': instagramEngagement,
        'youtube_engagement': youtubeEngagement,
        'avg_engagement': avgEngagement,
        'created_at': createdAt.toIso8601String(),
      };

  /// Default niche for fallback - uses centralized constants
  static Niche get defaultNiche => Niche(
        id: '',
        category: AppDefaultNiche.category,
        name: AppDefaultNiche.name,
        slug: AppDefaultNiche.slug,
        avgHookScore: AppDefaultNiche.avgHookScore,
        tiktokEngagement: AppDefaultNiche.tiktokEngagement,
        instagramEngagement: AppDefaultNiche.instagramEngagement,
        youtubeEngagement: AppDefaultNiche.youtubeEngagement,
        avgEngagement: AppDefaultNiche.avgEngagement,
        createdAt: DateTime.now(),
      );
}
