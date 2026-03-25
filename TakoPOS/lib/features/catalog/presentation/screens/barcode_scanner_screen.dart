import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:takopos/core/theme/app_theme.dart';
import 'package:takopos/features/catalog/domain/entities/catalog_entities.dart';
import 'package:takopos/features/catalog/presentation/providers/catalog_provider.dart';
import 'package:takopos/features/cart/presentation/providers/cart_provider.dart';

/// Barcode scanner screen using device camera
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() =>
      _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  String? _lastScannedCode;
  ProductEntity? _foundProduct;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          // Torch toggle
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
          // Camera switch
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
            tooltip: 'Switch Camera',
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner view
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: _onBarcodeDetected,
                ),
                // Scan overlay
                _buildScanOverlay(),
                // Processing indicator
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Result panel
          Expanded(
            flex: 2,
            child: _buildResultPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: 280,
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(
            color: _foundProduct != null
                ? AppColors.success
                : AppColors.textOnPrimary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Point camera at barcode',
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Last scanned code
          if (_lastScannedCode != null) ...[
            Text(
              'Scanned: $_lastScannedCode',
              style: AppTextStyles.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          // Error message
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: AppRadius.cardRadius,
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppColors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
          // Found product
          if (_foundProduct != null) ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Product Found',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _foundProduct!.name,
                      style: AppTextStyles.headline3,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _foundProduct!.basePrice.format(),
                      style: AppTextStyles.productPrice,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _scanAgain,
                            child: const Text('Scan Another'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _addToCart,
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('Add to Cart'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          // No product found yet
          if (_foundProduct == null && _errorMessage == null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Scan a product barcode',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;
    if (capture.barcodes.isEmpty) return;

    final barcode = capture.barcodes.first;
    final code = barcode.rawValue;

    if (code == null || code.isEmpty) return;
    if (code == _lastScannedCode && _foundProduct != null) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
      _errorMessage = null;
      _foundProduct = null;
    });

    // Look up product by barcode
    _lookupProduct(code);
  }

  void _lookupProduct(String barcode) {
    final products = ref.read(allProductsProvider);

    // Search in products by barcode
    ProductEntity? product;

    for (final p in products) {
      if (p.barcode == barcode) {
        product = p;
        break;
      }
      // Also check variant barcodes
      for (final v in p.variants) {
        if (v.barcode == barcode) {
          product = p;
          break;
        }
      }
      if (product != null) break;
    }

    setState(() {
      _isProcessing = false;
      if (product != null) {
        _foundProduct = product;
        _errorMessage = null;
      } else {
        _foundProduct = null;
        _errorMessage = 'Product not found for barcode: $barcode';
      }
    });
  }

  void _scanAgain() {
    setState(() {
      _foundProduct = null;
      _errorMessage = null;
      _lastScannedCode = null;
    });
  }

  void _addToCart() {
    if (_foundProduct == null) return;

    ref.read(cartProvider.notifier).addProduct(_foundProduct!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_foundProduct!.name} to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset for next scan
    _scanAgain();
  }
}
