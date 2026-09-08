import 'package:flutter/foundation.dart';
import 'package:hooko_v20/models/user_model.dart';
import 'package:hooko_v20/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static final _supabase = SupabaseConfig.client;

  /// Create or update user profile after authentication
  static Future<UserModel> upsertUser(User authUser) async {
    try {
      final userData = {
        'id': authUser.id,
        'email': authUser.email ?? '',
        'full_name': authUser.userMetadata?['full_name'] ?? authUser.userMetadata?['name'],
        'avatar_url': authUser.userMetadata?['avatar_url'] ?? authUser.userMetadata?['picture'],
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase
          .from('users')
          .upsert(userData, onConflict: 'id')
          .select()
          .single();

      debugPrint('User profile created/updated: ${result['email']}');
      return UserModel.fromJson(result);
    } catch (e) {
      debugPrint('Error upserting user: $e');
      rethrow;
    }
  }

  /// Get user profile by ID
  static Future<UserModel?> getUserById(String userId) async {
    try {
      final result = await SupabaseService.selectSingle(
        'users',
        filters: {'id': userId},
      );

      if (result == null) return null;
      return UserModel.fromJson(result);
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<UserModel> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      final result = await SupabaseService.update(
        'users',
        updates,
        filters: {'id': userId},
      );

      return UserModel.fromJson(result.first);
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  /// Delete user profile
  static Future<void> deleteUser(String userId) async {
    try {
      await SupabaseService.delete(
        'users',
        filters: {'id': userId},
      );
      debugPrint('User deleted: $userId');
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }
}
