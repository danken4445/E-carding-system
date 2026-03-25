import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/core/utils/money.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';

/// Provider for the list of categories
final categoriesProvider = StateProvider<List<CategoryEntity>>((ref) {
  // Return mock data for now - will be replaced with database queries
  return _mockCategories;
});

/// Provider for the currently selected category
final selectedCategoryProvider = StateProvider<String?>((ref) {
  final categories = ref.watch(categoriesProvider);
  return categories.isNotEmpty ? categories.first.id : null;
});

/// Provider for products filtered by selected category
final productsProvider = Provider<List<ProductEntity>>((ref) {
  final selectedCategoryId = ref.watch(selectedCategoryProvider);

  if (selectedCategoryId == null) {
    return _mockProducts;
  }

  return _mockProducts
      .where((p) => p.categoryId == selectedCategoryId)
      .toList();
});

/// Provider for all products (unfiltered)
final allProductsProvider = StateProvider<List<ProductEntity>>((ref) {
  return _mockProducts;
});

/// Provider for product search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results
final searchResultsProvider = Provider<List<ProductEntity>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();

  if (query.isEmpty) {
    return [];
  }

  return _mockProducts.where((p) {
    return p.name.toLowerCase().contains(query) ||
        (p.barcode?.toLowerCase().contains(query) ?? false) ||
        (p.sku?.toLowerCase().contains(query) ?? false);
  }).toList();
});

/// Provider to check if search is active
final isSearchActiveProvider = Provider<bool>((ref) {
  return ref.watch(searchQueryProvider).trim().isNotEmpty;
});

// ============================================================================
// MOCK DATA FOR DEVELOPMENT
// ============================================================================

final _mockCategories = [
  CategoryEntity(
    id: 'cat-1',
    name: 'Beverages',
    sortOrder: 0,
    colorHex: '#E3F2FD',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  CategoryEntity(
    id: 'cat-2',
    name: 'Food',
    sortOrder: 1,
    colorHex: '#FFF8E1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  CategoryEntity(
    id: 'cat-3',
    name: 'Snacks',
    sortOrder: 2,
    colorHex: '#FCE4EC',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  CategoryEntity(
    id: 'cat-4',
    name: 'Merchandise',
    sortOrder: 3,
    colorHex: '#E8F5E9',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

final _mockModifiers = [
  ModifierGroupEntity(
    id: 'mod-group-1',
    name: 'Extras',
    minSelections: 0,
    maxSelections: 3,
    modifiers: [
      ModifierEntity(
        id: 'mod-1',
        groupId: 'mod-group-1',
        name: 'Extra Shot',
        priceAdjustment: Money.fromDouble(0.50),
      ),
      ModifierEntity(
        id: 'mod-2',
        groupId: 'mod-group-1',
        name: 'Whipped Cream',
        priceAdjustment: Money.fromDouble(0.30),
      ),
    ],
  ),
  ModifierGroupEntity(
    id: 'mod-group-2',
    name: 'Sweetness',
    minSelections: 1,
    maxSelections: 1,
    modifiers: [
      ModifierEntity(
        id: 'mod-3',
        groupId: 'mod-group-2',
        name: 'No Sugar',
        priceAdjustment: const Money.zero(),
      ),
      ModifierEntity(
        id: 'mod-4',
        groupId: 'mod-group-2',
        name: 'Half Sugar',
        priceAdjustment: const Money.zero(),
        isDefault: true,
      ),
      ModifierEntity(
        id: 'mod-5',
        groupId: 'mod-group-2',
        name: 'Full Sugar',
        priceAdjustment: const Money.zero(),
      ),
    ],
  ),
];

final _sizeVariants = [
  VariantEntity(
    id: 'var-small',
    productId: '',
    name: 'Small',
    priceAdjustment: const Money.zero(),
  ),
  VariantEntity(
    id: 'var-medium',
    productId: '',
    name: 'Medium',
    priceAdjustment: Money.fromDouble(0.50),
  ),
  VariantEntity(
    id: 'var-large',
    productId: '',
    name: 'Large',
    priceAdjustment: Money.fromDouble(1.00),
  ),
];

final _mockProducts = [
  // Beverages
  ProductEntity(
    id: 'prod-1',
    name: 'Espresso',
    categoryId: 'cat-1',
    basePrice: Money.fromDouble(2.50),
    barcode: '1001',
    variants: _sizeVariants.map((v) => v.copyWith(productId: 'prod-1')).toList(),
    modifierGroups: _mockModifiers,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-2',
    name: 'Cappuccino',
    categoryId: 'cat-1',
    basePrice: Money.fromDouble(3.50),
    barcode: '1002',
    variants: _sizeVariants.map((v) => v.copyWith(productId: 'prod-2')).toList(),
    modifierGroups: _mockModifiers,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-3',
    name: 'Latte',
    categoryId: 'cat-1',
    basePrice: Money.fromDouble(4.00),
    barcode: '1003',
    variants: _sizeVariants.map((v) => v.copyWith(productId: 'prod-3')).toList(),
    modifierGroups: _mockModifiers,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-4',
    name: 'Iced Tea',
    categoryId: 'cat-1',
    basePrice: Money.fromDouble(2.00),
    barcode: '1004',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-5',
    name: 'Fresh Orange Juice',
    categoryId: 'cat-1',
    basePrice: Money.fromDouble(3.00),
    barcode: '1005',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // Food
  ProductEntity(
    id: 'prod-6',
    name: 'Chicken Sandwich',
    categoryId: 'cat-2',
    basePrice: Money.fromDouble(8.50),
    barcode: '2001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-7',
    name: 'Veggie Wrap',
    categoryId: 'cat-2',
    basePrice: Money.fromDouble(7.00),
    barcode: '2002',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-8',
    name: 'Caesar Salad',
    categoryId: 'cat-2',
    basePrice: Money.fromDouble(9.00),
    barcode: '2003',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-9',
    name: 'Pasta Bowl',
    categoryId: 'cat-2',
    basePrice: Money.fromDouble(10.50),
    barcode: '2004',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // Snacks
  ProductEntity(
    id: 'prod-10',
    name: 'Chocolate Croissant',
    categoryId: 'cat-3',
    basePrice: Money.fromDouble(3.50),
    barcode: '3001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-11',
    name: 'Blueberry Muffin',
    categoryId: 'cat-3',
    basePrice: Money.fromDouble(2.75),
    barcode: '3002',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-12',
    name: 'Chips',
    categoryId: 'cat-3',
    basePrice: Money.fromDouble(1.50),
    barcode: '3003',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-13',
    name: 'Cookie',
    categoryId: 'cat-3',
    basePrice: Money.fromDouble(1.25),
    barcode: '3004',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  // Merchandise
  ProductEntity(
    id: 'prod-14',
    name: 'Coffee Mug',
    categoryId: 'cat-4',
    basePrice: Money.fromDouble(12.00),
    barcode: '4001',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-15',
    name: 'T-Shirt',
    categoryId: 'cat-4',
    basePrice: Money.fromDouble(25.00),
    barcode: '4002',
    variants: [
      VariantEntity(
        id: 'var-s',
        productId: 'prod-15',
        name: 'S',
        priceAdjustment: const Money.zero(),
      ),
      VariantEntity(
        id: 'var-m',
        productId: 'prod-15',
        name: 'M',
        priceAdjustment: const Money.zero(),
      ),
      VariantEntity(
        id: 'var-l',
        productId: 'prod-15',
        name: 'L',
        priceAdjustment: const Money.zero(),
      ),
      VariantEntity(
        id: 'var-xl',
        productId: 'prod-15',
        name: 'XL',
        priceAdjustment: Money.fromDouble(2.00),
      ),
    ],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  ProductEntity(
    id: 'prod-16',
    name: 'Coffee Beans (1lb)',
    categoryId: 'cat-4',
    basePrice: Money.fromDouble(15.00),
    barcode: '4003',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
