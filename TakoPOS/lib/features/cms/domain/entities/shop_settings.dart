import 'package:hive/hive.dart';

/// Shop settings stored in Hive for fast local access
class ShopSettings {
  /// Business name displayed on receipts and UI
  final String businessName;

  /// Path to logo image (local file)
  final String? logoPath;

  /// Business contact phone number
  final String? contactPhone;

  /// Business contact email
  final String? contactEmail;

  /// Business address
  final String? address;

  /// Primary theme color (stored as Color.value int)
  final int primaryColorValue;

  /// Accent theme color (stored as Color.value int)
  final int accentColorValue;

  /// Custom text for receipt header
  final String? receiptHeader;

  /// Custom text for receipt footer
  final String? receiptFooter;

  /// Whether to show logo on receipts
  final bool showLogoOnReceipt;

  /// Whether to show address on receipts
  final bool showAddressOnReceipt;

  /// Whether to show contact info on receipts
  final bool showContactOnReceipt;

  /// Currency symbol (e.g., "$", "PHP", "€")
  final String currencySymbol;

  /// Currency code (e.g., "USD", "PHP", "EUR")
  final String currencyCode;

  /// Tax rate as decimal (e.g., 0.12 for 12%)
  final double taxRate;

  /// Whether prices include tax
  final bool taxInclusive;

  const ShopSettings({
    this.businessName = 'My Shop',
    this.logoPath,
    this.contactPhone,
    this.contactEmail,
    this.address,
    this.primaryColorValue = 0xFF1E88E5, // Blue
    this.accentColorValue = 0xFF26A69A, // Teal
    this.receiptHeader,
    this.receiptFooter,
    this.showLogoOnReceipt = true,
    this.showAddressOnReceipt = true,
    this.showContactOnReceipt = true,
    this.currencySymbol = '\$',
    this.currencyCode = 'USD',
    this.taxRate = 0.0,
    this.taxInclusive = false,
  });

  /// Create a copy with updated fields
  ShopSettings copyWith({
    String? businessName,
    String? logoPath,
    String? contactPhone,
    String? contactEmail,
    String? address,
    int? primaryColorValue,
    int? accentColorValue,
    String? receiptHeader,
    String? receiptFooter,
    bool? showLogoOnReceipt,
    bool? showAddressOnReceipt,
    bool? showContactOnReceipt,
    String? currencySymbol,
    String? currencyCode,
    double? taxRate,
    bool? taxInclusive,
  }) {
    return ShopSettings(
      businessName: businessName ?? this.businessName,
      logoPath: logoPath ?? this.logoPath,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      address: address ?? this.address,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      accentColorValue: accentColorValue ?? this.accentColorValue,
      receiptHeader: receiptHeader ?? this.receiptHeader,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      showLogoOnReceipt: showLogoOnReceipt ?? this.showLogoOnReceipt,
      showAddressOnReceipt: showAddressOnReceipt ?? this.showAddressOnReceipt,
      showContactOnReceipt: showContactOnReceipt ?? this.showContactOnReceipt,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
    );
  }

  /// Convert to JSON map for Hive storage
  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'logoPath': logoPath,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'address': address,
      'primaryColorValue': primaryColorValue,
      'accentColorValue': accentColorValue,
      'receiptHeader': receiptHeader,
      'receiptFooter': receiptFooter,
      'showLogoOnReceipt': showLogoOnReceipt,
      'showAddressOnReceipt': showAddressOnReceipt,
      'showContactOnReceipt': showContactOnReceipt,
      'currencySymbol': currencySymbol,
      'currencyCode': currencyCode,
      'taxRate': taxRate,
      'taxInclusive': taxInclusive,
    };
  }

  /// Create from JSON map
  factory ShopSettings.fromJson(Map<String, dynamic> json) {
    return ShopSettings(
      businessName: json['businessName'] as String? ?? 'My Shop',
      logoPath: json['logoPath'] as String?,
      contactPhone: json['contactPhone'] as String?,
      contactEmail: json['contactEmail'] as String?,
      address: json['address'] as String?,
      primaryColorValue: json['primaryColorValue'] as int? ?? 0xFF1E88E5,
      accentColorValue: json['accentColorValue'] as int? ?? 0xFF26A69A,
      receiptHeader: json['receiptHeader'] as String?,
      receiptFooter: json['receiptFooter'] as String?,
      showLogoOnReceipt: json['showLogoOnReceipt'] as bool? ?? true,
      showAddressOnReceipt: json['showAddressOnReceipt'] as bool? ?? true,
      showContactOnReceipt: json['showContactOnReceipt'] as bool? ?? true,
      currencySymbol: json['currencySymbol'] as String? ?? '\$',
      currencyCode: json['currencyCode'] as String? ?? 'USD',
      taxRate: (json['taxRate'] as num?)?.toDouble() ?? 0.0,
      taxInclusive: json['taxInclusive'] as bool? ?? false,
    );
  }
}

/// Hive TypeAdapter for ShopSettings
class ShopSettingsAdapter extends TypeAdapter<ShopSettings> {
  @override
  final int typeId = 10;

  @override
  ShopSettings read(BinaryReader reader) {
    final map = reader.readMap().cast<String, dynamic>();
    return ShopSettings.fromJson(map);
  }

  @override
  void write(BinaryWriter writer, ShopSettings obj) {
    writer.writeMap(obj.toJson());
  }
}
