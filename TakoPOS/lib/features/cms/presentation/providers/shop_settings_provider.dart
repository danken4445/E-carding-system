import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:takopos/features/cms/domain/entities/shop_settings.dart';

/// Hive box name for shop settings
const _shopSettingsBoxName = 'shop_settings';
const _shopSettingsKey = 'settings';

/// Provider for the shop settings Hive box
final shopSettingsBoxProvider = FutureProvider<Box<ShopSettings>>((ref) async {
  return Hive.openBox<ShopSettings>(_shopSettingsBoxName);
});

/// Provider for current shop settings
final shopSettingsProvider =
    StateNotifierProvider<ShopSettingsNotifier, AsyncValue<ShopSettings>>((ref) {
  return ShopSettingsNotifier(ref);
});

/// StateNotifier for shop settings management
class ShopSettingsNotifier extends StateNotifier<AsyncValue<ShopSettings>> {
  final Ref _ref;

  ShopSettingsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }

  /// Load settings from Hive
  Future<void> _loadSettings() async {
    try {
      final box = await _ref.read(shopSettingsBoxProvider.future);
      final settings = box.get(_shopSettingsKey) ?? const ShopSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update and persist settings
  Future<void> updateSettings(ShopSettings settings) async {
    try {
      final box = await _ref.read(shopSettingsBoxProvider.future);
      await box.put(_shopSettingsKey, settings);
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update business name
  Future<void> updateBusinessName(String name) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(businessName: name));
  }

  /// Update logo path
  Future<void> updateLogo(String? logoPath) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(logoPath: logoPath));
  }

  /// Update contact information
  Future<void> updateContact({
    String? phone,
    String? email,
    String? address,
  }) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(
      contactPhone: phone ?? current.contactPhone,
      contactEmail: email ?? current.contactEmail,
      address: address ?? current.address,
    ));
  }

  /// Update theme colors
  Future<void> updateThemeColors({
    int? primaryColor,
    int? accentColor,
  }) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(
      primaryColorValue: primaryColor ?? current.primaryColorValue,
      accentColorValue: accentColor ?? current.accentColorValue,
    ));
  }

  /// Update receipt settings
  Future<void> updateReceiptSettings({
    String? header,
    String? footer,
    bool? showLogo,
    bool? showAddress,
    bool? showContact,
  }) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(
      receiptHeader: header ?? current.receiptHeader,
      receiptFooter: footer ?? current.receiptFooter,
      showLogoOnReceipt: showLogo ?? current.showLogoOnReceipt,
      showAddressOnReceipt: showAddress ?? current.showAddressOnReceipt,
      showContactOnReceipt: showContact ?? current.showContactOnReceipt,
    ));
  }

  /// Update currency settings
  Future<void> updateCurrencySettings({
    String? symbol,
    String? code,
    double? taxRate,
    bool? taxInclusive,
  }) async {
    final current = state.valueOrNull ?? const ShopSettings();
    await updateSettings(current.copyWith(
      currencySymbol: symbol ?? current.currencySymbol,
      currencyCode: code ?? current.currencyCode,
      taxRate: taxRate ?? current.taxRate,
      taxInclusive: taxInclusive ?? current.taxInclusive,
    ));
  }
}

/// Convenience provider for accessing settings synchronously (with fallback)
final currentShopSettingsProvider = Provider<ShopSettings>((ref) {
  final asyncSettings = ref.watch(shopSettingsProvider);
  return asyncSettings.valueOrNull ?? const ShopSettings();
});
