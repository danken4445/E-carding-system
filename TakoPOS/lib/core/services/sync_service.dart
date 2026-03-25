import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:takopos/main.dart';
import 'package:takopos/core/database/database.dart';

/// Service for syncing transactions to Supabase
class SyncService {
  final SupabaseClient _client;
  final Connectivity _connectivity = Connectivity();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService(this._client);

  /// Initialize the sync service
  void initialize() {
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (results) {
        final isConnected = results.any(
          (r) => r != ConnectivityResult.none,
        );
        if (isConnected) {
          // Trigger sync when connection is restored
          syncPendingTransactions();
        }
      },
    );

    // Initial sync attempt
    syncPendingTransactions();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Check if we have an internet connection
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.any((r) => r != ConnectivityResult.none);
  }

  /// Sync all pending transactions to Supabase
  Future<void> syncPendingTransactions() async {
    if (_isSyncing) return;

    final connected = await isConnected;
    if (!connected) return;

    _isSyncing = true;

    try {
      // Get pending sync queue items (transactions only, up to 50 at a time)
      final allPendingItems = await database.getPendingSyncItems(limit: 50);
      final pendingItems = allPendingItems
          .where((item) => item.entityType == 'transaction')
          .toList();

      for (final item in pendingItems) {
        try {
          // Fetch the actual transaction
          final transaction = await database.getTransactionById(item.entityId);
          if (transaction == null) {
            // Transaction doesn't exist, remove from queue
            await database.deleteSyncItem(item.id);
            continue;
          }

          // Attempt sync
          await _syncTransaction(transaction);

          // Success - remove from queue
          await database.deleteSyncItem(item.id);
          debugPrint('✓ Synced transaction ${transaction.id}');
        } catch (e) {
          debugPrint('Failed to sync transaction ${item.entityId}: $e');

          // Update retry count
          await database.incrementSyncRetry(item.id, e.toString());

          // If too many retries (>5), log and skip for now
          if (item.retryCount >= 5) {
            debugPrint('⚠ Transaction ${item.entityId} exceeded max retries');
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single transaction to Supabase
  Future<void> _syncTransaction(dynamic transaction) async {
    final shopId = database.currentShopId;
    if (shopId == null) {
      throw Exception('No shop context available for transaction sync');
    }

    // Upload transaction with shop_id
    final response = await _client.from('transactions').upsert({
      'id': transaction.id,
      'shop_id': shopId,
      'shift_id': transaction.shiftId,
      'subtotal_cents': transaction.subtotalCents,
      'discount_cents': transaction.discountCents,
      'tax_cents': transaction.taxCents,
      'total_cents': transaction.totalCents,
      'status': transaction.status,
      'customer_id': transaction.customerId,
      'customer_name': transaction.customerName,
      'customer_email': transaction.customerEmail,
      'customer_phone': transaction.customerPhone,
      'cashier_id': transaction.cashierId,
      'cashier_name': transaction.cashierName,
      'notes': transaction.notes,
      'created_at': transaction.createdAt.toIso8601String(),
      'completed_at': transaction.completedAt?.toIso8601String(),
    }).select();

    if (response.isNotEmpty) {
      // Upload transaction lines
      final lines = await database.getLinesForTransaction(transaction.id);
      for (final line in lines) {
        await _client.from('transaction_lines').upsert({
          'id': line.id,
          'transaction_id': line.transactionId,
          'product_id': line.productId,
          'product_name': line.productName,
          'variant_id': line.variantId,
          'variant_name': line.variantName,
          'quantity': line.quantity,
          'unit_price_cents': line.unitPriceCents,
          'line_total_cents': line.lineTotalCents,
          'discount_cents': line.discountCents,
          'discount_reason': line.discountReason,
          'notes': line.notes,
          'modifiers_json': line.modifiersJson,
        });
      }

      // Upload payments
      final payments = await database.getPaymentsForTransaction(transaction.id);
      for (final payment in payments) {
        await _client.from('payments').upsert({
          'id': payment.id,
          'transaction_id': payment.transactionId,
          'method': payment.method,
          'amount_cents': payment.amountCents,
          'tendered_cents': payment.tenderedCents,
          'change_cents': payment.changeCents,
          'card_last4': payment.cardLast4,
          'card_brand': payment.cardBrand,
          'authorization_code': payment.authorizationCode,
          'external_payment_id': payment.externalPaymentId,
          'status': payment.status,
          'timestamp': payment.timestamp.toIso8601String(),
        });
      }

      // Mark transaction as synced
      // await database.markTransactionSynced(transaction.id);
    }
  }

  /// Fetch catalog data from Supabase and save to local database
  Future<void> syncCatalogFromServer() async {
    final connected = await isConnected;
    if (!connected) return;

    // Get current shop context
    final shopId = database.currentShopId;
    if (shopId == null) {
      debugPrint('No shop context available for catalog sync');
      return;
    }

    try {
      debugPrint('Starting catalog sync from Supabase for shop: $shopId...');

      // Fetch categories for current shop
      final categoriesData = await _client
          .from('categories')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true)
          .order('sort_order');

      debugPrint('Fetched ${categoriesData.length} categories for shop $shopId');

      // Save categories to local database
      for (final cat in categoriesData) {
        await database.into(database.categories).insertOnConflictUpdate(
              CategoriesCompanion.insert(
                id: cat['id'] as String,
                shopId: Value(shopId),
                name: cat['name'] as String,
                description: Value(cat['description'] as String?),
                sortOrder: Value(cat['sort_order'] as int? ?? 0),
                colorHex: Value(cat['color_hex'] as String?),
                iconName: Value(cat['icon_name'] as String?),
                isActive: Value(cat['is_active'] as bool? ?? true),
                createdAt: cat['created_at'] != null
                    ? DateTime.parse(cat['created_at'] as String)
                    : DateTime.now(),
                updatedAt: cat['updated_at'] != null
                    ? DateTime.parse(cat['updated_at'] as String)
                    : DateTime.now(),
              ),
            );
      }

      // Fetch products for current shop
      final productsData = await _client
          .from('products')
          .select()
          .eq('shop_id', shopId)
          .eq('is_active', true);

      debugPrint('Fetched ${productsData.length} products for shop $shopId');

      // Save products to local database
      for (final prod in productsData) {
        final categoryId = prod['category_id'] as String?;
        if (categoryId == null) {
          debugPrint('Skipping product ${prod['id']} - no category_id');
          continue;
        }

        await database.into(database.products).insertOnConflictUpdate(
              ProductsCompanion.insert(
                id: prod['id'] as String,
                shopId: Value(shopId),
                name: prod['name'] as String,
                description: Value(prod['description'] as String?),
                barcode: Value(prod['barcode'] as String?),
                sku: Value(prod['sku'] as String?),
                categoryId: categoryId,
                basePriceCents: prod['base_price_cents'] as int,
                costPriceCents: Value(prod['cost_price_cents'] as int?),
                imageUrl: Value(prod['image_url'] as String?),
                isActive: Value(prod['is_active'] as bool? ?? true),
                trackInventory: Value(prod['track_inventory'] as bool? ?? false),
                stockQuantity: Value(prod['stock_quantity'] as int?),
                lowStockThreshold: Value(prod['low_stock_threshold'] as int? ?? 5),
                createdAt: prod['created_at'] != null
                    ? DateTime.parse(prod['created_at'] as String)
                    : DateTime.now(),
                updatedAt: prod['updated_at'] != null
                    ? DateTime.parse(prod['updated_at'] as String)
                    : DateTime.now(),
                syncVersion: Value(prod['sync_version'] as int? ?? 0),
              ),
            );
      }

      // Fetch variants (filter by products that belong to current shop)
      final variantsData = await _client
          .from('variants')
          .select('*, products!inner(shop_id)')
          .eq('products.shop_id', shopId)
          .eq('is_active', true)
          .order('sort_order');

      debugPrint('Fetched ${variantsData.length} variants for shop $shopId');

      // Save variants to local database
      for (final variant in variantsData) {
        await database.into(database.variants).insertOnConflictUpdate(
              VariantsCompanion.insert(
                id: variant['id'] as String,
                productId: variant['product_id'] as String,
                name: variant['name'] as String,
                sku: Value(variant['sku'] as String?),
                barcode: Value(variant['barcode'] as String?),
                priceAdjustmentCents:
                    Value(variant['price_adjustment_cents'] as int? ?? 0),
                stockQuantity: Value(variant['stock_quantity'] as int?),
                sortOrder: Value(variant['sort_order'] as int? ?? 0),
                isActive: Value(variant['is_active'] as bool? ?? true),
              ),
            );
      }

      // Fetch modifier groups for current shop
      final modifierGroupsData = await _client
          .from('modifier_groups')
          .select()
          .eq('shop_id', shopId)
          .order('sort_order');

      debugPrint('Fetched ${modifierGroupsData.length} modifier groups for shop $shopId');

      // Save modifier groups
      for (final group in modifierGroupsData) {
        await database.into(database.modifierGroups).insertOnConflictUpdate(
              ModifierGroupsCompanion.insert(
                id: group['id'] as String,
                shopId: Value(shopId),
                name: group['name'] as String,
                minSelections: Value(group['min_selections'] as int? ?? 0),
                maxSelections: Value(group['max_selections'] as int? ?? 1),
                sortOrder: Value(group['sort_order'] as int? ?? 0),
              ),
            );
      }

      // Fetch modifiers (filter by modifier groups that belong to current shop)
      final modifiersData = await _client
          .from('modifiers')
          .select('*, modifier_groups!inner(shop_id)')
          .eq('modifier_groups.shop_id', shopId)
          .order('sort_order');

      debugPrint('Fetched ${modifiersData.length} modifiers for shop $shopId');

      // Save modifiers
      for (final modifier in modifiersData) {
        await database.into(database.modifiers).insertOnConflictUpdate(
              ModifiersCompanion.insert(
                id: modifier['id'] as String,
                groupId: modifier['group_id'] as String,
                name: modifier['name'] as String,
                priceAdjustmentCents:
                    Value(modifier['price_adjustment_cents'] as int? ?? 0),
                isDefault: Value(modifier['is_default'] as bool? ?? false),
                sortOrder: Value(modifier['sort_order'] as int? ?? 0),
              ),
            );
      }

      // Fetch product-modifier group associations (filter by products that belong to current shop)
      final productModifierGroupsData = await _client
          .from('product_modifier_groups')
          .select('*, products!inner(shop_id)')
          .eq('products.shop_id', shopId);

      debugPrint(
          'Fetched ${productModifierGroupsData.length} product-modifier group associations for shop $shopId');

      // Save associations
      for (final assoc in productModifierGroupsData) {
        await database
            .into(database.productModifierGroups)
            .insertOnConflictUpdate(
              ProductModifierGroupsCompanion.insert(
                productId: assoc['product_id'] as String,
                modifierGroupId: assoc['modifier_group_id'] as String,
                sortOrder: Value(assoc['sort_order'] as int? ?? 0),
              ),
            );
      }

      debugPrint('✓ Catalog sync completed successfully for shop $shopId');
    } catch (e) {
      debugPrint('Failed to sync catalog for shop $shopId: $e');
      rethrow;
    }
  }
}

/// Provider for the sync service
final syncServiceProvider = SyncService(Supabase.instance.client);
