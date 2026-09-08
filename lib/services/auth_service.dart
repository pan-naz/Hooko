import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Sign in anonymously - creates a temporary user session
  /// Perfect for apps without login that use RevenueCat for user management
  static Future<void> signInAnonymously() async {
    // Skip if already signed in
    if (_supabase.auth.currentUser != null) {
      debugPrint('AuthService: User already signed in (${_supabase.auth.currentUser!.isAnonymous ? "anonymous" : "registered"})');
      return;
    }

    try {
      final response = await _supabase.auth.signInAnonymously();
      if (response.user != null) {
        debugPrint('AuthService: Anonymous sign-in successful (uid: ${response.user!.id})');
      } else {
        debugPrint('AuthService: Anonymous sign-in returned no user');
      }
    } catch (e) {
      debugPrint('AuthService: Anonymous sign-in failed: $e');
      rethrow;
    }
  }

  /// Check if user has a valid session
  static bool get hasValidSession => _supabase.auth.currentSession != null;

  /// Get current access token for API calls
  static String? get accessToken => _supabase.auth.currentSession?.accessToken;

  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  static User? get currentUser => _supabase.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      _supabase.auth.onAuthStateChange;
}
