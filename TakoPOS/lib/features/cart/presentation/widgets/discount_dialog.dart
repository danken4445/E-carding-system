import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/utils/money.dart';
import 'package:takopos/features/cart/domain/entities/cart_entities.dart';
import 'package:uuid/uuid.dart';

/// Dialog for applying discounts (percentage or fixed amount)
class DiscountDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Function(Discount) onApply;

  const DiscountDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.onApply,
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  DiscountType _type = DiscountType.percentage;
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(widget.title, style: AppTextStyles.headline2),
              if (widget.subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.subtitle!,
                  style: AppTextStyles.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // Discount type selector
              Text('Discount Type', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _TypeButton(
                      label: 'Percentage',
                      icon: Icons.percent,
                      isSelected: _type == DiscountType.percentage,
                      onTap: () => setState(
                          () => _type = DiscountType.percentage),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _TypeButton(
                      label: 'Fixed',
                      icon: Icons.attach_money,
                      isSelected: _type == DiscountType.fixed,
                      onTap: () =>
                          setState(() => _type = DiscountType.fixed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Value input
              Text(
                _type == DiscountType.percentage
                    ? 'Percentage (%)'
                    : 'Amount (\$)',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _valueController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                decoration: InputDecoration(
                  hintText: _type == DiscountType.percentage
                      ? 'e.g., 10'
                      : 'e.g., 5.00',
                  prefixIcon: Icon(
                    _type == DiscountType.percentage
                        ? Icons.percent
                        : Icons.attach_money,
                  ),
                  errorText: _errorMessage,
                ),
                autofocus: true,
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              // Quick buttons for common discounts
              const SizedBox(height: AppSpacing.sm),
              _QuickButtons(
                type: _type,
                onSelect: (value) {
                  _valueController.text = value.toString();
                  setState(() {});
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Reason (optional)
              Text('Reason (optional)', style: AppTextStyles.bodyMedium),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  hintText: 'e.g., Employee discount, Damaged item',
                ),
                maxLines: 1,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  ElevatedButton(
                    onPressed: _applyDiscount,
                    child: const Text('Apply Discount'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyDiscount() {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      setState(() => _errorMessage = 'Please enter a value');
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (_type == DiscountType.percentage && value > 100) {
      setState(() => _errorMessage = 'Percentage cannot exceed 100%');
      return;
    }

    final discount = Discount(
      id: const Uuid().v4(),
      name: _type == DiscountType.percentage
          ? '$value% off'
          : '\$${value.toStringAsFixed(2)} off',
      type: _type,
      value: _type == DiscountType.percentage
          ? value
          : Money.fromDouble(value).cents.toDouble(),
      reason: _reasonController.text.trim().isNotEmpty
          ? _reasonController.text.trim()
          : null,
      appliedAt: DateTime.now(),
    );

    widget.onApply(discount);
    Navigator.of(context).pop();
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? AppColors.textOnPrimary
                    : AppColors.textPrimary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.textOnPrimary
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickButtons extends StatelessWidget {
  final DiscountType type;
  final Function(double) onSelect;

  const _QuickButtons({
    required this.type,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final values = type == DiscountType.percentage
        ? [5.0, 10.0, 15.0, 20.0, 25.0, 50.0]
        : [1.0, 2.0, 5.0, 10.0, 20.0, 50.0];

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: values.map((value) {
        final label = type == DiscountType.percentage
            ? '${value.toInt()}%'
            : '\$${value.toStringAsFixed(0)}';
        return ActionChip(
          label: Text(label),
          onPressed: () => onSelect(value),
          backgroundColor: AppColors.surfaceVariant,
        );
      }).toList(),
    );
  }
}
