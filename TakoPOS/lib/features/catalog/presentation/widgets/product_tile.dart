import 'package:flutter/material.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';

/// Individual product tile in the grid
class ProductTile extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;

  const ProductTile({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadius.cardRadius,
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product image or placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: product.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _buildPlaceholder(),
                          ),
                        )
                      : _buildPlaceholder(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Product name
              Text(
                product.name,
                style: AppTextStyles.productName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              // Price
              Text(
                product.basePrice.format(),
                style: AppTextStyles.productPrice,
                textAlign: TextAlign.center,
              ),
              // Indicators (variants, modifiers, low stock)
              if (_hasIndicators) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildIndicators(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.local_cafe,
        size: 36,
        color: AppColors.textSecondary.withValues(alpha: 0.5),
      ),
    );
  }

  bool get _hasIndicators =>
      product.hasVariants || product.hasModifiers || product.isLowStock;

  Widget _buildIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (product.hasVariants)
          _IndicatorChip(
            icon: Icons.style,
            tooltip: 'Has variants',
          ),
        if (product.hasModifiers)
          _IndicatorChip(
            icon: Icons.tune,
            tooltip: 'Customizable',
          ),
        if (product.isLowStock)
          _IndicatorChip(
            icon: Icons.warning,
            tooltip: 'Low stock',
            color: AppColors.warning,
          ),
        if (product.isOutOfStock)
          _IndicatorChip(
            icon: Icons.block,
            tooltip: 'Out of stock',
            color: AppColors.error,
          ),
      ],
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color? color;

  const _IndicatorChip({
    required this.icon,
    required this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Icon(
          icon,
          size: 14,
          color: color ?? AppColors.textSecondary,
        ),
      ),
    );
  }
}
