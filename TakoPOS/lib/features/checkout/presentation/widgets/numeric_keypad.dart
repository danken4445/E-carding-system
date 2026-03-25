import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:takopos/core/theme/app_theme.dart';

/// Numeric keypad for cash entry
class NumericKeypad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onValueChanged;
  final bool allowDecimal;
  final int maxDigits;

  const NumericKeypad({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.allowDecimal = true,
    this.maxDigits = 10,
  });

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();

    String newValue = value;

    if (key == 'C') {
      // Clear all
      newValue = '';
    } else if (key == 'backspace') {
      // Delete last character
      if (newValue.isNotEmpty) {
        newValue = newValue.substring(0, newValue.length - 1);
      }
    } else if (key == '.') {
      // Decimal point
      if (allowDecimal && !newValue.contains('.')) {
        newValue = newValue.isEmpty ? '0.' : '$newValue.';
      }
    } else if (key == '00') {
      // Double zero
      if (newValue.length + 2 <= maxDigits) {
        newValue = '$newValue$key';
      }
    } else {
      // Digit
      if (newValue.length < maxDigits) {
        // Don't allow leading zeros (except for "0.")
        if (newValue == '0' && key != '.') {
          newValue = key;
        } else {
          // Check decimal places (max 2)
          if (newValue.contains('.')) {
            final decimalIndex = newValue.indexOf('.');
            if (newValue.length - decimalIndex > 2) {
              return; // Already 2 decimal places
            }
          }
          newValue = '$newValue$key';
        }
      }
    }

    onValueChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate button size based on available space
        final buttonWidth = (constraints.maxWidth - AppSpacing.sm * 2) / 3;
        final buttonHeight = (constraints.maxHeight - AppSpacing.sm * 3) / 4;
        final size = Size(buttonWidth, buttonHeight.clamp(60, 90));

        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildRow(['1', '2', '3'], size),
            _buildRow(['4', '5', '6'], size),
            _buildRow(['7', '8', '9'], size),
            _buildRow(['C', '0', 'backspace'], size),
          ],
        );
      },
    );
  }

  Widget _buildRow(List<String> keys, Size buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _KeypadButton(
        keyValue: key,
        size: buttonSize,
        onPressed: () => _onKeyPressed(key),
      )).toList(),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  final String keyValue;
  final Size size;
  final VoidCallback onPressed;

  const _KeypadButton({
    required this.keyValue,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isAction = keyValue == 'C' || keyValue == 'backspace';
    final displayContent = _getDisplayContent();

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Material(
        color: isAction ? AppColors.surfaceVariant : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        elevation: 1,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(child: displayContent),
        ),
      ),
    );
  }

  Widget _getDisplayContent() {
    if (keyValue == 'backspace') {
      return Icon(
        Icons.backspace_outlined,
        size: 28,
        color: AppColors.textPrimary,
      );
    }
    if (keyValue == 'C') {
      return Text(
        'C',
        style: AppTextStyles.keypadNumber.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Text(
      keyValue,
      style: AppTextStyles.keypadNumber,
    );
  }
}

/// PIN pad for staff authentication
class PinPad extends StatelessWidget {
  final String value;
  final ValueChanged<String> onValueChanged;
  final int pinLength;

  const PinPad({
    super.key,
    required this.value,
    required this.onValueChanged,
    this.pinLength = 4,
  });

  void _onKeyPressed(String key) {
    HapticFeedback.lightImpact();

    String newValue = value;

    if (key == 'C') {
      newValue = '';
    } else if (key == 'backspace') {
      if (newValue.isNotEmpty) {
        newValue = newValue.substring(0, newValue.length - 1);
      }
    } else if (newValue.length < pinLength) {
      newValue = '$newValue$key';
    }

    onValueChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots
        _buildPinDisplay(),
        const SizedBox(height: AppSpacing.lg),
        // Keypad
        _buildKeypad(),
      ],
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pinLength, (index) {
        final isFilled = index < value.length;
        return Container(
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isFilled ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad() {
    const buttonSize = Size(80, 60);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildRow(['1', '2', '3'], buttonSize),
        const SizedBox(height: AppSpacing.sm),
        _buildRow(['4', '5', '6'], buttonSize),
        const SizedBox(height: AppSpacing.sm),
        _buildRow(['7', '8', '9'], buttonSize),
        const SizedBox(height: AppSpacing.sm),
        _buildRow(['C', '0', 'backspace'], buttonSize),
      ],
    );
  }

  Widget _buildRow(List<String> keys, Size buttonSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: keys.map((key) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: _PinButton(
            keyValue: key,
            size: buttonSize,
            onPressed: () => _onKeyPressed(key),
          ),
        );
      }).toList(),
    );
  }
}

class _PinButton extends StatelessWidget {
  final String keyValue;
  final Size size;
  final VoidCallback onPressed;

  const _PinButton({
    required this.keyValue,
    required this.size,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Center(
            child: keyValue == 'backspace'
                ? const Icon(Icons.backspace_outlined, size: 24)
                : Text(
                    keyValue,
                    style: AppTextStyles.headline2,
                  ),
          ),
        ),
      ),
    );
  }
}
