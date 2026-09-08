import 'dart:convert';

/// Analysis result model containing all Gemini-generated content
class AnalysisResult {
  final String id;
  final String videoId;
  final DateTime createdAt;
  
  // Scores
  final int overallScore;
  final int audioScore;
  final int visualScore;
  final int benchmark;
  
  // Industry benchmarks (engagement rates from niches table via edge function)
  final double? industryBenchmarkTiktok;
  final double? industryBenchmarkInstagram;
  final double? industryBenchmarkYoutube;
  final double? industryBenchmarkAvg; // Pre-calculated average from DB
  
  // Niche detection (slug matches Supabase niches table)
  final String nicheSlug;
  final String? nicheName; // Cached niche display name for history
  final String? nicheCategory; // Cached niche category for icon display
  
  // Audio type detection (WITH_SPEECH or SILENT_MUSIC_ONLY)
  final String audioType;
  
  // Language detection (ISO 639-1 code, e.g., "en", "ar", "es")
  final String? detectedLanguage;
  
  // Hook timing data
  final double? voiceStartTime; // When voice first starts in the hook (seconds)
  final bool isVoiceLate; // True if voice starts after 0.7 seconds
  final int? hookTimingPenalty; // Penalty applied if voice starts late (0-10)
  
// Current hook analysis
  final String currentHookQuote;
  final String audioFeedback;
  final String visualFeedback;
  final List<String> whyNotWorking;
  
  // Hook alternatives (3 options)
  final List<HookAlternative> hookAlternatives;
  
  // Thumbnail for history display (base64 encoded)
  final String? thumbnailBase64;
  
  const AnalysisResult({
    required this.id,
    required this.videoId,
    required this.createdAt,
    required this.overallScore,
    required this.audioScore,
    required this.visualScore,
    required this.benchmark,
    this.industryBenchmarkTiktok,
    this.industryBenchmarkInstagram,
    this.industryBenchmarkYoutube,
    this.industryBenchmarkAvg,
    required this.nicheSlug,
    this.nicheName,
    this.nicheCategory,
    this.audioType = 'WITH_SPEECH',
    this.detectedLanguage,
    this.voiceStartTime,
    this.isVoiceLate = false,
    this.hookTimingPenalty,
    required this.currentHookQuote,
    required this.audioFeedback,
    required this.visualFeedback,
    required this.whyNotWorking,
    required this.hookAlternatives,
    this.thumbnailBase64,
  });
  
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'] ?? '',
      videoId: json['video_id'] ?? '',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      overallScore: (json['overall_score'] as num?)?.toInt() ?? 0,
      audioScore: (json['audio_score'] as num?)?.toInt() ?? 0,
      visualScore: (json['visual_score'] as num?)?.toInt() ?? 0,
      benchmark: (json['benchmark'] as num?)?.toInt() ?? 70,
      // Map both field naming conventions (edge function sends both)
      industryBenchmarkTiktok: (json['industry_benchmark_tiktok'] ?? json['niche_tiktok_engagement'] as num?)?.toDouble(),
      industryBenchmarkInstagram: (json['industry_benchmark_instagram'] ?? json['niche_instagram_engagement'] as num?)?.toDouble(),
      industryBenchmarkYoutube: (json['industry_benchmark_youtube'] ?? json['niche_youtube_engagement'] as num?)?.toDouble(),
      industryBenchmarkAvg: (json['industry_benchmark_avg'] ?? json['niche_avg_engagement'] as num?)?.toDouble(),
      nicheSlug: json['niche_slug'] ?? 'relatable_pov_comedy',
      nicheName: json['niche_name'],
      nicheCategory: json['niche_category'],
      audioType: json['audio_type'] ?? 'WITH_SPEECH',
      detectedLanguage: json['detected_language'],
      // Support both field names: voice_start_time (stored) and voice_start_seconds (edge function)
      voiceStartTime: (json['voice_start_time'] ?? json['voice_start_seconds'] as num?)?.toDouble(),
      isVoiceLate: json['is_voice_late'] == true,
      // Support both field names: hook_timing_penalty (stored) and audio_penalty (edge function)
      hookTimingPenalty: (json['hook_timing_penalty'] ?? json['audio_penalty'] as num?)?.toInt(),
      currentHookQuote: json['current_hook_quote'] ?? '',
      audioFeedback: json['audio_feedback'] ?? '',
      visualFeedback: json['visual_feedback'] ?? '',
      whyNotWorking: List<String>.from(json['why_not_working'] ?? []),
      hookAlternatives: (json['hook_alternatives'] as List?)
          ?.map((e) => HookAlternative.fromJson(e))
          .toList() ?? [],
      thumbnailBase64: json['thumbnail_base64'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'video_id': videoId,
    'created_at': createdAt.toIso8601String(),
    'overall_score': overallScore,
    'audio_score': audioScore,
    'visual_score': visualScore,
    'benchmark': benchmark,
    'industry_benchmark_tiktok': industryBenchmarkTiktok,
    'industry_benchmark_instagram': industryBenchmarkInstagram,
    'industry_benchmark_youtube': industryBenchmarkYoutube,
    'industry_benchmark_avg': industryBenchmarkAvg,
    'niche_slug': nicheSlug,
    'niche_name': nicheName,
    'niche_category': nicheCategory,
    'audio_type': audioType,
    'detected_language': detectedLanguage,
    'voice_start_time': voiceStartTime,
    'is_voice_late': isVoiceLate,
    'hook_timing_penalty': hookTimingPenalty,
    'current_hook_quote': currentHookQuote,
    'audio_feedback': audioFeedback,
    'visual_feedback': visualFeedback,
    'why_not_working': whyNotWorking,
    'hook_alternatives': hookAlternatives.map((e) => e.toJson()).toList(),
    'thumbnail_base64': thumbnailBase64,
  };
  
  /// Create a copy with updated fields
  AnalysisResult copyWith({
    String? id,
    String? videoId,
    DateTime? createdAt,
    int? overallScore,
    int? audioScore,
    int? visualScore,
    int? benchmark,
    double? industryBenchmarkTiktok,
    double? industryBenchmarkInstagram,
    double? industryBenchmarkYoutube,
    double? industryBenchmarkAvg,
    String? nicheSlug,
    String? nicheName,
    String? nicheCategory,
    String? audioType,
    String? detectedLanguage,
    double? voiceStartTime,
    bool? isVoiceLate,
    int? hookTimingPenalty,
    String? currentHookQuote,
    String? audioFeedback,
    String? visualFeedback,
    List<String>? whyNotWorking,
    List<HookAlternative>? hookAlternatives,
    String? thumbnailBase64,
  }) => AnalysisResult(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    createdAt: createdAt ?? this.createdAt,
    overallScore: overallScore ?? this.overallScore,
    audioScore: audioScore ?? this.audioScore,
    visualScore: visualScore ?? this.visualScore,
    benchmark: benchmark ?? this.benchmark,
    industryBenchmarkTiktok: industryBenchmarkTiktok ?? this.industryBenchmarkTiktok,
    industryBenchmarkInstagram: industryBenchmarkInstagram ?? this.industryBenchmarkInstagram,
    industryBenchmarkYoutube: industryBenchmarkYoutube ?? this.industryBenchmarkYoutube,
    industryBenchmarkAvg: industryBenchmarkAvg ?? this.industryBenchmarkAvg,
    nicheSlug: nicheSlug ?? this.nicheSlug,
    nicheName: nicheName ?? this.nicheName,
    nicheCategory: nicheCategory ?? this.nicheCategory,
    audioType: audioType ?? this.audioType,
    detectedLanguage: detectedLanguage ?? this.detectedLanguage,
    voiceStartTime: voiceStartTime ?? this.voiceStartTime,
    isVoiceLate: isVoiceLate ?? this.isVoiceLate,
    hookTimingPenalty: hookTimingPenalty ?? this.hookTimingPenalty,
    currentHookQuote: currentHookQuote ?? this.currentHookQuote,
    audioFeedback: audioFeedback ?? this.audioFeedback,
    visualFeedback: visualFeedback ?? this.visualFeedback,
    whyNotWorking: whyNotWorking ?? this.whyNotWorking,
    hookAlternatives: hookAlternatives ?? this.hookAlternatives,
    thumbnailBase64: thumbnailBase64 ?? this.thumbnailBase64,
  );
  
  String toJsonString() => jsonEncode(toJson());
  
  static AnalysisResult fromJsonString(String jsonString) =>
      AnalysisResult.fromJson(jsonDecode(jsonString));
  
/// Creates a placeholder result for error states
  factory AnalysisResult.placeholder() => AnalysisResult(
    id: '',
    videoId: '',
    createdAt: DateTime.now(),
    overallScore: 0,
    audioScore: 0,
    visualScore: 0,
    benchmark: 70,
    industryBenchmarkTiktok: null,
    industryBenchmarkInstagram: null,
    industryBenchmarkYoutube: null,
    industryBenchmarkAvg: null,
    nicheSlug: 'relatable_pov_comedy',
    nicheName: null,
    nicheCategory: null,
    detectedLanguage: 'en',
    voiceStartTime: null,
    isVoiceLate: false,
    hookTimingPenalty: null,
    currentHookQuote: '',
    audioFeedback: '',
    visualFeedback: '',
    whyNotWorking: [],
    hookAlternatives: [
      HookAlternative(
        index: 1,
        estimatedScore: 0,
        sayThisQuote: '',
        audioTechniques: [],
        sayThisRationale: '',
        showThisQuote: '',
        visualTechniques: [],
        showThisRationale: '',
        proTips: [],
        generalTips: [],
        scriptAfterHook: '',
        visualAfterHook: '',
        suggestedCaption: '',
        suggestedHashtags: [],
      ),
    ],
    thumbnailBase64: null,
  );
}

/// A single hook alternative with say/show suggestions
class HookAlternative {
  final int index;
  final int estimatedScore;
  
  // Say This
  final String sayThisQuote;
  final List<String> audioTechniques; // DB technique slugs (2-4 per alternative)
  final String sayThisRationale;
  
  // Show This
  final String showThisQuote;
  final List<String> visualTechniques; // DB technique slugs (2-4 per alternative)
  final String showThisRationale;
  
  // Pro Tips
  final List<AnalysisTipSection> proTips;
  final List<String> generalTips;
  
  // Updated Script
  final String scriptAfterHook;
  final String visualAfterHook;
  final CtaSection? cta;
  
  // Caption & Hashtags
  final String suggestedCaption;
  final List<String> suggestedHashtags;
  
  // Viral Example
  final ViralExample? viralExample;
  
  const HookAlternative({
    required this.index,
    required this.estimatedScore,
    required this.sayThisQuote,
    required this.audioTechniques,
    required this.sayThisRationale,
    required this.showThisQuote,
    required this.visualTechniques,
    required this.showThisRationale,
    required this.proTips,
    required this.generalTips,
    required this.scriptAfterHook,
    required this.visualAfterHook,
    this.cta,
    required this.suggestedCaption,
    required this.suggestedHashtags,
    this.viralExample,
  });
  
  factory HookAlternative.fromJson(Map<String, dynamic> json) {
    return HookAlternative(
      index: (json['index'] as num?)?.toInt() ?? 1,
      estimatedScore: (json['estimated_score'] as num?)?.toInt() ?? 0,
      sayThisQuote: json['say_this_quote'] ?? '',
      // Support both new field (audio_techniques) and old field (say_this_tags)
      audioTechniques: List<String>.from(json['audio_techniques'] ?? json['say_this_tags'] ?? []),
      sayThisRationale: json['say_this_rationale'] ?? '',
      showThisQuote: json['show_this_quote'] ?? '',
      // Support both new field (visual_techniques) and old field (show_this_tags)
      visualTechniques: List<String>.from(json['visual_techniques'] ?? json['show_this_tags'] ?? []),
      showThisRationale: json['show_this_rationale'] ?? '',
      proTips: (json['pro_tips'] as List?)
          ?.map((e) => AnalysisTipSection.fromJson(e))
          .toList() ?? [],
      generalTips: List<String>.from(json['general_tips'] ?? []),
      scriptAfterHook: json['script_after_hook'] ?? '',
      visualAfterHook: json['visual_after_hook'] ?? '',
      cta: json['cta'] != null ? CtaSection.fromJson(json['cta']) : null,
      suggestedCaption: json['suggested_caption'] ?? '',
      suggestedHashtags: List<String>.from(json['suggested_hashtags'] ?? []),
      viralExample: json['viral_example'] != null 
          ? ViralExample.fromJson(json['viral_example']) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'index': index,
    'estimated_score': estimatedScore,
    'say_this_quote': sayThisQuote,
    'audio_techniques': audioTechniques,
    'say_this_rationale': sayThisRationale,
    'show_this_quote': showThisQuote,
    'visual_techniques': visualTechniques,
    'show_this_rationale': showThisRationale,
    'pro_tips': proTips.map((e) => e.toJson()).toList(),
    'general_tips': generalTips,
    'script_after_hook': scriptAfterHook,
    'visual_after_hook': visualAfterHook,
    'cta': cta?.toJson(),
    'suggested_caption': suggestedCaption,
    'suggested_hashtags': suggestedHashtags,
    'viral_example': viralExample?.toJson(),
  };
}

/// Tip section for pro tips (model version)
class AnalysisTipSection {
  final String title;
  final String iconType; // 'audio', 'visual', 'timing'
  final List<String> tips;
  
  const AnalysisTipSection({
    required this.title,
    required this.iconType,
    required this.tips,
  });
  
  factory AnalysisTipSection.fromJson(Map<String, dynamic> json) {
    return AnalysisTipSection(
      title: json['title'] ?? '',
      iconType: json['icon_type'] ?? 'audio',
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'title': title,
    'icon_type': iconType,
    'tips': tips,
  };
}

/// CTA section for call-to-action suggestions
class CtaSection {
  final String sayThisContent;
  final String showThisContent;
  
  const CtaSection({
    required this.sayThisContent,
    required this.showThisContent,
  });
  
  factory CtaSection.fromJson(Map<String, dynamic> json) {
    return CtaSection(
      sayThisContent: json['say_this_content'] ?? '',
      showThisContent: json['show_this_content'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'say_this_content': sayThisContent,
    'show_this_content': showThisContent,
  };
}

/// Viral example reference
class ViralExample {
  final String thumbnailUrl;
  final List<String> tags; // Changed from hookType string to tags list
  final String description;
  final String youtubeUrl;
  
  const ViralExample({
    required this.thumbnailUrl,
    required this.tags,
    required this.description,
    required this.youtubeUrl,
  });
  
  factory ViralExample.fromJson(Map<String, dynamic> json) {
    return ViralExample(
      thumbnailUrl: json['thumbnail_url'] ?? '',
      // Support both new field (tags) and old field (hook_type)
      tags: json['tags'] != null 
          ? List<String>.from(json['tags']) 
          : (json['hook_type'] != null ? [json['hook_type'] as String] : []),
      description: json['description'] ?? '',
      youtubeUrl: json['youtube_url'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'thumbnail_url': thumbnailUrl,
    'tags': tags,
    'description': description,
    'youtube_url': youtubeUrl,
  };
}
