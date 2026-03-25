import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/auth/domain/entities/auth_state.dart' as app_auth;
import 'package:takopos/features/auth/presentation/providers/auth_provider.dart';
import 'package:takopos/features/auth/presentation/providers/permissions_provider.dart';
import 'package:takopos/features/auth/presentation/screens/login_screen.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';
import 'package:takopos/features/catalog/presentation/screens/pos_screen.dart';
import 'package:takopos/features/catalog/presentation/screens/barcode_scanner_screen.dart';
import 'package:takopos/features/checkout/presentation/screens/cash_payment_screen.dart';
import 'package:takopos/features/cms/presentation/screens/cms_home_screen.dart';
import 'package:takopos/features/cms/presentation/screens/shop_settings_screen.dart';
import 'package:takopos/features/cms/presentation/screens/category_list_screen.dart';
import 'package:takopos/features/cms/presentation/screens/product_list_screen.dart';
import 'package:takopos/features/cms/presentation/screens/product_edit_screen.dart';
import 'package:takopos/features/cms/presentation/screens/modifier_list_screen.dart';
import 'package:takopos/features/cms/presentation/screens/modifier_edit_screen.dart';

/// Router provider with auth guards
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      final isInitial = authState.status == app_auth.AuthStatus.initial;
      final isLoggingIn = state.matchedLocation == '/login';

      // Don't redirect while loading or initializing
      if (isLoading || isInitial) {
        return null;
      }

      // If not authenticated and not on login page, redirect to login
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      // If authenticated and on login page, redirect to home
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      // Check CMS access permissions
      if (state.matchedLocation.startsWith('/cms') && isAuthenticated) {
        final canAccessCMS = ref.read(canAccessCMSProvider);
        if (!canAccessCMS) {
          return '/'; // Redirect to POS if no CMS access
        }

        // Check shop settings permission
        if (state.matchedLocation == '/cms/settings') {
          final canManageSettings = ref.read(canManageShopSettingsProvider);
          if (!canManageSettings) {
            return '/cms'; // Redirect to CMS home if no settings access
          }
        }
      }

      // No redirect needed
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        name: 'pos',
        builder: (context, state) => const PosScreen(),
      ),
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/checkout',
        name: 'checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/checkout/cash',
        name: 'cash-payment',
        builder: (context, state) => const CashPaymentScreen(),
      ),
      // CMS Routes - Protected by role (checked in redirect)
      GoRoute(
        path: '/cms',
        name: 'cms',
        builder: (context, state) => const CMSHomeScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            name: 'cms-settings',
            builder: (context, state) => const ShopSettingsScreen(),
          ),
          GoRoute(
            path: 'categories',
            name: 'cms-categories',
            builder: (context, state) => const CategoryListScreen(),
          ),
          GoRoute(
            path: 'products',
            name: 'cms-products',
            builder: (context, state) => const ProductListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'cms-product-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return ProductEditScreen(
                    productId: id == 'new' ? null : id,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'modifiers',
            name: 'cms-modifiers',
            builder: (context, state) => const ModifierListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'cms-modifier-detail',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  return ModifierEditScreen(
                    groupId: id == 'new' ? null : id,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Notifier class to trigger router refresh on auth state changes
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

/// Main application widget
class TakoPOSApp extends ConsumerWidget {
  const TakoPOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'TakoPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}

/// Checkout screen with payment method selection
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    if (cart.isEmpty) {
      // Redirect to POS if cart is empty
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order summary
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Order items summary
                    _buildOrderSummary(cart),
                    const SizedBox(height: AppSpacing.lg),
                    // Totals
                    _buildTotals(cart),
                    const SizedBox(height: AppSpacing.xl),
                    // Payment methods
                    Text(
                      'Select Payment Method',
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildPaymentMethods(context, cart),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Summary', style: AppTextStyles.headline3),
              Text(
                '${cart.totalItemCount} items',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          // List of items (condensed)
          ...cart.items.map<Widget>((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      item.total.format(),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTotals(cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.2),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        children: [
          _TotalRow(label: 'Subtotal', value: cart.subtotal.format()),
          if (cart.cartDiscount != null)
            _TotalRow(
              label: 'Discount',
              value: '-${cart.discountAmount.format()}',
              valueColor: AppColors.success,
            ),
          const Divider(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headline2),
              Text(
                cart.total.format(),
                style: AppTextStyles.cartTotal.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(BuildContext context, cart) {
    return Column(
      children: [
        // Cash payment
        _PaymentMethodButton(
          icon: Icons.payments,
          label: 'Cash',
          subtitle: 'Pay with cash',
          color: AppColors.success,
          onTap: () => context.go('/checkout/cash'),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Card payment (disabled for MVP)
        _PaymentMethodButton(
          icon: Icons.credit_card,
          label: 'Card',
          subtitle: 'Coming soon',
          color: AppColors.textSecondary,
          enabled: false,
          onTap: () {},
        ),
        const SizedBox(height: AppSpacing.sm),
        // Split payment (disabled for MVP)
        _PaymentMethodButton(
          icon: Icons.call_split,
          label: 'Split Payment',
          subtitle: 'Coming soon',
          color: AppColors.textSecondary,
          enabled: false,
          onTap: () {},
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMedium),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _PaymentMethodButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.surface : AppColors.surfaceVariant,
      borderRadius: AppRadius.cardRadius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: enabled ? color : AppColors.divider,
              width: enabled ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.headline3.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: enabled ? color : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
