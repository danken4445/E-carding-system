import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:takopos/features/cart/domain/entities/cart_entities.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';

/// UUID generator for cart items
const _uuid = Uuid();

/// Provider for the current cart state
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

/// State notifier for cart operations
class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(Cart.empty());

  /// Add a product to the cart
  void addProduct(
    ProductEntity product, {
    VariantEntity? variant,
    List<ModifierEntity> modifiers = const [],
    int quantity = 1,
    String? notes,
  }) {
    // Check if this exact item configuration already exists
    final existingIndex = state.items.indexWhere((item) =>
        item.product.id == product.id &&
        item.variant?.id == variant?.id &&
        _sameModifiers(item.selectedModifiers, modifiers) &&
        item.notes == notes);

    if (existingIndex >= 0) {
      // Increment quantity of existing item
      final existingItem = state.items[existingIndex];
      final updatedItem =
          existingItem.copyWith(quantity: existingItem.quantity + quantity);

      final updatedItems = [...state.items];
      updatedItems[existingIndex] = updatedItem;

      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        id: _uuid.v4(),
        product: product,
        variant: variant,
        selectedModifiers: modifiers,
        quantity: quantity,
        notes: notes,
      );

      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  /// Remove an item from the cart by ID
  void removeItem(String itemId) {
    final updatedItems =
        state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  /// Update item quantity
  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Increment item quantity
  void incrementQuantity(String itemId) {
    final item = state.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw ArgumentError('Item not found'),
    );
    updateQuantity(itemId, item.quantity + 1);
  }

  /// Decrement item quantity
  void decrementQuantity(String itemId) {
    final item = state.items.firstWhere(
      (item) => item.id == itemId,
      orElse: () => throw ArgumentError('Item not found'),
    );
    updateQuantity(itemId, item.quantity - 1);
  }

  /// Update item notes
  void updateItemNotes(String itemId, String? notes) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(notes: notes);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Apply a line discount to an item
  void applyLineDiscount(String itemId, Discount discount) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(lineDiscount: discount);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Remove line discount from an item
  void removeLineDiscount(String itemId) {
    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.clearDiscount();
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  /// Apply a cart-level discount
  void applyCartDiscount(Discount discount) {
    state = state.copyWith(cartDiscount: discount);
  }

  /// Remove cart-level discount
  void removeCartDiscount() {
    state = state.clearDiscount();
  }

  /// Set customer information
  void setCustomer({String? customerId, String? customerName}) {
    state = state.copyWith(
      customerId: customerId,
      customerName: customerName,
    );
  }

  /// Set cart notes
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  /// Clear the entire cart
  void clearCart() {
    state = Cart.empty();
  }

  /// Helper to compare modifier lists
  bool _sameModifiers(
    List<ModifierEntity> a,
    List<ModifierEntity> b,
  ) {
    if (a.length != b.length) return false;
    final aIds = a.map((m) => m.id).toSet();
    final bIds = b.map((m) => m.id).toSet();
    return aIds.containsAll(bIds) && bIds.containsAll(aIds);
  }
}
