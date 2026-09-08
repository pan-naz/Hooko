import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooko_v20/theme.dart';
import 'package:hooko_v20/nav.dart';
import 'package:hooko_v20/utils/responsive_wrapper.dart';
import 'package:hooko_v20/utils/orientation_manager.dart';
import 'package:hooko_v20/utils/svg_precache.dart';
import 'package:hooko_v20/utils/image_precache.dart';

import 'package:hooko_v20/supabase/supabase_config.dart';
import 'package:hooko_v20/services/user_service.dart';
import 'package:hooko_v20/services/demo_video_preloader.dart';
import 'package:hooko_v20/services/active_operations_manager.dart';
import 'package:hooko_v20/services/revenuecat_service.dart';
import 'package:hooko_v20/state/app_state.dart';

void main() async {
WidgetsFlutterBinding.ensureInitialized();

// Kick off ALL asset precaches as early as possible (fire-and-forget),
// before any awaits. They run in parallel with cleanup, Supabase init,
// and the splash animations. UI is never blocked on caching.
unawaited(precacheSvgAssets());
unawaited(precacheBackgroundImages());
unawaited(DemoVideoPreloader.instance.preload());

// CRITICAL: Clean up any lingering operations from previous session (hot restart)
// This stops video players and cancels analysis that might be running in background
await ActiveOperationsManager.instance.cleanupAll();

// Note: Orientation is managed dynamically by OrientationManager
// Tablets can rotate, phones stay portrait-only



// Ensure status bar content is visible on dark backgrounds (iOS & Android)
const overlay = SystemUiOverlayStyle(
statusBarColor: Colors.transparent,
statusBarIconBrightness: Brightness.light, // Android icons
statusBarBrightness: Brightness.dark, // iOS text/icons
);
SystemChrome.setSystemUIOverlayStyle(overlay);

await SupabaseConfig.initialize();
// Anonymous auth is handled in SupabaseConfig.initialize() with retry logic

// Listen to auth state changes and create/update user profiles
// Skip for anonymous users - they don't need a profile
SupabaseConfig.auth.onAuthStateChange.listen((data) async {
final user = data.session?.user;
if (user != null && !user.isAnonymous) {
try {
await UserService.upsertUser(user);
debugPrint('User profile synced for: ${user.email}');
} catch (e) {
debugPrint('Error syncing user profile: $e');
}
} else if (user != null && user.isAnonymous) {
debugPrint('Anonymous user signed in - skipping profile sync');
}
});

final appState = AppState();
// Start listening for connectivity changes so a failed daily-usage fetch
// can auto-retry once the network comes back.
appState.initConnectivityWatcher();
// Fire-and-forget: warm up history (incl. base64 thumbnails) so the
// History screen has data the moment it's opened.
unawaited(appState.loadHistory());

// Fire-and-forget: initialize RevenueCat (skipped automatically on web).
unawaited(RevenueCatService.initialize(appState));

runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
final AppState appState;

const MyApp({super.key, required this.appState});

@override
Widget build(BuildContext context) => AppStateProvider(
appState: appState,
child: OrientationManager(
  child: MaterialApp.router(
title: 'Hooko',
debugShowCheckedModeBanner: false,
theme: lightTheme,
darkTheme: darkTheme,
themeMode: ThemeMode.system,
routerConfig: AppRouter.router,
builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
value: const SystemUiOverlayStyle(
statusBarColor: Colors.transparent,
statusBarIconBrightness: Brightness.light, // Android
statusBarBrightness: Brightness.dark, // iOS (light content)
),
child: _GlobalGradientBackground(
child: ResponsiveWrapper(
// Uses AppBreakpoints.maxContentWidth by default (600)
child: child ?? const SizedBox.shrink(),
),
),
),
),
),
);
}

/// Global background that persists across all screens.
///
/// Animated gradient is NOT global - it's added locally only to:
/// - SplashScreen
/// - OnboardingScreen 1, 2, 3
/// - AnalyzingScreen
///
/// This prevents unnecessary GPU load on screens that don't need animation.
class _GlobalGradientBackground extends StatelessWidget {
final Widget child;

const _GlobalGradientBackground({required this.child});

/// Global app background color - used by all screens
static const Color backgroundColor = Color(0xFF110A1D);

@override
Widget build(BuildContext context) => Container(
color: backgroundColor,
child: child,
);
}
