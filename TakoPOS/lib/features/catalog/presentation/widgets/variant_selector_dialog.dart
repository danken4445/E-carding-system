import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/utils/money.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';

/// Dialog for selecting product variants and modifiers
class VariantSelectorDialog extends ConsumerStatefulWidget {
  final ProductEntity product;

  const VariantSelectorDialog({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<VariantSelectorDialog> createState() =>
      _VariantSelectorDialogState();
}

class _VariantSelectorDialogState
    extends ConsumerState<VariantSelectorDialog> {
  VariantEntity? _selectedVariant;
  final Map<String, List<ModifierEntity>> _selectedModifiers = {};
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Pre-select first variant if available
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
    // Pre-select default modifiers
    for (final group in widget.product.modifierGroups) {
      final defaults =
          group.modifiers.where((m) => m.isDefault).toList();
      if (defaults.isNotEmpty) {
        _selectedModifiers[group.id] = defaults;
      }
    }
  }

  Money get _totalPrice {
    Money price = widget.product.basePrice;
    if (_selectedVariant != null) {
      price = price + _selectedVariant!.priceAdjustment;
    }
    for (final modifiers in _selectedModifiers.values) {
      for (final modifier in modifiers) {
        price = price + modifier.priceAdjustment;
      }
    }
    return price * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            _buildHeader(),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Variants
                    if (widget.product.hasVariants) ...[
                      _buildVariantSection(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    // Modifiers
                    for (final group in widget.product.modifierGroups) ...[
                      _buildModifierGroup(group),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),
            // Footer with quantity and add button
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: AppTextStyles.headline3.copyWith(
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Starting at ${widget.product.basePrice.format()}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.textOnPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildVariantSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Size', style: AppTextStyles.headline3),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.product.variants.map((variant) {
            final isSelected = _selectedVariant?.id == variant.id;
            return _SelectableChip(
              label: variant.name,
              sublabel: variant.priceAdjustment.isPositive
                  ? '+${variant.priceAdjustment.format()}'
                  : null,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _selectedVariant = variant;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModifierGroup(ModifierGroupEntity group) {
    final selectedInGroup = _selectedModifiers[group.id] ?? [];
    final isRequired = group.isRequired;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(group.name, style: AppTextStyles.headline3),
            ),
            if (isRequired)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  'Required',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        if (group.allowsMultiple)
          Text(
            'Select up to ${group.maxSelections}',
            style: AppTextStyles.bodySmall,
          ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: group.modifiers.map((modifier) {
            final isSelected = selectedInGroup.any((m) => m.id == modifier.id);
            return _SelectableChip(
              label: modifier.name,
              sublabel: modifier.priceAdjustment.isPositive
                  ? '+${modifier.priceAdjustment.format()}'
                  : null,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (group.allowsMultiple) {
                    // Multi-select
                    final current =
                        List<ModifierEntity>.from(selectedInGroup);
                    if (isSelected) {
                      current.removeWhere((m) => m.id == modifier.id);
                    } else if (current.length < group.maxSelections) {
                      current.add(modifier);
                    }
                    _selectedModifiers[group.id] = current;
                  } else {
                    // Single select (radio)
                    _selectedModifiers[group.id] = [modifier];
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooter() {
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
          // Quantity selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '$_quantity',
                style: AppTextStyles.headline2,
              ),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
                color: AppColors.primary,
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Add to cart button
          SizedBox(
            width: double.infinity,
            height: AppSizing.buttonHeightLarge,
            child: ElevatedButton(
              onPressed: _canAdd ? _addToCart : null,
              child: Text(
                'Add to Cart - ${_totalPrice.format()}',
                style: AppTextStyles.buttonLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canAdd {
    // Check required variant
    if (widget.product.hasVariants && _selectedVariant == null) {
      return false;
    }
    // Check required modifier groups
    for (final group in widget.product.modifierGroups) {
      if (group.isRequired) {
        final selected = _selectedModifiers[group.id] ?? [];
        if (selected.length < group.minSelections) {
          return false;
        }
      }
    }
    return true;
  }

  void _addToCart() {
    final allModifiers = _selectedModifiers.values.expand((m) => m).toList();

    ref.read(cartProvider.notifier).addProduct(
      widget.product,
      variant: _selectedVariant,
      modifiers: allModifiers,
      quantity: _quantity,
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.product.name} to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final String? sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    this.sublabel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
              if (sublabel != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppColors.textOnPrimary.withValues(alpha: 0.7)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
