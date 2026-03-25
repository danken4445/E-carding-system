import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/cms/presentation/providers/shop_settings_provider.dart';

/// Shop settings management screen
class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _businessNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _receiptHeaderController;
  late TextEditingController _receiptFooterController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _currencyCodeController;
  late TextEditingController _taxRateController;

  bool _taxInclusive = false;
  bool _showLogo = true;
  bool _showAddress = true;
  bool _showContact = true;
  int _primaryColor = 0xFF1E88E5;
  int _accentColor = 0xFF26A69A;

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _receiptHeaderController = TextEditingController();
    _receiptFooterController = TextEditingController();
    _currencySymbolController = TextEditingController();
    _currencyCodeController = TextEditingController();
    _taxRateController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    _currencySymbolController.dispose();
    _currencyCodeController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
      data: (settings) {
        // Initialize controllers with current settings
        if (_businessNameController.text.isEmpty) {
          _businessNameController.text = settings.businessName;
          _phoneController.text = settings.contactPhone ?? '';
          _emailController.text = settings.contactEmail ?? '';
          _addressController.text = settings.address ?? '';
          _receiptHeaderController.text = settings.receiptHeader ?? '';
          _receiptFooterController.text = settings.receiptFooter ?? '';
          _currencySymbolController.text = settings.currencySymbol;
          _currencyCodeController.text = settings.currencyCode;
          _taxRateController.text = (settings.taxRate * 100).toStringAsFixed(1);
          _taxInclusive = settings.taxInclusive;
          _showLogo = settings.showLogoOnReceipt;
          _showAddress = settings.showAddressOnReceipt;
          _showContact = settings.showContactOnReceipt;
          _primaryColor = settings.primaryColorValue;
          _accentColor = settings.accentColorValue;
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Shop Settings'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/cms'),
            ),
            actions: [
              TextButton.icon(
                onPressed: _saveSettings,
                icon: const Icon(Icons.save, color: AppColors.success),
                label: const Text(
                  'Save',
                  style: TextStyle(color: AppColors.success),
                ),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                _buildSection(
                  'Business Profile',
                  Icons.store,
                  [
                    _buildTextField(
                      controller: _businessNameController,
                      label: 'Business Name *',
                      icon: Icons.business,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  'Theme Colors',
                  Icons.palette,
                  [
                    _buildColorPicker(
                      'Primary Color',
                      _primaryColor,
                      (color) => setState(() => _primaryColor = color),
                    ),
                    _buildColorPicker(
                      'Accent Color',
                      _accentColor,
                      (color) => setState(() => _accentColor = color),
                    ),
                    _buildColorPreview(),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  'Receipt Settings',
                  Icons.receipt,
                  [
                    _buildTextField(
                      controller: _receiptHeaderController,
                      label: 'Header Text',
                      hint: 'e.g., Thank you for shopping!',
                      maxLines: 2,
                    ),
                    _buildTextField(
                      controller: _receiptFooterController,
                      label: 'Footer Text',
                      hint: 'e.g., Returns accepted within 30 days',
                      maxLines: 2,
                    ),
                    CheckboxListTile(
                      title: const Text('Show Logo on Receipt'),
                      value: _showLogo,
                      onChanged: (value) =>
                          setState(() => _showLogo = value ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Show Address on Receipt'),
                      value: _showAddress,
                      onChanged: (value) =>
                          setState(() => _showAddress = value ?? true),
                    ),
                    CheckboxListTile(
                      title: const Text('Show Contact Info on Receipt'),
                      value: _showContact,
                      onChanged: (value) =>
                          setState(() => _showContact = value ?? true),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildSection(
                  'Currency & Tax',
                  Icons.attach_money,
                  [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _currencySymbolController,
                            label: 'Symbol',
                            hint: '\$',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildTextField(
                            controller: _currencyCodeController,
                            label: 'Code',
                            hint: 'USD',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _taxRateController,
                            label: 'Tax Rate (%)',
                            hint: '12.0',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: CheckboxListTile(
                            title: const Text('Tax Inclusive'),
                            value: _taxInclusive,
                            onChanged: (value) =>
                                setState(() => _taxInclusive = value ?? false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppRadius.md),
                topRight: Radius.circular(AppRadius.md),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppTextStyles.headline3,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildColorPicker(
    String label,
    int colorValue,
    Function(int) onColorChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: () => _showColorPickerDialog(label, colorValue, onColorChanged),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: AppRadius.buttonRadius,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.divider),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.bodyMedium),
                    Text(
                      '#${colorValue.toRadixString(16).substring(2).toUpperCase()}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.edit, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Color(_primaryColor).withOpacity(0.1),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: Color(_primaryColor).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Color(_primaryColor),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Text(
              'Preview',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Color(_accentColor),
              borderRadius: AppRadius.buttonRadius,
            ),
            child: Text(
              'Accent',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(
    String label,
    int currentColor,
    Function(int) onColorChanged,
  ) {
    // Simple preset color picker
    final presetColors = [
      0xFF1E88E5, // Blue
      0xFF26A69A, // Teal
      0xFF66BB6A, // Green
      0xFFFF7043, // Orange
      0xFFEC407A, // Pink
      0xFF9C27B0, // Purple
      0xFFEF5350, // Red
      0xFF42A5F5, // Light Blue
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Choose $label'),
        content: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: presetColors.map((color) {
            final isSelected = color == currentColor;
            return InkWell(
              onTap: () {
                onColorChanged(color);
                Navigator.pop(context);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(color),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(
                    color: isSelected ? Colors.black : AppColors.divider,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedSettings = ref.read(currentShopSettingsProvider).copyWith(
          businessName: _businessNameController.text,
          contactPhone: _phoneController.text.isEmpty
              ? null
              : _phoneController.text,
          contactEmail: _emailController.text.isEmpty
              ? null
              : _emailController.text,
          address: _addressController.text.isEmpty
              ? null
              : _addressController.text,
          primaryColorValue: _primaryColor,
          accentColorValue: _accentColor,
          receiptHeader: _receiptHeaderController.text.isEmpty
              ? null
              : _receiptHeaderController.text,
          receiptFooter: _receiptFooterController.text.isEmpty
              ? null
              : _receiptFooterController.text,
          showLogoOnReceipt: _showLogo,
          showAddressOnReceipt: _showAddress,
          showContactOnReceipt: _showContact,
          currencySymbol: _currencySymbolController.text,
          currencyCode: _currencyCodeController.text,
          taxRate: double.tryParse(_taxRateController.text) != null
              ? double.parse(_taxRateController.text) / 100
              : 0.0,
          taxInclusive: _taxInclusive,
        );

    await ref.read(shopSettingsProvider.notifier).updateSettings(updatedSettings);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
