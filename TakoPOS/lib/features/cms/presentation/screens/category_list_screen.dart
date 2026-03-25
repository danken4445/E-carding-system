import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/database/database.dart';
import 'package:takopos/main.dart';

/// Provider for watching all categories
final categoriesStreamProvider = StreamProvider<List<Category>>((ref) {
  return database.watchAllCategories();
});

/// Category list management screen
class CategoryListScreen extends ConsumerWidget {
  const CategoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cms'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCategoryDialog(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        backgroundColor: AppColors.primary,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (categories) {
          if (categories.isEmpty) {
            return _buildEmptyState(context, ref);
          }
          return _buildCategoryList(context, ref, categories);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: AppColors.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No categories yet',
            style: AppTextStyles.headline3.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Create your first category to organize products',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    WidgetRef ref,
    List<Category> categories,
  ) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: categories.length,
      onReorder: (oldIndex, newIndex) =>
          _reorderCategories(ref, categories, oldIndex, newIndex),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _CategoryCard(
          key: ValueKey(category.id),
          category: category,
          onEdit: () => _showCategoryDialog(context, ref, category),
          onDelete: () => _confirmDelete(context, ref, category),
        );
      },
    );
  }

  Future<void> _reorderCategories(
    WidgetRef ref,
    List<Category> categories,
    int oldIndex,
    int newIndex,
  ) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reordered = List<Category>.from(categories);
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);

    // Update sort order for all categories
    for (int i = 0; i < reordered.length; i++) {
      final cat = reordered[i];
      if (cat.sortOrder != i) {
        await database.updateCategory(
          CategoriesCompanion(
            id: Value(cat.id),
            name: Value(cat.name),
            description: Value(cat.description),
            sortOrder: Value(i),
            colorHex: Value(cat.colorHex),
            iconName: Value(cat.iconName),
            isActive: Value(cat.isActive),
            createdAt: Value(cat.createdAt),
            updatedAt: Value(DateTime.now()),
            syncVersion: Value(cat.syncVersion + 1),
          ),
        );
      }
    }
  }

  void _showCategoryDialog(
    BuildContext context,
    WidgetRef ref,
    Category? category,
  ) {
    showDialog(
      context: context,
      builder: (context) => _CategoryFormDialog(category: category),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\n'
          'Products in this category will need to be reassigned.',
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
      await database.deleteCategory(category.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${category.name} deleted'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = category.colorHex != null
        ? Color(int.parse(category.colorHex!.replaceFirst('#', '0xFF')))
        : AppColors.categoryColors[0];

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            Icons.category,
            color: color,
          ),
        ),
        title: Text(
          category.name,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: category.description != null
            ? Text(
                category.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: AppColors.error,
              tooltip: 'Delete',
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormDialog extends ConsumerStatefulWidget {
  final Category? category;

  const _CategoryFormDialog({this.category});

  @override
  ConsumerState<_CategoryFormDialog> createState() =>
      _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorIndex = 0;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');

    if (widget.category?.colorHex != null) {
      final colorValue =
          int.parse(widget.category!.colorHex!.replaceFirst('#', '0xFF'));
      _selectedColorIndex = AppColors.categoryColors.indexWhere(
        (c) => c.value == colorValue,
      );
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'New Category'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Color', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(
                  AppColors.categoryColors.length,
                  (index) => _ColorChip(
                    color: AppColors.categoryColors[index],
                    isSelected: _selectedColorIndex == index,
                    onTap: () => setState(() => _selectedColorIndex = index),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final colorHex =
        '#${AppColors.categoryColors[_selectedColorIndex].value.toRadixString(16).substring(2).toUpperCase()}';

    if (isEditing) {
      await database.updateCategory(
        CategoriesCompanion(
          id: Value(widget.category!.id),
          name: Value(_nameController.text),
          description: Value(_descriptionController.text.isEmpty
              ? null
              : _descriptionController.text),
          sortOrder: Value(widget.category!.sortOrder),
          colorHex: Value(colorHex),
          iconName: Value(widget.category!.iconName),
          isActive: Value(widget.category!.isActive),
          createdAt: Value(widget.category!.createdAt),
          updatedAt: Value(now),
          syncVersion: Value(widget.category!.syncVersion + 1),
        ),
      );
    } else {
      final categories = await database.getAllCategories();
      await database.insertCategory(
        CategoriesCompanion.insert(
          id: const Uuid().v4(),
          name: _nameController.text,
          description: Value(_descriptionController.text.isEmpty
              ? null
              : _descriptionController.text),
          sortOrder: Value(categories.length),
          colorHex: Value(colorHex),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Category updated' : 'Category created',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}

class _ColorChip extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorChip({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }
}
