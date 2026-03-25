import 'package:takopos/core/utils/money.dart';

/// Receipt data to be printed
class ReceiptData {
  final String receiptNumber;
  final DateTime timestamp;
  final String storeName;
  final String? storeAddress;
  final String? storePhone;
  final String cashierName;
  final List<ReceiptItem> items;
  final Money subtotal;
  final Money discount;
  final Money tax;
  final Money total;
  final PaymentDetails payment;
  final String? notes;

  const ReceiptData({
    required this.receiptNumber,
    required this.timestamp,
    required this.storeName,
    this.storeAddress,
    this.storePhone,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.payment,
    this.notes,
  });
}

/// Individual item on the receipt
class ReceiptItem {
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money total;
  final List<String> modifiers;
  final String? notes;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.modifiers = const [],
    this.notes,
  });
}

/// Payment details for the receipt
class PaymentDetails {
  final String method; // cash, card, etc.
  final Money amount;
  final Money? tendered;
  final Money? change;
  final String? cardLast4;
  final String? cardBrand;

  const PaymentDetails({
    required this.method,
    required this.amount,
    this.tendered,
    this.change,
    this.cardLast4,
    this.cardBrand,
  });
}

/// Result of a print operation
class PrintResult {
  final bool success;
  final String? message;
  final DateTime timestamp;

  const PrintResult({
    required this.success,
    this.message,
    required this.timestamp,
  });

  factory PrintResult.success() {
    return PrintResult(
      success: true,
      timestamp: DateTime.now(),
    );
  }

  factory PrintResult.failure(String message) {
    return PrintResult(
      success: false,
      message: message,
      timestamp: DateTime.now(),
    );
  }
}

/// Printer status
enum PrinterStatus {
  disconnected,
  connecting,
  connected,
  printing,
  error,
}

/// Abstract interface for receipt printers
abstract class ReceiptPrinter {
  /// Get current printer status
  PrinterStatus get status;

  /// Stream of status changes
  Stream<PrinterStatus> get statusStream;

  /// Check if printer is connected
  bool get isConnected;

  /// Connect to a printer
  /// [identifier] could be Bluetooth address, IP address, or device name
  Future<bool> connect(String identifier);

  /// Disconnect from the printer
  Future<void> disconnect();

  /// Print a receipt
  Future<PrintResult> printReceipt(ReceiptData receipt);

  /// Open the cash drawer (if supported)
  Future<bool> openCashDrawer();

  /// Test print to verify connection
  Future<PrintResult> printTest();

  /// Discover available printers
  Future<List<PrinterDevice>> discoverPrinters();
}

/// Represents a discoverable printer device
class PrinterDevice {
  final String id;
  final String name;
  final String? address;
  final PrinterType type;

  const PrinterDevice({
    required this.id,
    required this.name,
    this.address,
    required this.type,
  });
}

/// Type of printer connection
enum PrinterType {
  bluetooth,
  usb,
  network,
  unknown,
}
