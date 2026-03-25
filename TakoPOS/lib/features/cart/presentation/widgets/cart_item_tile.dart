import 'package:flutter/material.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/cart/domain/entities/cart_entities.dart';

/// Individual cart item row with quantity controls
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback? onApplyDiscount; // Made nullable for permission-based display

  const CartItemTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    this.onApplyDiscount, // No longer required
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.md),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) => onRemove(),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.cartItemBackground,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content row
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          item.displayName,
                          style: AppTextStyles.cartItemName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Modifiers
                        if (item.selectedModifiers.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            item.modifierSummary,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Notes
                        if (item.notes != null && item.notes!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.note,
                                size: 12,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.notes!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        // Unit price
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${item.unitPrice.format()} each',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Quantity and total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Total
                      Text(
                        item.total.format(),
                        style: AppTextStyles.productPrice,
                      ),
                      // Line discount
                      if (item.lineDiscount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '-${item.lineDiscountAmount.format()}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.success,
                            fontSize: 11,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      // Quantity controls
                      _QuantityControls(
                        quantity: item.quantity,
                        onChanged: onQuantityChanged,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  // Discount button (only show if permission allows)
                  if (onApplyDiscount != null) ...[
                    if (item.lineDiscount == null)
                      _ActionButton(
                        icon: Icons.discount_outlined,
                        label: 'Discount',
                        onTap: onApplyDiscount!,
                      )
                    else
                      _ActionButton(
                        icon: Icons.cancel,
                        label: 'Remove Discount',
                        onTap: onApplyDiscount!,
                        color: AppColors.success,
                      ),
                  ],
                  const Spacer(),
                  // Remove button
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'Remove',
                    onTap: onRemove,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;

  const _QuantityControls({
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuantityButton(
            icon: Icons.remove,
            onTap: quantity > 1 ? () => onChanged(quantity - 1) : null,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              '$quantity',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _QuantityButton(
            icon: Icons.add,
            onTap: () => onChanged(quantity + 1),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? AppColors.primary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(
        icon,
        size: 16,
        color: color ?? AppColors.textSecondary,
      ),
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color ?? AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
    );
  }
}
