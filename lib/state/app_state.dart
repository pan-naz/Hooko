import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:hooko_v20/models/analysis_result.dart';
import 'package:hooko_v20/services/analysis_service.dart';
import 'package:hooko_v20/services/daily_usage_service.dart';

/// Subscription tier based on RevenueCat entitlement.
enum SubscriptionTier {
  /// Not subscribed - demo mode only
  none,
  /// Plus10 - 10 daily analyses
  plus10,
  /// Plus20 - 20 daily analyses
  plus20,
}

/// App-wide state management using InheritedWidget pattern
class AppState extends ChangeNotifier {
  AssetEntity? _selectedVideoAsset;
  AnalysisResult? _latestAnalysisResult;
  
  /// Cached history list - preloaded on app start
  List<AnalysisResult> _history = [];
  bool _historyLoaded = false;
  
  /// Whether viewing a saved result from history (static view, no video)
  bool _isViewingFromHistory = false;
  
  /// Current subscription tier
  SubscriptionTier _subscriptionTier = SubscriptionTier.none;

  /// Whether RevenueCat has reported the initial entitlement state at least once.
  /// Used by the splash screen to decide where to route the user.
  bool _rcInitialSyncComplete = false;
  bool get rcInitialSyncComplete => _rcInitialSyncComplete;

  /// Completer-style future that resolves when [_rcInitialSyncComplete] flips to true.
  Future<void> get rcInitialSyncFuture {
    if (_rcInitialSyncComplete) return Future.value();
    _rcInitialSyncCompleter ??= Completer<void>();
    return _rcInitialSyncCompleter!.future;
  }
  Completer<void>? _rcInitialSyncCompleter;

  /// Mark RC initial sync as complete (called by RevenueCatService).
  void markRcInitialSyncComplete() {
    if (_rcInitialSyncComplete) return;
    _rcInitialSyncComplete = true;
    _rcInitialSyncCompleter?.complete();
    _rcInitialSyncCompleter = null;
    notifyListeners();
  }
  
  /// Number of analyses used today (server-authoritative; refreshed via [refreshDailyUsage]).
  int _dailyAnalysisUsed = 0;

  /// Whether the daily usage has been fetched from the server at least once.
  bool _dailyUsageLoaded = false;
  bool get dailyUsageLoaded => _dailyUsageLoaded;

  /// Future that resolves the first time daily usage has been loaded
  /// (either from server or skipped for free tier). The splash awaits this
  /// before navigating so the user never sees a stale "0" count flash.
  Completer<void>? _dailyUsageLoadedCompleter;
  Future<void> get dailyUsageLoadedFuture {
    if (_dailyUsageLoaded) return Future.value();
    _dailyUsageLoadedCompleter ??= Completer<void>();
    return _dailyUsageLoadedCompleter!.future;
  }

  void _markDailyUsageLoaded() {
    if (_dailyUsageLoaded) return;
    _dailyUsageLoaded = true;
    _dailyUsageLoadedCompleter?.complete();
    _dailyUsageLoadedCompleter = null;
  }
  
  /// Total analyses available per day based on subscription
  int get dailyAnalysisTotal {
    switch (_subscriptionTier) {
      case SubscriptionTier.plus10:
        return 10;
      case SubscriptionTier.plus20:
        return 20;
      case SubscriptionTier.none:
        return 0;
    }
  }
  
  /// Badge label based on subscription status (used when no SVG asset available)
  String get subscriptionBadgeLabel => _subscriptionTier == SubscriptionTier.none ? 'Demo' : '';
  
  /// SVG asset path for the badge, or null to fall back to [subscriptionBadgeLabel].
  String? get subscriptionBadgeAsset {
    switch (_subscriptionTier) {
      case SubscriptionTier.plus10:
        return 'assets/icons/plus10.svg';
      case SubscriptionTier.plus20:
        return 'assets/icons/plus20.svg';
      case SubscriptionTier.none:
        return null;
    }
  }
  
  /// Current subscription tier
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  
  /// Whether user has any active paid subscription
  bool get isProSubscribed => _subscriptionTier != SubscriptionTier.none;
  
  /// Get daily analysis used count
  int get dailyAnalysisUsed => _dailyAnalysisUsed;
  
  /// Set subscription tier (call from RevenueCat listener)
  void setSubscriptionTier(SubscriptionTier tier) {
    final changed = _subscriptionTier != tier;
    _subscriptionTier = tier;
    if (changed) notifyListeners();
    // Always refresh server-side daily usage when RC reports a tier (covers
    // first-load case where the tier matches the default but we haven't yet
    // synced today's count). Fire-and-forget.
    // ignore: discarded_futures
    refreshDailyUsage();
  }

  /// Backwards-compatible setter. Defaults to plus10 when [value] is true.
  void setProSubscribed(bool value) {
    setSubscriptionTier(value ? SubscriptionTier.plus10 : SubscriptionTier.none);
  }

  /// Whether the last refresh attempt failed (e.g. no internet). When true,
  /// the UI can show an offline indicator instead of a stale/zero count.
  bool _dailyUsageFailed = false;
  bool get dailyUsageFailed => _dailyUsageFailed;

  /// Guards against concurrent refreshes.
  bool _dailyUsageRefreshInFlight = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Begin listening for connectivity changes so we can auto-retry the
  /// daily usage fetch when the connection is restored.
  void initConnectivityWatcher() {
    _connectivitySub ??= Connectivity()
        .onConnectivityChanged
        .listen((results) {
      final hasConnection =
          results.any((r) => r != ConnectivityResult.none);
      if (hasConnection && _dailyUsageFailed) {
        // ignore: discarded_futures
        refreshDailyUsage();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  /// Fetch today's usage from Supabase and update local state.
  /// Retries once on failure before marking as failed.
  Future<void> refreshDailyUsage() async {
    if (_subscriptionTier == SubscriptionTier.none) {
      // No server tracking for non-subscribers; reset locally.
      if (_dailyAnalysisUsed != 0 || !_dailyUsageLoaded || _dailyUsageFailed) {
        _dailyAnalysisUsed = 0;
        _dailyUsageFailed = false;
        _markDailyUsageLoaded();
        notifyListeners();
      }
      return;
    }

    if (_dailyUsageRefreshInFlight) return;
    _dailyUsageRefreshInFlight = true;

    try {
      DailyUsage? usage;
      // Try up to 2 attempts.
      for (int attempt = 0; attempt < 2; attempt++) {
        try {
          usage = await DailyUsageService.fetchToday(_subscriptionTier);
        } catch (e) {
          debugPrint('refreshDailyUsage attempt ${attempt + 1} failed: $e');
          usage = null;
        }
        if (usage != null) break;
        if (attempt == 0) {
          await Future.delayed(const Duration(milliseconds: 600));
        }
      }

      if (usage != null) {
        _dailyAnalysisUsed = usage.count;
        _dailyUsageFailed = false;
        _markDailyUsageLoaded();
      } else {
        _dailyUsageFailed = true;
        // Do not mark loaded on failure; UI keys off dailyUsageFailed instead.
      }
      notifyListeners();
    } finally {
      _dailyUsageRefreshInFlight = false;
    }
  }

  /// Increment usage on the server and update local state.
  /// Returns the new count (or null on failure).
  Future<int?> recordAnalysisUsed() async {
    if (_subscriptionTier == SubscriptionTier.none) return null;
    final newCount = await DailyUsageService.incrementToday(_subscriptionTier);
    if (newCount != null) {
      _dailyAnalysisUsed = newCount;
      notifyListeners();
    }
    return newCount;
  }

  /// Returns true if the user has remaining analyses for today.
  bool get hasDailyAnalysesRemaining =>
      _subscriptionTier != SubscriptionTier.none &&
      _dailyAnalysisUsed < dailyAnalysisTotal;

  /// Get the selected video asset (from photo library)
  AssetEntity? get selectedVideoAsset => _selectedVideoAsset;

  /// Set the selected video asset
  set selectedVideoAsset(AssetEntity? asset) {
    _selectedVideoAsset = asset;
    notifyListeners();
  }

  /// Clear the selected video
  void clearSelectedVideo() {
    _selectedVideoAsset = null;
    notifyListeners();
  }

  /// Check if a video is selected
  bool get hasSelectedVideo => _selectedVideoAsset != null;
  
  /// Get the latest analysis result
  AnalysisResult? get latestAnalysisResult => _latestAnalysisResult;
  
  /// Whether viewing a saved history result (static mode)
  bool get isViewingFromHistory => _isViewingFromHistory;
  
  /// Set the latest analysis result
  void setLatestAnalysisResult(AnalysisResult result, {bool fromHistory = false}) {
    _latestAnalysisResult = result;
    _isViewingFromHistory = fromHistory;
    notifyListeners();
  }
  
  /// Clear the latest analysis result
  void clearLatestAnalysisResult() {
    _latestAnalysisResult = null;
    _isViewingFromHistory = false;
    notifyListeners();
  }
  
  /// Get cached history list
  List<AnalysisResult> get history => _history;
  
  /// Whether history has been loaded at least once
  bool get historyLoaded => _historyLoaded;
  
  /// Load history from storage (call on app start/shell init)
  Future<void> loadHistory() async {
    try {
      _history = await AnalysisService.getHistory();
      _historyLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('AppState: Failed to load history: $e');
      _historyLoaded = true;
      notifyListeners();
    }
  }
  
  /// Refresh history (call after new analysis)
  Future<void> refreshHistory() async {
    try {
      _history = await AnalysisService.getHistory();
      notifyListeners();
    } catch (e) {
      debugPrint('AppState: Failed to refresh history: $e');
    }
  }
  
  /// Remove item from history
  void removeFromHistory(String id) {
    _history.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Restore an item back into the cached history list.
  ///
  /// This is mainly used for optimistic UI updates (e.g. delete) when the
  /// underlying persistence operation fails.
  void restoreHistoryItem(AnalysisResult item) {
    // Prevent duplicates
    if (_history.any((h) => h.id == item.id)) return;

    // Keep newest-first ordering (same as AnalysisService.saveToHistory).
    final insertAt = _history.indexWhere((h) => h.createdAt.isBefore(item.createdAt));
    if (insertAt == -1) {
      _history.add(item);
    } else {
      _history.insert(insertAt, item);
    }
    notifyListeners();
  }
}

/// Provider widget to make AppState available throughout the widget tree
class AppStateProvider extends InheritedNotifier<AppState> {
  const AppStateProvider({
    super.key,
    required AppState appState,
    required super.child,
  }) : super(notifier: appState);

  /// Get the AppState from the widget tree
  static AppState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }

  /// Get the AppState without listening to changes
  static AppState read(BuildContext context) {
    final provider =
        context.getInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!.notifier!;
  }
}
