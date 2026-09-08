import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooko_v20/state/app_state.dart';

/// RevenueCat integration service.
///
/// - Initializes the SDK with the iOS public API key.
/// - Exposes the current entitlement state (mapped to [SubscriptionTier]).
/// - Provides helpers to fetch offerings, purchase a package, and restore.
///
/// NOTE: Web is intentionally NOT supported. All methods are no-ops on web.
/// Outcome of a call to [RevenueCatService.restorePurchases].
enum RestoreResult {
  /// Entitlement is now active — subscription was restored.
  restored,

  /// Call succeeded but no active subscription was found on the account.
  noSubscription,

  /// Call failed (network, store unavailable, etc.).
  error,

  /// Platform doesn't support in-app purchases (e.g. web).
  unsupported,
}

class RevenueCatService {
  RevenueCatService._();

  /// Public iOS SDK key from the RevenueCat dashboard.
  static const String _iosApiKey = 'appl_nMjkuPQfrajRTRGYPKkXnnNprPX';

  /// Entitlement identifier configured in RevenueCat.
  static const String entitlementId = 'plus';

  /// Product identifiers for the two tiers (App Store Connect product IDs).
  static const String productPlus10 = 'plus_10_monthly';
  static const String productPlus20 = 'plus_20_monthly';

  static bool _initialized = false;

  /// Whether we're running on a platform that supports RevenueCat.
  /// Web is skipped per project requirements.
  static bool get isSupported => !kIsWeb;

  /// Initialize the RevenueCat SDK. Safe to call multiple times.
  /// Pass [appState] so we can listen for entitlement changes and update tier.
  static Future<void> initialize(AppState appState) async {
    if (!isSupported) {
      // Web / unsupported platforms: treat as non-subscriber and unblock splash.
      appState.markRcInitialSyncComplete();
      return;
    }
    if (_initialized) {
      appState.markRcInitialSyncComplete();
      return;
    }
    try {
      await Purchases.setLogLevel(LogLevel.info);
      await Purchases.configure(PurchasesConfiguration(_iosApiKey));
      _initialized = true;

      // STEP 1 (fast): push cached customer info IMMEDIATELY so the rest of
      // the app (including the daily-usage fetch triggered by
      // setSubscriptionTier) can start in parallel with restore. The cached
      // info is local-only and returns near-instantly.
      try {
        final cached = await Purchases.getCustomerInfo();
        _applyCustomerInfo(appState, cached);
      } catch (e) {
        debugPrint('RevenueCat: initial cached getCustomerInfo failed: $e');
      }
      appState.markRcInitialSyncComplete();

      // STEP 2 (background): force a receipt sync.
      //
      // For anonymous users, RevenueCat generates a fresh `$RCAnonymousID:...`
      // on every install. `restorePurchases()` reads the App Store receipt
      // (which IS preserved across reinstalls and full wipes, tied to the
      // Apple ID) and aliases the fresh anon ID back to the original
      // subscriber record. After this call, `originalAppUserId` returns the
      // stable ID we use as the key for `daily_analysis_usage`.
      //
      // This is the ONLY identity source that survives:
      //   - app reinstall
      //   - full device wipe / restore
      //   - moving to a new device (same Apple ID)
      //
      // Run in background — if it changes the tier or stable user id,
      // _applyCustomerInfo will fire setSubscriptionTier again which refreshes
      // daily usage with the corrected identity.
      // ignore: discarded_futures
      Purchases.restorePurchases().then((info) {
        _applyCustomerInfo(appState, info);
      }).catchError((Object e) {
        debugPrint('RevenueCat: initial restore failed (likely no receipt): $e');
      });

      // Listen for any future changes.
      Purchases.addCustomerInfoUpdateListener((info) {
        _applyCustomerInfo(appState, info);
      });
    } catch (e) {
      debugPrint('RevenueCat: init failed: $e');
      // Don't block the splash forever — mark as complete so the app routes
      // the user as a non-subscriber.
      appState.markRcInitialSyncComplete();
    }
  }

  /// Returns the current app user ID (anonymous `$RCAnonymousID:...` by default).
  /// Returns null if unsupported / not initialized.
  ///
  /// NOTE: This changes on every fresh install for anonymous users. For
  /// cross-device / cross-reinstall tracking use [getStableUserId] instead.
  static Future<String?> getAppUserId() async {
    if (!isSupported) return null;
    try {
      return await Purchases.appUserID;
    } catch (e) {
      debugPrint('RevenueCat: getAppUserId failed: $e');
      return null;
    }
  }

  /// Returns a stable user identifier that survives reinstalls for subscribed
  /// users by leveraging RevenueCat's `originalAppUserId`.
  ///
  /// `originalAppUserId` is the first appUserID that ever logged a purchase
  /// for this Apple ID. After a fresh install RevenueCat restores it via the
  /// App Store receipt, so two devices / two reinstalls with the same Apple
  /// ID return the same value.
  ///
  /// Falls back to the current `appUserID` if `originalAppUserId` is missing
  /// (e.g. user has never subscribed). Returns null if unsupported.
  static Future<String?> getStableUserId() async {
    if (!isSupported) return null;
    try {
      final info = await Purchases.getCustomerInfo();
      final original = info.originalAppUserId;
      if (original.isNotEmpty) return original;
      return await Purchases.appUserID;
    } catch (e) {
      debugPrint('RevenueCat: getStableUserId failed: $e');
      return null;
    }
  }

  /// Fetches the current offerings. Returns null if unsupported or on error.
  static Future<Offerings?> getOfferings() async {
    if (!isSupported) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat: getOfferings failed: $e');
      return null;
    }
  }

  /// Purchase a package. Returns true if the entitlement is now active.
  static Future<bool> purchasePackage(Package package, AppState appState) async {
    if (!isSupported) return false;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      _applyCustomerInfo(appState, result.customerInfo);
      return result.customerInfo.entitlements.active.containsKey(entitlementId);
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('RevenueCat: purchase failed: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('RevenueCat: purchase failed: $e');
      return false;
    }
  }

  /// Opens the native subscription management UI (App Store on iOS), where
  /// the user can upgrade / downgrade / cancel their subscription.
  ///
  /// No-op on web or if the SDK isn't initialized.
  static Future<void> showManageSubscriptions() async {
    if (!isSupported) return;
    try {
      final info = await Purchases.getCustomerInfo();
      final url = info.managementURL;
      if (url == null || url.isEmpty) {
        debugPrint('RevenueCat: managementURL is null (no active store subscription)');
        return;
      }
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('RevenueCat: failed to launch managementURL=$url');
      }
    } catch (e) {
      debugPrint('RevenueCat: showManageSubscriptions failed: $e');
    }
  }

  /// Restore previous purchases. Returns a [RestoreResult] describing the
  /// outcome so the UI can show the appropriate feedback.
  static Future<RestoreResult> restorePurchases(AppState appState) async {
    if (!isSupported) return RestoreResult.unsupported;
    try {
      final info = await Purchases.restorePurchases();
      _applyCustomerInfo(appState, info);
      final active = info.entitlements.active.containsKey(entitlementId);
      return active ? RestoreResult.restored : RestoreResult.noSubscription;
    } catch (e) {
      debugPrint('RevenueCat: restore failed: $e');
      return RestoreResult.error;
    }
  }

  /// Maps a [CustomerInfo] to a [SubscriptionTier] and updates [appState].
  static void _applyCustomerInfo(AppState appState, CustomerInfo info) {
    // Debug dump so we can see exactly what RC is reporting in sandbox/prod.
    debugPrint('RC: appUserId=${info.originalAppUserId}');
    debugPrint('RC: active entitlements=${info.entitlements.active.keys.toList()}');
    for (final e in info.entitlements.active.values) {
      debugPrint(
        'RC:  - id=${e.identifier} productId=${e.productIdentifier} '
        'isSandbox=${e.isSandbox} willRenew=${e.willRenew} '
        'periodType=${e.periodType} store=${e.store} '
        'expires=${e.expirationDate} latestPurchase=${e.latestPurchaseDate}',
      );
    }
    debugPrint('RC: managementURL=${info.managementURL}');

    final entitlement = info.entitlements.active[entitlementId];
    if (entitlement == null) {
      appState.setSubscriptionTier(SubscriptionTier.none);
      return;
    }

    final productId = entitlement.productIdentifier;
    if (productId == productPlus20) {
      appState.setSubscriptionTier(SubscriptionTier.plus20);
    } else if (productId == productPlus10) {
      appState.setSubscriptionTier(SubscriptionTier.plus10);
    } else {
      // Unknown product but entitlement is active — default to plus10.
      debugPrint('RevenueCat: active entitlement with unknown productId=$productId');
      appState.setSubscriptionTier(SubscriptionTier.plus10);
    }
  }
}
