import 'package:equatable/equatable.dart';
import 'package:takopos/core/utils/money.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';

/// Represents the current shopping cart
class Cart extends Equatable {
  final String id;
  final List<CartItem> items;
  final Discount? cartDiscount;
  final String? customerId;
  final String? customerName;
  final String? notes;
  final DateTime createdAt;

  const Cart({
    required this.id,
    this.items = const [],
    this.cartDiscount,
    this.customerId,
    this.customerName,
    this.notes,
    required this.createdAt,
  });

  /// Create an empty cart
  factory Cart.empty() {
    return Cart(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: const [],
      createdAt: DateTime.now(),
    );
  }

  /// Calculate subtotal (before discounts)
  Money get subtotal {
    return items.fold(const Money.zero(), (sum, item) => sum + item.total);
  }

  /// Calculate cart-level discount amount
  Money get discountAmount {
    if (cartDiscount == null) return const Money.zero();
    return cartDiscount!.calculateDiscount(subtotal);
  }

  /// Calculate total (after discounts)
  Money get total {
    return subtotal - discountAmount;
  }

  /// Get total number of items (counting quantities)
  int get totalItemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  /// Get number of unique line items
  int get uniqueItemCount => items.length;

  /// Check if cart is empty
  bool get isEmpty => items.isEmpty;

  /// Check if cart is not empty
  bool get isNotEmpty => items.isNotEmpty;

  @override
  List<Object?> get props => [id, items, cartDiscount, customerId];

  Cart copyWith({
    String? id,
    List<CartItem>? items,
    Discount? cartDiscount,
    String? customerId,
    String? customerName,
    String? notes,
    DateTime? createdAt,
  }) {
    return Cart(
      id: id ?? this.id,
      items: items ?? this.items,
      cartDiscount: cartDiscount ?? this.cartDiscount,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Create a copy without the cart discount
  Cart clearDiscount() {
    return Cart(
      id: id,
      items: items,
      cartDiscount: null,
      customerId: customerId,
      customerName: customerName,
      notes: notes,
      createdAt: createdAt,
    );
  }
}

/// Represents an item in the cart
class CartItem extends Equatable {
  final String id;
  final ProductEntity product;
  final VariantEntity? variant;
  final List<ModifierEntity> selectedModifiers;
  final int quantity;
  final Discount? lineDiscount;
  final String? notes;

  const CartItem({
    required this.id,
    required this.product,
    this.variant,
    this.selectedModifiers = const [],
    this.quantity = 1,
    this.lineDiscount,
    this.notes,
  });

  /// Calculate unit price (base + variant + modifiers)
  Money get unitPrice {
    Money price = product.basePrice;

    if (variant != null) {
      price = price + variant!.priceAdjustment;
    }

    for (final modifier in selectedModifiers) {
      price = price + modifier.priceAdjustment;
    }

    return price;
  }

  /// Calculate line discount amount
  Money get lineDiscountAmount {
    if (lineDiscount == null) return const Money.zero();
    final lineTotal = unitPrice * quantity;
    return lineDiscount!.calculateDiscount(lineTotal);
  }

  /// Calculate total (unit price * quantity - discount)
  Money get total {
    final lineTotal = unitPrice * quantity;
    return lineTotal - lineDiscountAmount;
  }

  /// Get display name (product name + variant name if applicable)
  String get displayName {
    if (variant != null) {
      return '${product.name} (${variant!.name})';
    }
    return product.name;
  }

  /// Get modifier summary string
  String get modifierSummary {
    if (selectedModifiers.isEmpty) return '';
    return selectedModifiers.map((m) => m.name).join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        product.id,
        variant?.id,
        selectedModifiers.map((m) => m.id).toList(),
        quantity,
        lineDiscount,
        notes,
      ];

  CartItem copyWith({
    String? id,
    ProductEntity? product,
    VariantEntity? variant,
    List<ModifierEntity>? selectedModifiers,
    int? quantity,
    Discount? lineDiscount,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      variant: variant ?? this.variant,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      quantity: quantity ?? this.quantity,
      lineDiscount: lineDiscount ?? this.lineDiscount,
      notes: notes ?? this.notes,
    );
  }

  /// Create a copy without the line discount
  CartItem clearDiscount() {
    return CartItem(
      id: id,
      product: product,
      variant: variant,
      selectedModifiers: selectedModifiers,
      quantity: quantity,
      lineDiscount: null,
      notes: notes,
    );
  }
}

/// Represents a discount (can be percentage or fixed amount)
class Discount extends Equatable {
  final String id;
  final String name;
  final DiscountType type;
  final double value; // Percentage (e.g., 10 for 10%) or cents for fixed
  final String? reason;
  final String? approvedBy;
  final DateTime appliedAt;

  const Discount({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.reason,
    this.approvedBy,
    required this.appliedAt,
  });

  /// Create a percentage discount
  factory Discount.percentage({
    required String id,
    required String name,
    required double percentage,
    String? reason,
    String? approvedBy,
  }) {
    return Discount(
      id: id,
      name: name,
      type: DiscountType.percentage,
      value: percentage,
      reason: reason,
      approvedBy: approvedBy,
      appliedAt: DateTime.now(),
    );
  }

  /// Create a fixed amount discount
  factory Discount.fixed({
    required String id,
    required String name,
    required Money amount,
    String? reason,
    String? approvedBy,
  }) {
    return Discount(
      id: id,
      name: name,
      type: DiscountType.fixed,
      value: amount.cents.toDouble(),
      reason: reason,
      approvedBy: approvedBy,
      appliedAt: DateTime.now(),
    );
  }

  /// Calculate discount amount for a given base amount
  Money calculateDiscount(Money baseAmount) {
    switch (type) {
      case DiscountType.percentage:
        return baseAmount.percentage(value);
      case DiscountType.fixed:
        final fixedAmount = Money.fromCents(value.toInt());
        // Don't allow discount greater than base amount
        return fixedAmount > baseAmount ? baseAmount : fixedAmount;
    }
  }

  /// Get display value (e.g., "10%" or "$5.00")
  String get displayValue {
    switch (type) {
      case DiscountType.percentage:
        return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}%';
      case DiscountType.fixed:
        return Money.fromCents(value.toInt()).format();
    }
  }

  @override
  List<Object?> get props => [id, name, type, value];

  Discount copyWith({
    String? id,
    String? name,
    DiscountType? type,
    double? value,
    String? reason,
    String? approvedBy,
    DateTime? appliedAt,
  }) {
    return Discount(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      value: value ?? this.value,
      reason: reason ?? this.reason,
      approvedBy: approvedBy ?? this.approvedBy,
      appliedAt: appliedAt ?? this.appliedAt,
    );
  }
}

/// Type of discount
enum DiscountType {
  percentage,
  fixed,
}
