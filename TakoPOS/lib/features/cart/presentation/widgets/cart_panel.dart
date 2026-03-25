import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/auth/presentation/providers/permissions_provider.dart';
import 'package:takopos/features/cart/domain/entities/cart_entities.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';
import 'package:takopos/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:takopos/features/cart/presentation/widgets/discount_dialog.dart';

/// Cart panel showing current order items and totals
class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Container(
      color: AppColors.cartBackground,
      child: Column(
        children: [
          // Cart header
          _buildHeader(context, ref, cart),
          // Cart items
          Expanded(
            child: cart.isEmpty
                ? _buildEmptyCart()
                : _buildCartItems(ref, cart),
          ),
          // Totals
          _buildTotals(context, ref, cart),
          // Action buttons
          _buildActions(context, ref, cart),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Cart cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_cart),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Current Order',
              style: AppTextStyles.headline3,
            ),
          ),
          Text(
            '${cart.uniqueItemCount} items',
            style: AppTextStyles.bodySmall,
          ),
          if (cart.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClearCart(context, ref),
              tooltip: 'Clear cart',
              iconSize: 20,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cart is empty',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tap products to add them',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(WidgetRef ref, Cart cart) {
    final canApplyDiscounts = ref.watch(canApplyDiscountsProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return CartItemTile(
          item: item,
          onQuantityChanged: (qty) {
            ref.read(cartProvider.notifier).updateQuantity(item.id, qty);
          },
          onRemove: () {
            ref.read(cartProvider.notifier).removeItem(item.id);
          },
          onApplyDiscount: canApplyDiscounts
              ? () => _showLineDiscountDialog(context, ref, item)
              : null,
        );
      },
    );
  }

  Widget _buildTotals(BuildContext context, WidgetRef ref, Cart cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Column(
        children: [
          // Subtotal
          _TotalRow(
            label: 'Subtotal',
            value: cart.subtotal.format(),
          ),
          // Discount (if applied)
          if (cart.cartDiscount != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _TotalRow(
              label: 'Discount (${cart.cartDiscount!.displayValue})',
              value: '-${cart.discountAmount.format()}',
              valueColor: AppColors.success,
              onRemove: () {
                ref.read(cartProvider.notifier).removeCartDiscount();
              },
            ),
          ],
          const Divider(height: AppSpacing.md),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: AppTextStyles.headline3),
              Text(
                cart.total.format(),
                style: AppTextStyles.cartTotal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Cart cart) {
    final canApplyDiscounts = ref.watch(canApplyDiscountsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Discount button (only show if user has permission)
            if (cart.isNotEmpty &&
                cart.cartDiscount == null &&
                canApplyDiscounts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showCartDiscountDialog(context, ref),
                    icon: const Icon(Icons.discount_outlined),
                    label: const Text('Apply Discount'),
                  ),
                ),
              ),
            // Checkout button
            SizedBox(
              width: double.infinity,
              height: AppSizing.buttonHeightLarge,
              child: ElevatedButton(
                onPressed: cart.isEmpty
                    ? null
                    : () => context.go('/checkout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payments),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Checkout - ${cart.total.format()}',
                      style: AppTextStyles.buttonLarge,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
          'This will remove all items from the current order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }

  void _showCartDiscountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        title: 'Cart Discount',
        onApply: (discount) {
          ref.read(cartProvider.notifier).applyCartDiscount(discount);
        },
      ),
    );
  }

  void _showLineDiscountDialog(
    BuildContext context,
    WidgetRef ref,
    CartItem item,
  ) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        title: 'Line Discount',
        subtitle: item.displayName,
        onApply: (discount) {
          ref.read(cartProvider.notifier).applyLineDiscount(item.id, discount);
        },
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onRemove;

  const _TotalRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.bodyMedium),
            if (onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Icon(
                  Icons.cancel,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
