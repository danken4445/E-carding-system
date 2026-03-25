import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ============================================================================
// CATALOG TABLES
// ============================================================================

/// Product categories (e.g., Beverages, Food, Merchandise)
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get colorHex => text().nullable()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Products available for sale
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  TextColumn get categoryId => text().references(Categories, #id)();
  IntColumn get basePriceCents => integer()();
  IntColumn get costPriceCents => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get trackInventory =>
      boolean().withDefault(const Constant(false))();
  IntColumn get stockQuantity => integer().nullable()();
  IntColumn get lowStockThreshold => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Product variants (e.g., Small/Medium/Large, Red/Blue)
class Variants extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  IntColumn get priceAdjustmentCents =>
      integer().withDefault(const Constant(0))();
  IntColumn get stockQuantity => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Groups of modifiers (e.g., "Extras", "Sweetness Level")
class ModifierGroups extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get minSelections => integer().withDefault(const Constant(0))();
  IntColumn get maxSelections => integer().withDefault(const Constant(1))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual modifiers (e.g., "Extra Shot", "No Sugar")
class Modifiers extends Table {
  TextColumn get id => text()();
  TextColumn get groupId => text().references(ModifierGroups, #id)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get priceAdjustmentCents =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction table: which modifier groups apply to which products
class ProductModifierGroups extends Table {
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get modifierGroupId => text().references(ModifierGroups, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {productId, modifierGroupId};
}

// ============================================================================
// TRANSACTION TABLES
// ============================================================================

/// Completed or in-progress transactions/orders
class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get externalId => text().nullable()(); // Backend ID after sync
  TextColumn get shiftId => text().nullable()();
  IntColumn get subtotalCents => integer()();
  IntColumn get discountCents => integer().withDefault(const Constant(0))();
  IntColumn get taxCents => integer().withDefault(const Constant(0))();
  IntColumn get totalCents => integer()();
  TextColumn get status => text()(); // draft, completed, voided, refunded
  TextColumn get syncStatus => text()(); // pending, synced, failed, conflict
  TextColumn get customerId => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get customerEmail => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get cashierId => text()();
  TextColumn get cashierName => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Individual line items within a transaction
class TransactionLines extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get productId => text()();
  TextColumn get productName => text()(); // Denormalized for receipts
  TextColumn get variantId => text().nullable()();
  TextColumn get variantName => text().nullable()();
  IntColumn get quantity => integer()();
  IntColumn get unitPriceCents => integer()();
  IntColumn get lineTotalCents => integer()();
  IntColumn get discountCents => integer().withDefault(const Constant(0))();
  TextColumn get discountReason => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get modifiersJson =>
      text().nullable()(); // JSON array of applied modifiers

  @override
  Set<Column> get primaryKey => {id};
}

/// Payments applied to transactions
class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get method => text()(); // cash, card, giftCard, storeCredit
  IntColumn get amountCents => integer()();
  IntColumn get tenderedCents => integer().nullable()(); // For cash payments
  IntColumn get changeCents => integer().nullable()(); // For cash payments
  TextColumn get cardLast4 => text().nullable()();
  TextColumn get cardBrand => text().nullable()();
  TextColumn get authorizationCode => text().nullable()();
  TextColumn get externalPaymentId => text().nullable()();
  TextColumn get status => text()(); // pending, approved, declined, voided
  DateTimeColumn get timestamp => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// USER & AUTH TABLES
// ============================================================================

/// Staff members who can use the POS
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get authUserId => text().nullable()(); // Link to auth.users
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().nullable()(); // User email
  TextColumn get pinHash => text().nullable()(); // Hashed 4-6 digit PIN
  TextColumn get role => text()(); // staff, manager, owner
  TextColumn get permissionsJson => text().nullable()(); // JSON array
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SHIFT MANAGEMENT TABLES (Phase 2)
// ============================================================================

/// Cash register shifts
class Shifts extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text().nullable()(); // Multi-tenant support
  TextColumn get userId => text().references(Users, #id)();
  TextColumn get registerId => text().nullable()();
  IntColumn get openingCashCents => integer()();
  IntColumn get closingCashCents => integer().nullable()();
  IntColumn get expectedCashCents => integer().nullable()();
  IntColumn get varianceCents => integer().nullable()();
  DateTimeColumn get openedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  BoolColumn get isBlindClose => boolean().withDefault(const Constant(false))();
  TextColumn get status => text()(); // open, closing, closed
  TextColumn get notes => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================================
// SYNC QUEUE TABLE
// ============================================================================

/// Queue of pending sync operations
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // transaction, product, etc.
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get payload => text()(); // JSON data to sync
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get queuedAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
}

// ============================================================================
// DATABASE CLASS
// ============================================================================

@DriftDatabase(tables: [
  Categories,
  Products,
  Variants,
  ModifierGroups,
  Modifiers,
  ProductModifierGroups,
  Transactions,
  TransactionLines,
  Payments,
  Users,
  Shifts,
  SyncQueue,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'takopos');
  }

  @override
  int get schemaVersion => 2; // Updated for multi-tenancy

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // Migration from v1 to v2: Add multi-tenancy support
          if (from == 1 && to == 2) {
            // Add shop_id columns using raw SQL since the generated code doesn't exist yet
            await m.database.customStatement(
              'ALTER TABLE categories ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE products ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE modifier_groups ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE transactions ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE shifts ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE users ADD COLUMN shop_id TEXT;');
            await m.database.customStatement(
              'ALTER TABLE users ADD COLUMN email TEXT;');
            await m.database.customStatement(
              'ALTER TABLE users ADD COLUMN auth_user_id TEXT;');
          }
        },
      );

  // =========================================================================
  // SHOP CONTEXT MANAGEMENT
  // =========================================================================

  /// Current shop ID for multi-tenant filtering
  String? get currentShopId => _currentShopId;
  String? _currentShopId;

  /// Set the current shop context (called after authentication)
  void setCurrentShopId(String? shopId) {
    _currentShopId = shopId;
  }

  // =========================================================================
  // CATEGORY QUERIES
  // =========================================================================

  Future<List<Category>> getAllCategories() => (select(categories)
        ..where((c) =>
            c.shopId.equals(currentShopId ?? '') |
            c.shopId.isNull()) // Support legacy data without shop_id
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .get();

  Stream<List<Category>> watchAllCategories() => (select(categories)
        ..where((c) =>
            c.shopId.equals(currentShopId ?? '') | c.shopId.isNull())
        ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
      .watch();

  Future<int> insertCategory(CategoriesCompanion category) =>
      into(categories).insert(category);

  Future<bool> updateCategory(CategoriesCompanion category) =>
      update(categories).replace(category);

  Future<int> deleteCategory(String id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  // =========================================================================
  // PRODUCT QUERIES
  // =========================================================================

  Future<List<Product>> getAllProducts() => (select(products)
        ..where((p) =>
            p.shopId.equals(currentShopId ?? '') | p.shopId.isNull()))
      .get();

  Future<List<Product>> getProductsByCategory(String categoryId) =>
      (select(products)
            ..where((p) =>
                p.categoryId.equals(categoryId) &
                (p.shopId.equals(currentShopId ?? '') | p.shopId.isNull())))
          .get();

  Stream<List<Product>> watchProductsByCategory(String categoryId) =>
      (select(products)
            ..where((p) =>
                p.categoryId.equals(categoryId) &
                (p.shopId.equals(currentShopId ?? '') | p.shopId.isNull())))
          .watch();

  Future<Product?> getProductByBarcode(String barcode) => (select(products)
        ..where((p) =>
            p.barcode.equals(barcode) &
            (p.shopId.equals(currentShopId ?? '') | p.shopId.isNull())))
      .getSingleOrNull();

  Future<List<Product>> searchProducts(String query) => (select(products)
        ..where((p) =>
            (p.name.like('%$query%') | p.barcode.like('%$query%')) &
            (p.shopId.equals(currentShopId ?? '') | p.shopId.isNull())))
      .get();

  Future<int> insertProduct(ProductsCompanion product) =>
      into(products).insert(product);

  Future<bool> updateProduct(ProductsCompanion product) =>
      update(products).replace(product);

  // =========================================================================
  // VARIANT QUERIES
  // =========================================================================

  Future<List<Variant>> getVariantsForProduct(String productId) =>
      (select(variants)
            ..where((v) => v.productId.equals(productId))
            ..orderBy([(v) => OrderingTerm.asc(v.sortOrder)]))
          .get();

  Stream<List<Variant>> watchVariantsForProduct(String productId) =>
      (select(variants)
            ..where((v) => v.productId.equals(productId))
            ..orderBy([(v) => OrderingTerm.asc(v.sortOrder)]))
          .watch();

  // =========================================================================
  // MODIFIER QUERIES
  // =========================================================================

  Future<List<ModifierGroup>> getModifierGroupsForProduct(
      String productId) async {
    final query = select(modifierGroups).join([
      innerJoin(
        productModifierGroups,
        productModifierGroups.modifierGroupId.equalsExp(modifierGroups.id),
      ),
    ])
      ..where(productModifierGroups.productId.equals(productId))
      ..orderBy([OrderingTerm.asc(productModifierGroups.sortOrder)]);

    final results = await query.get();
    return results.map((row) => row.readTable(modifierGroups)).toList();
  }

  Future<List<Modifier>> getModifiersForGroup(String groupId) =>
      (select(modifiers)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
          .get();

  // =========================================================================
  // TRANSACTION QUERIES
  // =========================================================================

  Future<int> insertTransaction(TransactionsCompanion transaction) =>
      into(transactions).insert(transaction);

  Future<Transaction?> getTransactionById(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<bool> updateTransaction(TransactionsCompanion transaction) =>
      update(transactions).replace(transaction);

  Future<Transaction?> getTransaction(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Transaction>> getRecentTransactions({int limit = 20}) =>
      (select(transactions)
            ..where((t) =>
                t.shopId.equals(currentShopId ?? '') | t.shopId.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<List<Transaction>> getPendingSyncTransactions() => (select(transactions)
        ..where((t) =>
            t.syncStatus.equals('pending') &
            (t.shopId.equals(currentShopId ?? '') | t.shopId.isNull())))
      .get();

  // =========================================================================
  // TRANSACTION LINE QUERIES
  // =========================================================================

  Future<int> insertTransactionLine(TransactionLinesCompanion line) =>
      into(transactionLines).insert(line);

  Future<List<TransactionLine>> getLinesForTransaction(String transactionId) =>
      (select(transactionLines)
            ..where((l) => l.transactionId.equals(transactionId)))
          .get();

  // =========================================================================
  // PAYMENT QUERIES
  // =========================================================================

  Future<int> insertPayment(PaymentsCompanion payment) =>
      into(payments).insert(payment);

  Future<List<Payment>> getPaymentsForTransaction(String transactionId) =>
      (select(payments)..where((p) => p.transactionId.equals(transactionId)))
          .get();

  // =========================================================================
  // USER QUERIES
  // =========================================================================

  Future<User?> getUserByUsername(String username) =>
      (select(users)..where((u) => u.username.equals(username)))
          .getSingleOrNull();

  Future<List<User>> getAllUsers() => select(users).get();

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  // =========================================================================
  // SYNC QUEUE QUERIES
  // =========================================================================

  Future<int> enqueueSync(SyncQueueCompanion entry) =>
      into(syncQueue).insert(entry);

  Future<List<SyncQueueData>> getPendingSyncItems({int limit = 50}) =>
      (select(syncQueue)
            ..orderBy([(s) => OrderingTerm.asc(s.queuedAt)])
            ..limit(limit))
          .get();

  Future<int> deleteSyncItem(int id) =>
      (delete(syncQueue)..where((s) => s.id.equals(id))).go();

  Future<void> incrementSyncRetry(int id, String error) async {
    // Increment retry count using raw SQL
    await customStatement(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_attempt_at = ?, last_error = ? WHERE id = ?',
      [DateTime.now().millisecondsSinceEpoch, error, id],
    );
  }

  // =========================================================================
  // PRODUCT EXTENDED QUERIES (CMS)
  // =========================================================================

  Stream<List<Product>> watchAllProducts() => (select(products)
        ..where((p) =>
            p.shopId.equals(currentShopId ?? '') | p.shopId.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();

  Future<int> deleteProduct(String id) async {
    // Delete related variants first
    await (delete(variants)..where((v) => v.productId.equals(id))).go();
    // Delete product-modifier associations
    await (delete(productModifierGroups)..where((p) => p.productId.equals(id)))
        .go();
    // Delete the product
    return (delete(products)..where((p) => p.id.equals(id))).go();
  }

  // =========================================================================
  // VARIANT CRUD (CMS)
  // =========================================================================

  Future<int> insertVariant(VariantsCompanion variant) =>
      into(variants).insert(variant);

  Future<bool> updateVariant(VariantsCompanion variant) =>
      update(variants).replace(variant);

  Future<int> deleteVariant(String id) =>
      (delete(variants)..where((v) => v.id.equals(id))).go();

  Future<int> deleteVariantsForProduct(String productId) =>
      (delete(variants)..where((v) => v.productId.equals(productId))).go();

  // =========================================================================
  // MODIFIER GROUP CRUD (CMS)
  // =========================================================================

  Future<List<ModifierGroup>> getAllModifierGroups() =>
      (select(modifierGroups)
            ..where((g) =>
                g.shopId.equals(currentShopId ?? '') | g.shopId.isNull())
            ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
          .get();

  Stream<List<ModifierGroup>> watchAllModifierGroups() =>
      (select(modifierGroups)
            ..where((g) =>
                g.shopId.equals(currentShopId ?? '') | g.shopId.isNull())
            ..orderBy([(g) => OrderingTerm.asc(g.sortOrder)]))
          .watch();

  Future<int> insertModifierGroup(ModifierGroupsCompanion group) =>
      into(modifierGroups).insert(group);

  Future<bool> updateModifierGroup(ModifierGroupsCompanion group) =>
      update(modifierGroups).replace(group);

  Future<int> deleteModifierGroup(String id) async {
    // Delete modifiers in group first
    await (delete(modifiers)..where((m) => m.groupId.equals(id))).go();
    // Delete product associations
    await (delete(productModifierGroups)
          ..where((p) => p.modifierGroupId.equals(id)))
        .go();
    // Delete the group
    return (delete(modifierGroups)..where((g) => g.id.equals(id))).go();
  }

  // =========================================================================
  // MODIFIER CRUD (CMS)
  // =========================================================================

  Future<List<Modifier>> getAllModifiers() =>
      (select(modifiers)..orderBy([(m) => OrderingTerm.asc(m.sortOrder)])).get();

  Stream<List<Modifier>> watchModifiersForGroup(String groupId) =>
      (select(modifiers)
            ..where((m) => m.groupId.equals(groupId))
            ..orderBy([(m) => OrderingTerm.asc(m.sortOrder)]))
          .watch();

  Future<int> insertModifier(ModifiersCompanion modifier) =>
      into(modifiers).insert(modifier);

  Future<bool> updateModifier(ModifiersCompanion modifier) =>
      update(modifiers).replace(modifier);

  Future<int> deleteModifier(String id) =>
      (delete(modifiers)..where((m) => m.id.equals(id))).go();

  // =========================================================================
  // PRODUCT-MODIFIER GROUP LINKING (CMS)
  // =========================================================================

  Future<List<String>> getModifierGroupIdsForProduct(String productId) async {
    final query = select(productModifierGroups)
      ..where((p) => p.productId.equals(productId));
    final results = await query.get();
    return results.map((r) => r.modifierGroupId).toList();
  }

  Future<void> setProductModifierGroups(
      String productId, List<String> groupIds) async {
    // Delete existing associations
    await (delete(productModifierGroups)
          ..where((p) => p.productId.equals(productId)))
        .go();
    // Insert new associations
    for (int i = 0; i < groupIds.length; i++) {
      await into(productModifierGroups).insert(
        ProductModifierGroupsCompanion.insert(
          productId: productId,
          modifierGroupId: groupIds[i],
          sortOrder: Value(i),
        ),
      );
    }
  }
}
