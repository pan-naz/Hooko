import 'package:flutter/material.dart';
import 'package:hooko_v20/components/daily_limit_dialog.dart';
import 'package:hooko_v20/components/hooko_plus_paywall.dart';
import 'package:hooko_v20/state/app_state.dart';

/// Gate that decides whether the user is allowed to start a real analysis.
///
/// Flow:
/// 1. If user is not subscribed → show the Hooko Plus paywall and return false.
///    (After a successful purchase, the RevenueCat listener will update the
///    tier. The caller should re-invoke the action if the user upgrades.)
/// 2. If user is subscribed → refresh today's usage from the server.
///    If the daily limit has been reached → show a "come back tomorrow"
///    dialog and return false.
/// 3. Otherwise return true.
class AnalysisGate {
  /// Returns true if the user can proceed with starting a new analysis.
  static Future<bool> ensureCanAnalyze(BuildContext context) async {
    final appState = AppStateProvider.read(context);

    // Not subscribed → paywall.
    if (!appState.isProSubscribed) {
      await HookoPlusPaywall.show(context);
      // Do not auto-start analysis after purchase; user explicitly re-taps.
      return false;
    }

    // Subscribed → decide based on the cached server count. The count is
    // primed at app launch (via [AppState.setSubscriptionTier] →
    // [AppState.refreshDailyUsage]) and updated after every analysis by
    // [AppState.recordAnalysisUsed], which returns the authoritative server
    // total. We deliberately do NOT refresh here so the file picker opens
    // immediately on tap (no network round-trip in the critical path).
    if (!appState.hasDailyAnalysesRemaining) {
      await DailyLimitReachedDialog.show(
        context,
        limit: appState.dailyAnalysisTotal,
        tier: appState.subscriptionTier,
      );
      return false;
    }

    return true;
  }
}
