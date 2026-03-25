import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/core/utils/money.dart';
import 'package:takopos/core/database/database.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';
import 'package:takopos/features/checkout/presentation/widgets/numeric_keypad.dart';
import 'package:takopos/platforms/hardware/printer/printer_interface.dart';
import 'package:takopos/platforms/hardware/printer/printer_provider.dart';
import 'package:takopos/main.dart';
import 'dart:convert';

/// Cash payment screen with exact change calculator
class CashPaymentScreen extends ConsumerStatefulWidget {
  const CashPaymentScreen({super.key});

  @override
  ConsumerState<CashPaymentScreen> createState() => _CashPaymentScreenState();
}

class _CashPaymentScreenState extends ConsumerState<CashPaymentScreen> {
  String _tenderedInput = '';

  Money get _tendered {
    if (_tenderedInput.isEmpty) return const Money.zero();
    return Money.tryParse(_tenderedInput) ?? const Money.zero();
  }

  Money get _total => ref.read(cartProvider).total;

  Money get _change {
    if (_tendered < _total) return const Money.zero();
    return _tendered - _total;
  }

  bool get _canComplete => _tendered >= _total;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/checkout'),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Order total
            _buildTotalSection(cart.total),
            const Divider(height: 1),
            // Amount tendered and change
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Tendered amount display
                    _buildTenderedDisplay(),
                    const SizedBox(height: AppSpacing.md),
                    // Change display
                    _buildChangeDisplay(),
                    const SizedBox(height: AppSpacing.lg),
                    // Quick cash buttons
                    _buildQuickCashButtons(),
                    const SizedBox(height: AppSpacing.lg),
                    // Numeric keypad
                    Expanded(
                      child: NumericKeypad(
                        value: _tenderedInput,
                        onValueChanged: (value) {
                          setState(() => _tenderedInput = value);
                        },
                        allowDecimal: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Complete payment button
            _buildCompleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalSection(Money total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.surfaceVariant,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Due',
            style: AppTextStyles.headline3,
          ),
          Text(
            total.format(),
            style: AppTextStyles.cartTotal.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenderedDisplay() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Amount Tendered',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _tenderedInput.isEmpty ? '\$0.00' : '\$${_formatInput()}',
            style: AppTextStyles.keypadDisplay.copyWith(
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatInput() {
    if (_tenderedInput.isEmpty) return '0.00';
    // If no decimal point, show as-is with .00
    if (!_tenderedInput.contains('.')) {
      return '$_tenderedInput.00';
    }
    // If has decimal, pad cents to 2 digits
    final parts = _tenderedInput.split('.');
    final cents = parts.length > 1 ? parts[1].padRight(2, '0') : '00';
    return '${parts[0]}.${cents.substring(0, cents.length.clamp(0, 2))}';
  }

  Widget _buildChangeDisplay() {
    final isEnough = _tendered >= _total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isEnough ? AppColors.successLight : AppColors.surfaceVariant,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isEnough ? 'Change Due' : 'Still Due',
            style: AppTextStyles.bodyLarge,
          ),
          Text(
            isEnough ? _change.format() : (_total - _tendered).format(),
            style: AppTextStyles.headline2.copyWith(
              color: isEnough ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCashButtons() {
    // Common bill denominations
    final quickAmounts = <Money>[
      _total, // Exact amount
      Money.fromDouble(5),
      Money.fromDouble(10),
      Money.fromDouble(20),
      Money.fromDouble(50),
      Money.fromDouble(100),
    ];

    // Filter to only show amounts >= total
    final relevantAmounts = quickAmounts.where((a) => a >= _total).toList();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        // Exact amount button
        _QuickCashButton(
          label: 'Exact\n${_total.format()}',
          isHighlighted: true,
          onTap: () {
            setState(() => _tenderedInput = _total.toDouble().toString());
          },
        ),
        // Common denominations
        for (final amount
            in relevantAmounts.where((a) => a != _total).take(5))
          _QuickCashButton(
            label: amount.format(showCents: false),
            onTap: () {
              setState(
                  () => _tenderedInput = amount.toDouble().toStringAsFixed(2));
            },
          ),
      ],
    );
  }

  Widget _buildCompleteButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizing.buttonHeightLarge,
        child: ElevatedButton(
          onPressed: _canComplete ? _completePayment : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _canComplete
                    ? 'Complete - Change ${_change.format()}'
                    : 'Enter Amount',
                style: AppTextStyles.buttonLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completePayment() async {
    final cart = ref.read(cartProvider);

    // Save transaction to database and enqueue for sync
    final transactionId = const Uuid().v4();
    try {
      await _saveTransaction(transactionId, cart);
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Show success dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 32),
            const SizedBox(width: AppSpacing.sm),
            const Text('Payment Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentRow(label: 'Total', value: _total.format()),
            _PaymentRow(label: 'Cash Received', value: _tendered.format()),
            const Divider(),
            _PaymentRow(
              label: 'Change',
              value: _change.format(),
              isHighlighted: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _printReceipt(cart, transactionId),
            child: const Text('Print Receipt'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.of(context).pop();
              context.go('/');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('New Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTransaction(String transactionId, cart) async {
    final now = DateTime.now();

    // Save transaction
    await database.insertTransaction(
      TransactionsCompanion.insert(
        id: transactionId,
        shiftId: const Value(null), // TODO: Add shift management
        subtotalCents: cart.subtotal.cents,
        discountCents: Value(cart.discountAmount.cents),
        taxCents: const Value(0), // MVP: no tax
        totalCents: cart.total.cents,
        status: 'completed',
        syncStatus: 'pending', // Mark for sync
        customerId: const Value(null),
        customerName: const Value(null),
        customerEmail: const Value(null),
        customerPhone: const Value(null),
        cashierId: '00000000-0000-0000-0000-000000000002', // Default cashier
        cashierName: const Value('Cashier'),
        notes: const Value(null),
        createdAt: now, // Raw DateTime, not wrapped in Value()
        completedAt: Value(now),
        syncVersion: const Value(0),
      ),
    );

    // Save transaction lines
    for (final item in cart.items) {
      final lineId = const Uuid().v4();
      await database.insertTransactionLine(
        TransactionLinesCompanion.insert(
          id: lineId,
          transactionId: transactionId,
          productId: item.product.id,
          productName: item.product.name,
          variantId: Value(item.variant?.id),
          variantName: Value(item.variant?.name),
          quantity: item.quantity,
          unitPriceCents: item.unitPrice.cents,
          lineTotalCents: item.total.cents,
          discountCents: Value(item.discount?.amount.cents ?? 0),
          discountReason: Value(item.discount?.reason),
          notes: Value(item.notes),
          modifiersJson: Value(
            item.selectedModifiers.isNotEmpty
                ? jsonEncode(item.selectedModifiers
                    .map((m) => {'id': m.id, 'name': m.name})
                    .toList())
                : null,
          ),
        ),
      );
    }

    // Save payment
    final paymentId = const Uuid().v4();
    await database.insertPayment(
      PaymentsCompanion.insert(
        id: paymentId,
        transactionId: transactionId,
        method: 'cash',
        amountCents: cart.total.cents,
        tenderedCents: Value(_tendered.cents),
        changeCents: Value(_change.cents),
        cardLast4: const Value(null),
        cardBrand: const Value(null),
        authorizationCode: const Value(null),
        externalPaymentId: const Value(null),
        status: 'approved',
        timestamp: now, // Raw DateTime, not wrapped in Value()
      ),
    );

    // Enqueue for sync to Supabase
    await database.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'transaction',
        entityId: transactionId,
        operation: 'create',
        payload: '', // Payload not needed since we fetch from DB
        queuedAt: now, // Raw DateTime, not wrapped in Value()
      ),
    );

    debugPrint('✓ Transaction $transactionId saved and queued for sync');
  }

  Future<void> _printReceipt(cart, String transactionId) async {
    final printer = ref.read(receiptPrinterProvider);

    // Convert cart to receipt data
    final receiptData = ReceiptData(
      receiptNumber: transactionId.substring(0, 8).toUpperCase(),
      timestamp: DateTime.now(),
      storeName: 'TakoPOS Demo Store',
      storeAddress: '123 Main Street, City, State 12345',
      storePhone: '(555) 123-4567',
      cashierName: 'Cashier',
      items: cart.items
          .map((item) => ReceiptItem(
                name: item.displayName,
                quantity: item.quantity,
                unitPrice: item.unitPrice,
                total: item.total,
                modifiers: item.selectedModifiers.map((m) => m.name).toList(),
                notes: item.notes,
              ))
          .toList(),
      subtotal: cart.subtotal,
      discount: cart.discountAmount,
      tax: const Money.zero(),
      total: cart.total,
      payment: PaymentDetails(
        method: 'Cash',
        amount: cart.total,
        tendered: _tendered,
        change: _change,
      ),
    );

    // Attempt to print
    final result = await printer.printReceipt(receiptData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'Receipt printed successfully'
                : 'Print failed: ${result.message}',
          ),
          backgroundColor:
              result.success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}

class _QuickCashButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _QuickCashButton({
    required this.label,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isHighlighted ? AppColors.primary : AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          constraints: const BoxConstraints(minWidth: 70),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isHighlighted
                  ? AppColors.textOnPrimary
                  : AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _PaymentRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isHighlighted
                ? AppTextStyles.headline3
                : AppTextStyles.bodyMedium,
          ),
          Text(
            value,
            style: isHighlighted
                ? AppTextStyles.headline2.copyWith(color: AppColors.success)
                : AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
          ),
        ],
      ),
    );
  }
}
