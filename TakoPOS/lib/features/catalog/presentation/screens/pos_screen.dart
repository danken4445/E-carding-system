import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/auth/domain/entities/user_entity.dart';
import 'package:takopos/features/auth/presentation/providers/auth_provider.dart';
import 'package:takopos/features/auth/presentation/providers/permissions_provider.dart';
import 'package:takopos/features/catalog/presentation/widgets/catalog_panel.dart';
import 'package:takopos/features/cart/presentation/widgets/cart_panel.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';

/// Main POS screen with adaptive layout
/// - Tablets: Split view (catalog left, cart right)
/// - Phones: Single view with bottom sheet cart
class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

    return Scaffold(
      appBar: _buildAppBar(context),
      body: isTablet ? _buildTabletLayout() : _buildPhoneLayout(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            Icons.point_of_sale,
            color: AppColors.textOnPrimary,
          ),
          const SizedBox(width: AppSpacing.sm),
          const Text('TakoPOS'),
        ],
      ),
      actions: [
        // User profile display and menu
        Consumer(
          builder: (context, ref, child) {
            final user = ref.watch(currentUserProvider);
            final shop = ref.watch(currentShopProvider);
            final canAccessCMS = ref.watch(canAccessCMSProvider);

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Row(
                children: [
                  // Shop name
                  if (shop != null)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        shop.name,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textOnPrimary.withOpacity(0.8),
                        ),
                      ),
                    ),

                  // User info and menu
                  if (user != null)
                    PopupMenuButton<String>(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primaryLight,
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : 'U',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textOnPrimary,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(user.role).withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  user.role.name.toUpperCase(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textOnPrimary,
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        if (canAccessCMS)
                          const PopupMenuItem(
                            value: 'cms',
                            child: Row(
                              children: [
                                Icon(Icons.settings),
                                SizedBox(width: AppSpacing.sm),
                                Text('CMS / Settings'),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'sync',
                          child: Row(
                            children: [
                              Icon(
                                Icons.sync,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Text('Sync Data'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout),
                              SizedBox(width: AppSpacing.sm),
                              Text('Logout'),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'cms':
                            context.go('/cms');
                            break;
                          case 'sync':
                            // TODO: Trigger manual sync
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Syncing data...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                            break;
                          case 'logout':
                            _showLogoutDialog(context, ref);
                            break;
                        }
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  /// Get color for user role badge
  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.owner:
        return Colors.purple;
      case UserRole.manager:
        return Colors.blue;
      case UserRole.staff:
        return Colors.teal;
    }
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Catalog panel (60%)
        const Expanded(
          flex: 6,
          child: CatalogPanel(),
        ),
        // Divider
        const VerticalDivider(width: 1, thickness: 1),
        // Cart panel (40%)
        const Expanded(
          flex: 4,
          child: CartPanel(),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Stack(
      children: [
        // Catalog panel (full screen)
        const CatalogPanel(),
        // Mini cart at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _MiniCartBar(),
        ),
      ],
    );
  }
}

/// Mini cart bar for phone layout (shows total and item count)
class _MiniCartBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cart icon with badge
            Stack(
              children: [
                const Icon(Icons.shopping_cart, size: 28),
                if (cart.totalItemCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${cart.totalItemCount}',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Total
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    cart.total.format(),
                    style: AppTextStyles.headline3,
                  ),
                ],
              ),
            ),
            // View Cart / Checkout button
            ElevatedButton.icon(
              onPressed: cart.isEmpty ? null : () {
                _showCartSheet(context);
              },
              icon: const Icon(Icons.arrow_upward),
              label: Text(cart.isEmpty ? 'Cart Empty' : 'View Cart'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Cart panel
              const Expanded(child: CartPanel()),
            ],
          ),
        ),
      ),
    );
  }
}
