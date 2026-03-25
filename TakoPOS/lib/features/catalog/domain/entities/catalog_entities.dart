import 'package:equatable/equatable.dart';
import 'package:takopos/core/utils/money.dart';

/// Represents a product category (e.g., Beverages, Food)
class CategoryEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final String? colorHex;
  final String? iconName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.description,
    this.sortOrder = 0,
    this.colorHex,
    this.iconName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        sortOrder,
        colorHex,
        iconName,
        isActive,
      ];

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? description,
    int? sortOrder,
    String? colorHex,
    String? iconName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a product available for sale
class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? barcode;
  final String? sku;
  final String categoryId;
  final Money basePrice;
  final Money? costPrice;
  final String? imageUrl;
  final bool isActive;
  final bool trackInventory;
  final int? stockQuantity;
  final int? lowStockThreshold;
  final List<VariantEntity> variants;
  final List<ModifierGroupEntity> modifierGroups;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductEntity({
    required this.id,
    required this.name,
    this.description,
    this.barcode,
    this.sku,
    required this.categoryId,
    required this.basePrice,
    this.costPrice,
    this.imageUrl,
    this.isActive = true,
    this.trackInventory = false,
    this.stockQuantity,
    this.lowStockThreshold,
    this.variants = const [],
    this.modifierGroups = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if product has variants
  bool get hasVariants => variants.isNotEmpty;

  /// Check if product has modifiers
  bool get hasModifiers => modifierGroups.isNotEmpty;

  /// Check if product is low on stock
  bool get isLowStock {
    if (!trackInventory || stockQuantity == null) return false;
    final threshold = lowStockThreshold ?? 5;
    return stockQuantity! <= threshold;
  }

  /// Check if product is out of stock
  bool get isOutOfStock {
    if (!trackInventory || stockQuantity == null) return false;
    return stockQuantity! <= 0;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        barcode,
        categoryId,
        basePrice,
        isActive,
      ];

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? barcode,
    String? sku,
    String? categoryId,
    Money? basePrice,
    Money? costPrice,
    String? imageUrl,
    bool? isActive,
    bool? trackInventory,
    int? stockQuantity,
    int? lowStockThreshold,
    List<VariantEntity>? variants,
    List<ModifierGroupEntity>? modifierGroups,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      sku: sku ?? this.sku,
      categoryId: categoryId ?? this.categoryId,
      basePrice: basePrice ?? this.basePrice,
      costPrice: costPrice ?? this.costPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      trackInventory: trackInventory ?? this.trackInventory,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      variants: variants ?? this.variants,
      modifierGroups: modifierGroups ?? this.modifierGroups,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Represents a product variant (e.g., Small, Medium, Large)
class VariantEntity extends Equatable {
  final String id;
  final String productId;
  final String name;
  final String? sku;
  final String? barcode;
  final Money priceAdjustment;
  final int? stockQuantity;
  final int sortOrder;
  final bool isActive;

  const VariantEntity({
    required this.id,
    required this.productId,
    required this.name,
    this.sku,
    this.barcode,
    required this.priceAdjustment,
    this.stockQuantity,
    this.sortOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, productId, name, priceAdjustment];

  VariantEntity copyWith({
    String? id,
    String? productId,
    String? name,
    String? sku,
    String? barcode,
    Money? priceAdjustment,
    int? stockQuantity,
    int? sortOrder,
    bool? isActive,
  }) {
    return VariantEntity(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Represents a group of modifiers (e.g., "Extras", "Sweetness Level")
class ModifierGroupEntity extends Equatable {
  final String id;
  final String name;
  final int minSelections;
  final int maxSelections;
  final int sortOrder;
  final List<ModifierEntity> modifiers;

  const ModifierGroupEntity({
    required this.id,
    required this.name,
    this.minSelections = 0,
    this.maxSelections = 1,
    this.sortOrder = 0,
    this.modifiers = const [],
  });

  /// Whether this modifier group is required
  bool get isRequired => minSelections > 0;

  /// Whether multiple selections are allowed
  bool get allowsMultiple => maxSelections > 1;

  @override
  List<Object?> get props => [id, name, minSelections, maxSelections];

  ModifierGroupEntity copyWith({
    String? id,
    String? name,
    int? minSelections,
    int? maxSelections,
    int? sortOrder,
    List<ModifierEntity>? modifiers,
  }) {
    return ModifierGroupEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      minSelections: minSelections ?? this.minSelections,
      maxSelections: maxSelections ?? this.maxSelections,
      sortOrder: sortOrder ?? this.sortOrder,
      modifiers: modifiers ?? this.modifiers,
    );
  }
}

/// Represents an individual modifier (e.g., "Extra Shot", "No Sugar")
class ModifierEntity extends Equatable {
  final String id;
  final String groupId;
  final String name;
  final Money priceAdjustment;
  final bool isDefault;
  final int sortOrder;

  const ModifierEntity({
    required this.id,
    required this.groupId,
    required this.name,
    required this.priceAdjustment,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  /// Check if this modifier has an additional cost
  bool get hasAdditionalCost => priceAdjustment.isPositive;

  @override
  List<Object?> get props => [id, groupId, name, priceAdjustment];

  ModifierEntity copyWith({
    String? id,
    String? groupId,
    String? name,
    Money? priceAdjustment,
    bool? isDefault,
    int? sortOrder,
  }) {
    return ModifierEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      priceAdjustment: priceAdjustment ?? this.priceAdjustment,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
