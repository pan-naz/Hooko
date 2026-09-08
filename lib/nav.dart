import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooko_v20/screens/home_screen.dart';
import 'package:hooko_v20/screens/onboarding_screen.dart';
import 'package:hooko_v20/screens/onboarding_screen_2.dart';
import 'package:hooko_v20/screens/onboarding_screen_3.dart';
import 'package:hooko_v20/screens/demo_screen.dart';
import 'package:hooko_v20/screens/uploaded_video_screen.dart';
import 'package:hooko_v20/screens/demo_screen_2.dart';
import 'package:hooko_v20/screens/demo_result.dart';
import 'package:hooko_v20/screens/splash_screen.dart';
import 'package:hooko_v20/screens/history_screen.dart';
import 'package:hooko_v20/screens/profile_screen.dart';
import 'package:hooko_v20/screens/analyzing_screen.dart';
import 'package:hooko_v20/screens/analysis_result_screen.dart';
import 'package:hooko_v20/components/main_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

/// GoRouter configuration for app navigation
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == AppRoutes.splash;
      
      // Allow splash to show first - it handles navigation logic
      if (isOnSplash) return null;
      
      // No automatic redirects - let splash screen handle the logic
      // based on onboarding completion status
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) {
          final fromHeights = state.extra as List<double>?;
          return NoTransitionPage(
            child: OnboardingScreen(fromHeights: fromHeights),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding2,
        name: 'onboarding2',
        pageBuilder: (context, state) {
          final fromHeights = state.extra as List<double>?;
          return NoTransitionPage(
            child: OnboardingScreen2(fromHeights: fromHeights),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding3,
        name: 'onboarding3',
        pageBuilder: (context, state) {
          final fromHeights = state.extra as List<double>?;
          return NoTransitionPage(
            child: OnboardingScreen3(fromHeights: fromHeights),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.demo,
        name: 'demo',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: DemoScreen(),
        ),
      ),
      // ShellRoute keeps the MainShell (with navbar) persistent across these routes
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          key: state.pageKey,
          child: MainShell(child: child),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.history,
            name: 'history',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HistoryScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.uploadedVideo,
        name: 'uploadedVideo',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const UploadedVideoScreen(),
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // When AnalyzingScreen comes on top, this screen scales down
            final scaleAnimation = Tween<double>(
              begin: 1.0,
              end: 0.92,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ));
            
            final radiusAnimation = Tween<double>(
              begin: 0.0,
              end: 40.0,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ));
            
            // Entry fade
            final fadeIn = FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
            
            return AnimatedBuilder(
              animation: secondaryAnimation,
              builder: (context, _) {
                return Transform.scale(
                  scale: scaleAnimation.value,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radiusAnimation.value),
                    child: fadeIn,
                  ),
                );
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.analyzing,
        name: 'analyzing',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnalyzingScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // When AnalysisResult comes on top, this screen scales down (like demo2)
            final scaleAnimation = Tween<double>(
              begin: 1.0,
              end: 0.92,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ));
            
            final radiusAnimation = Tween<double>(
              begin: 0.0,
              end: 40.0,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInOutCubic,
            ));
            
            // Slide up from bottom on enter
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved);
            
            return AnimatedBuilder(
              animation: secondaryAnimation,
              builder: (context, _) {
                return Transform.scale(
                  scale: scaleAnimation.value,
                  alignment: Alignment.topCenter,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radiusAnimation.value),
                    child: SlideTransition(position: slideAnimation, child: child),
                  ),
                );
              },
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.analysisResult,
        name: 'analysisResult',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AnalysisResultScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up from bottom on enter; slide down on exit (same as demoResult)
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved);
            return SlideTransition(position: slideAnimation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.demo2,
        name: 'demo2',
        pageBuilder: (context, state) {
          final preloaded = state.extra as VideoPlayerController?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: DemoScreen2(preloadedController: preloaded),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              // When DemoResult comes on top, this screen scales down
              final scaleAnimation = Tween<double>(
                begin: 1.0,
                end: 0.92,
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ));
              
              final radiusAnimation = Tween<double>(
                begin: 0.0,
                end: 40.0,
              ).animate(CurvedAnimation(
                parent: secondaryAnimation,
                curve: Curves.easeInOutCubic,
              ));
              
              return AnimatedBuilder(
                animation: secondaryAnimation,
                builder: (context, _) {
                  return Transform.scale(
                    scale: scaleAnimation.value,
                    alignment: Alignment.topCenter,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(radiusAnimation.value),
                      child: child,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.demoResult,
        name: 'demoResult',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DemoResult(),
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Slide up from bottom on enter; instant exit (no reverse animation)
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved);
            return SlideTransition(position: slideAnimation, child: child);
          },
        ),
      ),
    ],
  );
}

/// Route path constants
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboarding2 = '/onboarding2';
  static const String onboarding3 = '/onboarding3';
  static const String demo = '/demo';
  static const String home = '/home';
  static const String history = '/history';
  static const String profile = '/profile';
  static const String uploadedVideo = '/uploaded-video';
  static const String analyzing = '/analyzing';
  static const String analysisResult = '/analysis-result';
  static const String demo2 = '/demo2';
  static const String demoResult = '/demo-result';
}

/// Helper class to convert auth state stream to ChangeNotifier
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
