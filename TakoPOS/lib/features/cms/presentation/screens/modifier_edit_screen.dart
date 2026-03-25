import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/database/database.dart';
import 'package:takopos/main.dart';

/// Modifier group edit screen
class ModifierEditScreen extends ConsumerStatefulWidget {
  final String? groupId;

  const ModifierEditScreen({super.key, this.groupId});

  @override
  ConsumerState<ModifierEditScreen> createState() => _ModifierEditScreenState();
}

class _ModifierEditScreenState extends ConsumerState<ModifierEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameController;
  late TextEditingController _minSelectionsController;
  late TextEditingController _maxSelectionsController;

  ModifierGroup? _existingGroup;
  List<_ModifierForm> _modifiers = [];

  bool get isEditing => widget.groupId != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _minSelectionsController = TextEditingController(text: '0');
    _maxSelectionsController = TextEditingController(text: '1');
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minSelectionsController.dispose();
    _maxSelectionsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (isEditing) {
      final groups = await database.getAllModifierGroups();
      _existingGroup = groups.firstWhere(
        (g) => g.id == widget.groupId,
        orElse: () => throw Exception('Group not found'),
      );

      _nameController.text = _existingGroup!.name;
      _minSelectionsController.text = _existingGroup!.minSelections.toString();
      _maxSelectionsController.text = _existingGroup!.maxSelections.toString();

      final modifiers = await database.getAllModifiers();
      _modifiers = modifiers
          .where((m) => m.groupId == _existingGroup!.id)
          .map((m) => _ModifierForm(
                id: m.id,
                name: m.name,
                priceAdjustment: m.priceAdjustmentCents / 100,
                isDefault: m.isDefault,
              ))
          .toList();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? 'Edit Add-on Group' : 'New Add-on Group'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Add-on Group' : 'New Add-on Group'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/cms/modifiers'),
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
            _buildGroupSettings(),
            const SizedBox(height: AppSpacing.lg),
            _buildModifiersSection(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupSettings() {
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
                const Icon(Icons.settings, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Group Settings', style: AppTextStyles.headline3),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name *',
                    hintText: 'e.g., Size, Extras, Toppings',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minSelectionsController,
                        decoration: const InputDecoration(
                          labelText: 'Min Selections',
                          hintText: '0',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSelectionsController,
                        decoration: const InputDecoration(
                          labelText: 'Max Selections',
                          hintText: '1',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Min = 0: Optional selection. Min > 0: Required selection.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifiersSection() {
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
                const Icon(Icons.list, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Modifiers', style: AppTextStyles.headline3),
                const Spacer(),
                Text(
                  '${_modifiers.length} items',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                ..._modifiers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final modifier = entry.value;
                  return _ModifierRow(
                    modifier: modifier,
                    onChanged: (m) => setState(() => _modifiers[index] = m),
                    onDelete: () => setState(() => _modifiers.removeAt(index)),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _modifiers.add(_ModifierForm(
                        id: null,
                        name: '',
                        priceAdjustment: 0,
                        isDefault: false,
                      ));
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Modifier'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate at least one modifier
    final validModifiers = _modifiers.where((m) => m.name.isNotEmpty).toList();
    if (validModifiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one modifier')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final groupId = isEditing ? _existingGroup!.id : const Uuid().v4();

      if (isEditing) {
        await database.updateModifierGroup(
          ModifierGroupsCompanion(
            id: Value(groupId),
            name: Value(_nameController.text),
            minSelections:
                Value(int.tryParse(_minSelectionsController.text) ?? 0),
            maxSelections:
                Value(int.tryParse(_maxSelectionsController.text) ?? 1),
            sortOrder: Value(_existingGroup!.sortOrder),
          ),
        );

        // Delete existing modifiers and recreate
        final existingModifiers = await database.getAllModifiers();
        for (final m in existingModifiers.where((m) => m.groupId == groupId)) {
          await database.deleteModifier(m.id);
        }
      } else {
        final groups = await database.getAllModifierGroups();
        await database.insertModifierGroup(
          ModifierGroupsCompanion.insert(
            id: groupId,
            name: _nameController.text,
            minSelections:
                Value(int.tryParse(_minSelectionsController.text) ?? 0),
            maxSelections:
                Value(int.tryParse(_maxSelectionsController.text) ?? 1),
            sortOrder: Value(groups.length),
          ),
        );
      }

      // Save modifiers
      for (int i = 0; i < validModifiers.length; i++) {
        final modifier = validModifiers[i];
        await database.insertModifier(
          ModifiersCompanion.insert(
            id: modifier.id ?? const Uuid().v4(),
            groupId: groupId,
            name: modifier.name,
            priceAdjustmentCents: Value((modifier.priceAdjustment * 100).round()),
            isDefault: Value(modifier.isDefault),
            sortOrder: Value(i),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? 'Group updated' : 'Group created'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/cms/modifiers');
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
        title: const Text('Delete Add-on Group'),
        content: Text(
          'Are you sure you want to delete "${_existingGroup!.name}"?',
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
      await database.deleteModifierGroup(_existingGroup!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group deleted'),
            backgroundColor: AppColors.error,
          ),
        );
        context.go('/cms/modifiers');
      }
    }
  }
}

class _ModifierForm {
  String? id;
  String name;
  double priceAdjustment;
  bool isDefault;

  _ModifierForm({
    this.id,
    required this.name,
    required this.priceAdjustment,
    required this.isDefault,
  });
}

class _ModifierRow extends StatelessWidget {
  final _ModifierForm modifier;
  final Function(_ModifierForm) onChanged;
  final VoidCallback onDelete;

  const _ModifierRow({
    required this.modifier,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        children: [
          Checkbox(
            value: modifier.isDefault,
            onChanged: (v) => onChanged(_ModifierForm(
              id: modifier.id,
              name: modifier.name,
              priceAdjustment: modifier.priceAdjustment,
              isDefault: v ?? false,
            )),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: modifier.name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => onChanged(_ModifierForm(
                id: modifier.id,
                name: v,
                priceAdjustment: modifier.priceAdjustment,
                isDefault: modifier.isDefault,
              )),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextFormField(
              initialValue: modifier.priceAdjustment != 0
                  ? modifier.priceAdjustment.toStringAsFixed(2)
                  : '',
              decoration: const InputDecoration(
                labelText: '+Price',
                prefixText: '\$',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => onChanged(_ModifierForm(
                id: modifier.id,
                name: modifier.name,
                priceAdjustment: double.tryParse(v) ?? 0,
                isDefault: modifier.isDefault,
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
