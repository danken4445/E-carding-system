import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/auth/presentation/providers/auth_provider.dart';
import 'package:takopos/features/auth/presentation/providers/permissions_provider.dart';
import 'package:takopos/features/cms/presentation/providers/shop_settings_provider.dart';
import 'package:takopos/main.dart';

/// CMS Dashboard screen - main hub for content management
class CMSHomeScreen extends ConsumerWidget {
  const CMSHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopSettings = ref.watch(currentShopSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync with server',
            onPressed: () {
              // TODO: Trigger manual sync
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Syncing...')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop Name Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: Color(shopSettings.primaryColorValue).withOpacity(0.1),
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: Color(shopSettings.primaryColorValue).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(shopSettings.primaryColorValue),
                    child: Text(
                      shopSettings.businessName.isNotEmpty
                          ? shopSettings.businessName[0].toUpperCase()
                          : 'S',
                      style: AppTextStyles.headline2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopSettings.businessName,
                          style: AppTextStyles.headline3,
                        ),
                        if (shopSettings.address != null)
                          Text(
                            shopSettings.address!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // CMS Menu Grid
            Expanded(
              child: _CMSMenuGrid(),
            ),
          ],
        ),
      ),
    );
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
}

class _CMSMenuGrid extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManageShopSettings = ref.watch(canManageShopSettingsProvider);
    final canManageProducts = ref.watch(canManageProductsProvider);

    return FutureBuilder(
      future: _loadCounts(),
      builder: (context, snapshot) {
        final counts = snapshot.data ??
            {'products': 0, 'categories': 0, 'modifierGroups': 0};

        // Build menu items based on permissions
        final menuItems = <Widget>[];

        // Shop Settings (owners only)
        if (canManageShopSettings) {
          menuItems.add(
            _CMSMenuCard(
              icon: Icons.store,
              title: 'Shop Settings',
              subtitle: 'Theme, branding, receipts',
              color: AppColors.primary,
              onTap: () => context.go('/cms/settings'),
            ),
          );
        }

        // Products, Categories, and Add-ons (managers and owners)
        if (canManageProducts) {
          menuItems.addAll([
            _CMSMenuCard(
              icon: Icons.inventory_2,
              title: 'Products',
              subtitle: '${counts['products']} items',
              color: AppColors.categoryColors[0],
              onTap: () => context.go('/cms/products'),
            ),
            _CMSMenuCard(
              icon: Icons.category,
              title: 'Categories',
              subtitle: '${counts['categories']} categories',
              color: AppColors.categoryColors[1],
              onTap: () => context.go('/cms/categories'),
            ),
            _CMSMenuCard(
              icon: Icons.add_circle_outline,
              title: 'Add-ons',
              subtitle: '${counts['modifierGroups']} groups',
              color: AppColors.categoryColors[2],
              onTap: () => context.go('/cms/modifiers'),
            ),
          ]);
        }

        // If no permissions, show a message
        if (menuItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No Access',
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'You don\'t have permission to access CMS features.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.2,
          children: menuItems,
        );
      },
    );
  }

  Future<Map<String, int>> _loadCounts() async {
    final products = await database.getAllProducts();
    final categories = await database.getAllCategories();
    final modifierGroups = await database.getAllModifierGroups();

    return {
      'products': products.length,
      'categories': categories.length,
      'modifierGroups': modifierGroups.length,
    };
  }
}

class _CMSMenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CMSMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
