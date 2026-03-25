import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:takopos/features/catalog/presentation/widgets/category_tabs.dart';
import 'package:takopos/features/catalog/presentation/widgets/product_grid.dart';
import 'package:takopos/features/catalog/presentation/widgets/search_bar_widget.dart';

/// Catalog panel containing categories, search, and product grid
class CatalogPanel extends ConsumerWidget {
  const CatalogPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSearchActive = ref.watch(isSearchActiveProvider);

    return Column(
      children: [
        // Search bar
        const SearchBarWidget(),
        // Category tabs (hidden when searching)
        if (!isSearchActive) const CategoryTabs(),
        // Product grid
        const Expanded(child: ProductGrid()),
      ],
    );
  }
}
