import 'package:equatable/equatable.dart';
import 'package:takopos/features/auth/domain/entities/user_entity.dart';
import 'package:takopos/features/auth/domain/entities/shop_entity.dart';

/// Authentication status
enum AuthStatus {
  initial, // Initial state before checking auth
  loading, // Loading user data
  authenticated, // User is logged in
  unauthenticated, // User is not logged in
  error, // Error occurred during auth
}

/// Authentication state
class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final ShopEntity? shop;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.shop,
    this.errorMessage,
  });

  /// Initial state
  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        shop = null,
        errorMessage = null;

  /// Loading state
  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        shop = null,
        errorMessage = null;

  /// Authenticated state
  const AuthState.authenticated({
    required this.user,
    required this.shop,
  })  : status = AuthStatus.authenticated,
        errorMessage = null;

  /// Unauthenticated state
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        shop = null,
        errorMessage = null;

  /// Error state
  const AuthState.error(this.errorMessage)
      : status = AuthStatus.error,
        user = null,
        shop = null;

  /// Check if user is authenticated
  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// Check if loading
  bool get isLoading => status == AuthStatus.loading;

  /// Check if unauthenticated
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;

  /// Check if error
  bool get hasError => status == AuthStatus.error;

  /// Copy with modifications
  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    ShopEntity? shop,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      shop: shop ?? this.shop,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, user, shop, errorMessage];

  @override
  String toString() {
    return 'AuthState(status: ${status.name}, user: ${user?.email}, shop: ${shop?.name}, error: $errorMessage)';
  }
}
