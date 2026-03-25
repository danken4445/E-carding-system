import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:takopos/platforms/hardware/printer/printer_interface.dart';

/// Mock printer implementation for testing
/// This simulates a thermal printer without actual hardware
class MockReceiptPrinter implements ReceiptPrinter {
  PrinterStatus _status = PrinterStatus.disconnected;
  final _statusController = StreamController<PrinterStatus>.broadcast();

  @override
  PrinterStatus get status => _status;

  @override
  Stream<PrinterStatus> get statusStream => _statusController.stream;

  @override
  bool get isConnected => _status == PrinterStatus.connected;

  void _updateStatus(PrinterStatus newStatus) {
    _status = newStatus;
    _statusController.add(newStatus);
  }

  @override
  Future<bool> connect(String identifier) async {
    debugPrint('MockPrinter: Connecting to $identifier');
    _updateStatus(PrinterStatus.connecting);

    // Simulate connection delay
    await Future.delayed(const Duration(seconds: 1));

    _updateStatus(PrinterStatus.connected);
    debugPrint('MockPrinter: Connected');
    return true;
  }

  @override
  Future<void> disconnect() async {
    debugPrint('MockPrinter: Disconnecting');
    _updateStatus(PrinterStatus.disconnected);
  }

  @override
  Future<PrintResult> printReceipt(ReceiptData receipt) async {
    if (!isConnected) {
      return PrintResult.failure('Printer not connected');
    }

    debugPrint('MockPrinter: Printing receipt ${receipt.receiptNumber}');
    _updateStatus(PrinterStatus.printing);

    // Simulate printing delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate receipt text for debugging
    final receiptText = _generateReceiptText(receipt);
    debugPrint('MockPrinter: Receipt content:\n$receiptText');

    _updateStatus(PrinterStatus.connected);
    return PrintResult.success();
  }

  @override
  Future<bool> openCashDrawer() async {
    if (!isConnected) return false;

    debugPrint('MockPrinter: Opening cash drawer');
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  @override
  Future<PrintResult> printTest() async {
    if (!isConnected) {
      return PrintResult.failure('Printer not connected');
    }

    debugPrint('MockPrinter: Printing test page');
    await Future.delayed(const Duration(seconds: 1));

    const testText = '''
========================================
           TEST RECEIPT
========================================
TakoPOS - Point of Sale System

Printer: Mock Thermal Printer
Status: Connected
Date: ${null} // Will be replaced

This is a test print.
If you can read this, the printer
is working correctly.

========================================
''';

    debugPrint(testText);
    return PrintResult.success();
  }

  @override
  Future<List<PrinterDevice>> discoverPrinters() async {
    debugPrint('MockPrinter: Discovering printers');
    await Future.delayed(const Duration(seconds: 2));

    // Return mock devices
    return [
      const PrinterDevice(
        id: 'mock-bt-001',
        name: 'Mock Bluetooth Printer 1',
        address: '00:11:22:33:44:55',
        type: PrinterType.bluetooth,
      ),
      const PrinterDevice(
        id: 'mock-bt-002',
        name: 'Mock Bluetooth Printer 2',
        address: '00:11:22:33:44:66',
        type: PrinterType.bluetooth,
      ),
      const PrinterDevice(
        id: 'mock-usb-001',
        name: 'Mock USB Printer',
        type: PrinterType.usb,
      ),
    ];
  }

  String _generateReceiptText(ReceiptData receipt) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('========================================');
    buffer.writeln('       ${receipt.storeName.toUpperCase()}');
    if (receipt.storeAddress != null) {
      buffer.writeln('    ${receipt.storeAddress}');
    }
    if (receipt.storePhone != null) {
      buffer.writeln('    ${receipt.storePhone}');
    }
    buffer.writeln('========================================');
    buffer.writeln();

    // Receipt info
    buffer.writeln('Receipt: ${receipt.receiptNumber}');
    buffer.writeln('Date: ${receipt.timestamp}');
    buffer.writeln('Cashier: ${receipt.cashierName}');
    buffer.writeln('----------------------------------------');
    buffer.writeln();

    // Items
    for (final item in receipt.items) {
      buffer.writeln('${item.quantity}x ${item.name}');
      buffer.writeln('   ${item.unitPrice.format()} ea   ${item.total.format()}');

      // Modifiers
      for (final modifier in item.modifiers) {
        buffer.writeln('   + $modifier');
      }

      // Notes
      if (item.notes != null && item.notes!.isNotEmpty) {
        buffer.writeln('   Note: ${item.notes}');
      }

      buffer.writeln();
    }

    buffer.writeln('----------------------------------------');

    // Totals
    buffer.writeln('Subtotal:        ${receipt.subtotal.format()}');

    if (receipt.discount.isPositive) {
      buffer.writeln('Discount:       -${receipt.discount.format()}');
    }

    if (receipt.tax.isPositive) {
      buffer.writeln('Tax:             ${receipt.tax.format()}');
    }

    buffer.writeln('========================================');
    buffer.writeln('TOTAL:           ${receipt.total.format()}');
    buffer.writeln('========================================');
    buffer.writeln();

    // Payment
    buffer.writeln('Payment Method: ${receipt.payment.method.toUpperCase()}');
    buffer.writeln('Amount:          ${receipt.payment.amount.format()}');

    if (receipt.payment.tendered != null) {
      buffer.writeln('Tendered:        ${receipt.payment.tendered!.format()}');
      buffer.writeln('Change:          ${receipt.payment.change!.format()}');
    }

    if (receipt.payment.cardLast4 != null) {
      buffer.writeln('Card: ${receipt.payment.cardBrand} ****${receipt.payment.cardLast4}');
    }

    buffer.writeln();

    // Notes
    if (receipt.notes != null && receipt.notes!.isNotEmpty) {
      buffer.writeln('Notes: ${receipt.notes}');
      buffer.writeln();
    }

    // Footer
    buffer.writeln('========================================');
    buffer.writeln('    Thank you for your business!');
    buffer.writeln('       Please come again!');
    buffer.writeln('========================================');

    return buffer.toString();
  }

  void dispose() {
    _statusController.close();
  }
}
