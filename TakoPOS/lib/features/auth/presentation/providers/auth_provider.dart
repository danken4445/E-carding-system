import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takopos/features/auth/domain/entities/auth_state.dart' as app_auth;
import 'package:takopos/features/auth/domain/entities/user_entity.dart';
import 'package:takopos/features/auth/domain/entities/shop_entity.dart';
import 'package:takopos/main.dart';

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<app_auth.AuthState> {
  final SupabaseClient _supabase;

  AuthNotifier(this._supabase) : super(const app_auth.AuthState.initial()) {
    _initialize();
  }

  /// Initialize auth state and listen to auth changes
  void _initialize() {
    // Listen to auth state changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _loadUserData();
      } else {
        state = const app_auth.AuthState.unauthenticated();
        // Clear shop context from database
        database.setCurrentShopId(null);
      }
    });

    // Check initial session
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _loadUserData();
    } else {
      state = const app_auth.AuthState.unauthenticated();
    }
  }

  /// Load user and shop data from Supabase
  Future<void> _loadUserData() async {
    try {
      state = const app_auth.AuthState.loading();

      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        state = const app_auth.AuthState.unauthenticated();
        return;
      }

      // Fetch user from users table
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('auth_user_id', authUser.id)
          .single();

      final user = UserEntity.fromJson(userResponse);

      // Fetch shop data
      final shopResponse =
          await _supabase.from('shops').select().eq('id', user.shopId).single();

      final shop = ShopEntity.fromJson(shopResponse);

      // Set shop context in local database
      database.setCurrentShopId(shop.id);

      state = app_auth.AuthState.authenticated(user: user, shop: shop);
    } catch (e, stackTrace) {
      print('Error loading user data: $e');
      print('Stack trace: $stackTrace');

      if (e.toString().contains('JWT')) {
        // Token expired or invalid, sign out
        await signOut();
      } else {
        state = app_auth.AuthState.error(e.toString());
      }
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      state = const app_auth.AuthState.loading();

      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // _loadUserData will be called by auth state listener
    } catch (e) {
      print('Sign in error: $e');
      state = app_auth.AuthState.error(_formatAuthError(e));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      state = const app_auth.AuthState.unauthenticated();
      database.setCurrentShopId(null);
    } catch (e) {
      print('Sign out error: $e');
      state = app_auth.AuthState.error(e.toString());
    }
  }

  /// Refresh auth state (useful after network reconnection)
  Future<void> refresh() async {
    if (state.isAuthenticated) {
      await _loadUserData();
    }
  }

  /// Format authentication errors for user display
  String _formatAuthError(Object error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('invalid login credentials') ||
        errorStr.contains('invalid email or password')) {
      return 'Invalid email or password';
    } else if (errorStr.contains('email not confirmed')) {
      return 'Please confirm your email before signing in';
    } else if (errorStr.contains('network')) {
      return 'Network error. Please check your connection';
    } else if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else {
      return 'Sign in failed. Please try again';
    }
  }
}

/// Provider for auth state
final authProvider = StateNotifierProvider<AuthNotifier, app_auth.AuthState>((ref) {
  return AuthNotifier(Supabase.instance.client);
});

/// Convenience provider for current user
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for current shop
final currentShopProvider = Provider<ShopEntity?>((ref) {
  return ref.watch(authProvider).shop;
});

/// Convenience provider for authentication status
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Convenience provider for user role
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  return ref.watch(authProvider).user?.role;
});
