import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/database/database.dart';
import 'package:takopos/main.dart';

/// Product edit screen for creating and editing products
class ProductEditScreen extends ConsumerStatefulWidget {
  final String? productId;

  const ProductEditScreen({super.key, this.productId});

  @override
  ConsumerState<ProductEditScreen> createState() => _ProductEditScreenState();
}

class _ProductEditScreenState extends ConsumerState<ProductEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _barcodeController;
  late TextEditingController _skuController;
  late TextEditingController _basePriceController;
  late TextEditingController _costPriceController;

  String? _selectedCategoryId;
  bool _trackInventory = false;
  int? _stockQuantity;
  int? _lowStockThreshold;

  List<Category> _categories = [];
  List<_VariantForm> _variants = [];
  List<String> _linkedModifierGroupIds = [];
  List<ModifierGroup> _allModifierGroups = [];

  Product? _existingProduct;

  bool get isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _barcodeController = TextEditingController();
    _skuController = TextEditingController();
    _basePriceController = TextEditingController();
    _costPriceController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _barcodeController.dispose();
    _skuController.dispose();
    _basePriceController.dispose();
    _costPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    _categories = await database.getAllCategories();
    _allModifierGroups = await database.getAllModifierGroups();

    if (isEditing) {
      final products = await database.getAllProducts();
      _existingProduct = products.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => throw Exception('Product not found'),
      );

      _nameController.text = _existingProduct!.name;
      _descriptionController.text = _existingProduct!.description ?? '';
      _barcodeController.text = _existingProduct!.barcode ?? '';
      _skuController.text = _existingProduct!.sku ?? '';
      _basePriceController.text =
          (_existingProduct!.basePriceCents / 100).toStringAsFixed(2);
      _costPriceController.text = _existingProduct!.costPriceCents != null
          ? (_existingProduct!.costPriceCents! / 100).toStringAsFixed(2)
          : '';
      _selectedCategoryId = _existingProduct!.categoryId;
      _trackInventory = _existingProduct!.trackInventory;
      _stockQuantity = _existingProduct!.stockQuantity;
      _lowStockThreshold = _existingProduct!.lowStockThreshold;

      // Load variants
      final variants =
          await database.getVariantsForProduct(_existingProduct!.id);
      _variants = variants
          .map((v) => _VariantForm(
                id: v.id,
                name: v.name,
                priceAdjustment: v.priceAdjustmentCents / 100,
                barcode: v.barcode,
              ))
          .toList();

      // Load linked modifier groups
      _linkedModifierGroupIds =
          await database.getModifierGroupIdsForProduct(_existingProduct!.id);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Product' : 'New Product'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Product' : 'New Product'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cms/products'),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppColors.error,
              onPressed: _confirmDelete,
              tooltip: 'Delete',
            ),
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, color: AppColors.success),
            label: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? AppColors.textSecondary : AppColors.success,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildSection('Basic Information', Icons.info_outline, [
              _buildTextField(
                controller: _nameController,
                label: 'Product Name *',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 3,
              ),
              _buildCategoryDropdown(),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _barcodeController,
                      label: 'Barcode',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _skuController,
                      label: 'SKU',
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            _buildSection('Pricing', Icons.attach_money, [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _basePriceController,
                      label: 'Base Price *',
                      prefix: '\$',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Price is required';
                        if (double.tryParse(v) == null) return 'Invalid price';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildTextField(
                      controller: _costPriceController,
                      label: 'Cost Price',
                      prefix: '\$',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            _buildVariantsSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildModifiersSection(),
            const SizedBox(height: AppSpacing.lg),
            _buildInventorySection(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(title, style: AppTextStyles.headline3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _selectedCategoryId,
        decoration: const InputDecoration(
          labelText: 'Category *',
          border: OutlineInputBorder(),
        ),
        items: _categories
            .map((cat) => DropdownMenuItem(
                  value: cat.id,
                  child: Text(cat.name),
                ))
            .toList(),
        onChanged: (value) => setState(() => _selectedCategoryId = value),
        validator: (v) => v == null ? 'Category is required' : null,
      ),
    );
  }

  Widget _buildVariantsSection() {
    return _buildSection('Variants', Icons.style, [
      ..._variants.asMap().entries.map((entry) {
        final index = entry.key;
        final variant = entry.value;
        return _VariantRow(
          variant: variant,
          onChanged: (v) => setState(() => _variants[index] = v),
          onDelete: () => setState(() => _variants.removeAt(index)),
        );
      }),
      const SizedBox(height: AppSpacing.sm),
      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _variants.add(_VariantForm(
              id: null,
              name: '',
              priceAdjustment: 0,
            ));
          });
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Variant'),
      ),
    ]);
  }

  Widget _buildModifiersSection() {
    return _buildSection('Add-ons (Modifiers)', Icons.add_circle_outline, [
      if (_allModifierGroups.isEmpty)
        Text(
          'No modifier groups available. Create some in the Add-ons section.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        )
      else
        ..._allModifierGroups.map((group) {
          final isLinked = _linkedModifierGroupIds.contains(group.id);
          return CheckboxListTile(
            title: Text(group.name),
            subtitle: Text(
              'Min: ${group.minSelections}, Max: ${group.maxSelections}',
            ),
            value: isLinked,
            onChanged: (value) {
              setState(() {
                if (value == true) {
                  _linkedModifierGroupIds.add(group.id);
                } else {
                  _linkedModifierGroupIds.remove(group.id);
                }
              });
            },
          );
        }),
    ]);
  }

  Widget _buildInventorySection() {
    return _buildSection('Inventory', Icons.inventory, [
      SwitchListTile(
        title: const Text('Track Inventory'),
        subtitle: const Text('Enable stock tracking for this product'),
        value: _trackInventory,
        onChanged: (value) => setState(() => _trackInventory = value),
      ),
      if (_trackInventory) ...[
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _stockQuantity?.toString() ?? '',
                decoration: const InputDecoration(
                  labelText: 'Current Stock',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _stockQuantity = int.tryParse(v),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextFormField(
                initialValue: _lowStockThreshold?.toString() ?? '5',
                decoration: const InputDecoration(
                  labelText: 'Low Stock Alert',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => _lowStockThreshold = int.tryParse(v),
              ),
            ),
          ],
        ),
      ],
    ]);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final productId = isEditing ? _existingProduct!.id : const Uuid().v4();
      final basePriceCents =
          (double.parse(_basePriceController.text) * 100).round();
      final costPriceCents = _costPriceController.text.isNotEmpty
          ? (double.parse(_costPriceController.text) * 100).round()
          : null;

      if (isEditing) {
        await database.into(database.products).insertOnConflictUpdate(
              ProductsCompanion.insert(
                id: productId,
                name: _nameController.text,
                description: Value(_descriptionController.text.isEmpty
                    ? null
                    : _descriptionController.text),
                barcode: Value(_barcodeController.text.isEmpty
                    ? null
                    : _barcodeController.text),
                sku: Value(
                    _skuController.text.isEmpty ? null : _skuController.text),
                categoryId: _selectedCategoryId!,
                basePriceCents: basePriceCents,
                costPriceCents: Value(costPriceCents),
                isActive: const Value(true),
                trackInventory: Value(_trackInventory),
                stockQuantity: Value(_stockQuantity),
                lowStockThreshold: Value(_lowStockThreshold ?? 5),
                createdAt: _existingProduct!.createdAt,
                updatedAt: now,
                syncVersion: Value(_existingProduct!.syncVersion + 1),
              ),
            );
      } else {
        await database.insertProduct(
          ProductsCompanion.insert(
            id: productId,
            name: _nameController.text,
            description: Value(_descriptionController.text.isEmpty
                ? null
                : _descriptionController.text),
            barcode: Value(_barcodeController.text.isEmpty
                ? null
                : _barcodeController.text),
            sku: Value(
                _skuController.text.isEmpty ? null : _skuController.text),
            categoryId: _selectedCategoryId!,
            basePriceCents: basePriceCents,
            costPriceCents: Value(costPriceCents),
            isActive: const Value(true),
            trackInventory: Value(_trackInventory),
            stockQuantity: Value(_stockQuantity),
            lowStockThreshold: Value(_lowStockThreshold ?? 5),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      // Save variants
      await database.deleteVariantsForProduct(productId);
      for (int i = 0; i < _variants.length; i++) {
        final variant = _variants[i];
        if (variant.name.isEmpty) continue;
        await database.insertVariant(
          VariantsCompanion.insert(
            id: variant.id ?? const Uuid().v4(),
            productId: productId,
            name: variant.name,
            priceAdjustmentCents: Value((variant.priceAdjustment * 100).round()),
            barcode: Value(variant.barcode),
            sortOrder: Value(i),
            isActive: const Value(true),
          ),
        );
      }

      // Save modifier group links
      await database.setProductModifierGroups(
          productId, _linkedModifierGroupIds);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Product updated' : 'Product created'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/cms/products');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text(
          'Are you sure you want to delete "${_existingProduct!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await database.deleteProduct(_existingProduct!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/cms/products');
      }
    }
  }
}

class _VariantForm {
  String? id;
  String name;
  double priceAdjustment;
  String? barcode;

  _VariantForm({
    this.id,
    required this.name,
    required this.priceAdjustment,
    this.barcode,
  });
}

class _VariantRow extends StatelessWidget {
  final _VariantForm variant;
  final Function(_VariantForm) onChanged;
  final VoidCallback onDelete;

  const _VariantRow({
    required this.variant,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: variant.name,
              decoration: const InputDecoration(
                labelText: 'Variant Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onChanged(_VariantForm(
                id: variant.id,
                name: v,
                priceAdjustment: variant.priceAdjustment,
                barcode: variant.barcode,
              )),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              initialValue: variant.priceAdjustment != 0
                  ? variant.priceAdjustment.toStringAsFixed(2)
                  : '',
              decoration: const InputDecoration(
                labelText: '+/- Price',
                prefixText: '\$',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => onChanged(_VariantForm(
                id: variant.id,
                name: variant.name,
                priceAdjustment: double.tryParse(v) ?? 0,
                barcode: variant.barcode,
              )),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
