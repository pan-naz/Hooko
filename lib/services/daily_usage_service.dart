import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:hooko_v20/services/revenuecat_service.dart';
import 'package:hooko_v20/state/app_state.dart';
import 'package:hooko_v20/supabase/supabase_config.dart';

/// Snapshot of a user's daily analysis usage.
class DailyUsage {
  final int count;
  final int limit;
  final DateTime date;

  const DailyUsage({required this.count, required this.limit, required this.date});

  int get remaining => (limit - count).clamp(0, limit);
  bool get hasReachedLimit => count >= limit;
}

/// Server-authoritative tracking of daily analysis usage.
///
/// All reads/writes go through the `track-daily-usage` edge function. The
/// underlying `daily_analysis_usage` table is no longer accessible directly
/// from the client (RLS-locked, service-role only).
///
/// "Today" is computed on the server using the user's IANA timezone +
/// server UTC time, so changing the device clock has no effect on the
/// rollover day.
class DailyUsageService {
  static const String _functionName = 'track-daily-usage';

  /// Maximum analyses per day based on subscription tier.
  static int limitForTier(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus10:
        return 10;
      case SubscriptionTier.plus20:
        return 20;
      case SubscriptionTier.none:
        return 0;
    }
  }

  static String _tierKey(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.plus10:
        return 'plus10';
      case SubscriptionTier.plus20:
        return 'plus20';
      case SubscriptionTier.none:
        return 'none';
    }
  }

  /// Best-effort lookup of the device's IANA timezone name (e.g.
  /// "Asia/Tokyo"). Falls back to "UTC" if the platform plugin fails.
  static Future<String> _deviceTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final name = info.identifier;
      if (name.isNotEmpty) return name;
    } catch (e) {
      debugPrint('DailyUsageService: getLocalTimezone failed: $e');
    }
    return 'UTC';
  }

  static Future<Map<String, dynamic>?> _invoke({
    required String action,
    required String appUserId,
    required SubscriptionTier tier,
  }) async {
    final tz = await _deviceTimezone();
    try {
      final res = await SupabaseConfig.client.functions.invoke(
        _functionName,
        body: {
          'action': action,
          'app_user_id': appUserId,
          'tier': _tierKey(tier),
          'timezone': tz,
        },
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      debugPrint('DailyUsageService: unexpected response type: $data');
      return null;
    } catch (e) {
      debugPrint('DailyUsageService: invoke($action) failed: $e');
      return null;
    }
  }

  /// Returns the user ID used to key the daily-usage table.
  ///
  /// We use RevenueCat's `originalAppUserId`, which is derived from the Apple
  /// App Store receipt. This is the ONLY identifier that survives:
  ///   - app reinstall
  ///   - full device wipe / restore from backup
  ///   - moving to a brand-new device (same Apple ID)
  ///
  /// Free users are not subscribers and therefore have no usage row — the
  /// caller should short-circuit before reaching here.
  static Future<String?> _resolveUserId() async {
    return RevenueCatService.getStableUserId();
  }

  /// Fetch today's usage from the server. Returns null on failure.
  ///
  /// Free tier users are skipped — they have no analyses available, so there
  /// is nothing to fetch.
  static Future<DailyUsage?> fetchToday(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.none) {
      return DailyUsage(count: 0, limit: 0, date: DateTime.now());
    }

    final appUserId = await _resolveUserId();
    if (appUserId == null) return null;

    final data = await _invoke(
      action: 'get',
      appUserId: appUserId,
      tier: tier,
    );
    if (data == null) return null;

    final count = (data['count'] as num?)?.toInt() ?? 0;
    final limit = (data['limit'] as num?)?.toInt() ?? limitForTier(tier);
    final usageDate = data['usage_date'] as String?;
    final date = usageDate != null
        ? DateTime.tryParse(usageDate) ?? DateTime.now()
        : DateTime.now();
    return DailyUsage(count: count, limit: limit, date: date);
  }

  /// Atomically increment today's count by 1 and return the new total.
  /// Returns null on failure or for free-tier users.
  static Future<int?> incrementToday(SubscriptionTier tier) async {
    if (tier == SubscriptionTier.none) return null;

    final appUserId = await _resolveUserId();
    if (appUserId == null) return null;

    final data = await _invoke(
      action: 'increment',
      appUserId: appUserId,
      tier: tier,
    );
    if (data == null) return null;

    final count = (data['count'] as num?)?.toInt();
    return count;
  }
}
