import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';
import 'package:takopos/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:takopos/features/catalog/presentation/widgets/product_tile.dart';
import 'package:takopos/features/catalog/presentation/widgets/variant_selector_dialog.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';

/// Grid of products for selection
class ProductGrid extends ConsumerWidget {
  const ProductGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchActive = ref.watch(isSearchActiveProvider);
    final products = isSearchActive
        ? ref.watch(searchResultsProvider)
        : ref.watch(productsProvider);

    if (products.isEmpty) {
      return _EmptyState(isSearch: isSearchActive);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate number of columns based on available width
        // Minimum tile width of 120, aiming for 4-6 columns on tablets
        final columns = (constraints.maxWidth / 140).floor().clamp(2, 6);

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.md),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.gridSpacing,
            mainAxisSpacing: AppSpacing.gridSpacing,
            childAspectRatio: 0.85, // Slightly taller than wide
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductTile(
              product: product,
              onTap: () => _handleProductTap(context, ref, product),
            );
          },
        );
      },
    );
  }

  void _handleProductTap(
    BuildContext context,
    WidgetRef ref,
    ProductEntity product,
  ) {
    // If product has variants or modifiers, show selection dialog
    if (product.hasVariants || product.hasModifiers) {
      showDialog(
        context: context,
        builder: (context) => VariantSelectorDialog(product: product),
      );
    } else {
      // Add directly to cart
      ref.read(cartProvider.notifier).addProduct(product);
      _showAddedFeedback(context, product.name);
    }
  }

  void _showAddedFeedback(BuildContext context, String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $productName to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;

  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            isSearch ? 'No products found' : 'No products in this category',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (isSearch) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try a different search term',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
