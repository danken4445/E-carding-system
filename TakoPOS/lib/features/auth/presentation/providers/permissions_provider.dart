import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/features/auth/domain/entities/user_entity.dart';
import 'package:takopos/features/auth/presentation/providers/auth_provider.dart';

/// Permissions notifier for managing role-based access control
class PermissionsNotifier extends StateNotifier<UserRole?> {
  final Ref _ref;

  PermissionsNotifier(this._ref) : super(null) {
    // Watch for user changes and update role
    _ref.listen(
      currentUserProvider,
      (previous, next) {
        state = next?.role;
      },
    );
  }

  /// Can access CMS (content management system)
  bool get canAccessCMS => state?.canAccessCMS ?? false;

  /// Can manage products and categories
  bool get canManageProducts => state?.canManageProducts ?? false;

  /// Can manage users in the shop
  bool get canManageUsers => state?.canManageUsers ?? false;

  /// Can manage shop settings
  bool get canManageShopSettings => state?.canManageShopSettings ?? false;

  /// Can apply discounts
  bool get canApplyDiscounts => state?.canApplyDiscounts ?? false;

  /// Can void transactions
  bool get canVoidTransactions => state?.canVoidTransactions ?? false;

  /// Can view reports
  bool get canViewReports => state?.canViewReports ?? false;
}

/// Provider for permissions state
final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, UserRole?>((ref) {
  return PermissionsNotifier(ref);
});

/// Convenience providers for specific permissions

/// Can access CMS
final canAccessCMSProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canAccessCMS;
});

/// Can manage products
final canManageProductsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canManageProducts;
});

/// Can manage users
final canManageUsersProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canManageUsers;
});

/// Can manage shop settings
final canManageShopSettingsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canManageShopSettings;
});

/// Can apply discounts
final canApplyDiscountsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canApplyDiscounts;
});

/// Can void transactions
final canVoidTransactionsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canVoidTransactions;
});

/// Can view reports
final canViewReportsProvider = Provider<bool>((ref) {
  return ref.watch(permissionsProvider.notifier).canViewReports;
});
