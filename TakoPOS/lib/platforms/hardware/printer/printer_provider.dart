import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:takopos/platforms/hardware/printer/printer_interface.dart';
import 'package:takopos/platforms/hardware/printer/mock_printer.dart';

/// Provider for the receipt printer
/// Currently uses MockReceiptPrinter for testing
/// Replace with actual printer implementation when ready
final receiptPrinterProvider = Provider<ReceiptPrinter>((ref) {
  return MockReceiptPrinter();
});

/// Provider for printer status stream
final printerStatusProvider = StreamProvider<PrinterStatus>((ref) {
  final printer = ref.watch(receiptPrinterProvider);
  return printer.statusStream;
});
