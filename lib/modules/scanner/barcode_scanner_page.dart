import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen barcode scanner page.
///
/// Opens the device camera and scans barcodes / QR codes.
/// When a code is detected, it returns the scanned value via `Get.back()`.
/// The calling page can then look up the product by barcode/SKU.
class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: true,
    facing: CameraFacing.back,
    formats: [
      BarcodeFormat.all,
    ],
  );

  bool _hasScanned = false;
  bool _flashOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    _hasScanned = true;
    _controller.stop();

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Return the scanned value
    Get.back(result: barcode.rawValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text("Scan Barcode"),
        elevation: 0,
        actions: [
          // Flash toggle
          IconButton(
            onPressed: () {
              setState(() => _flashOn = !_flashOn);
              _controller.toggleTorch();
            },
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? AppColors.warning : Colors.white70,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay
          CustomPaint(
            painter: _ScanOverlayPainter(),
            size: Size.infinite,
          ),

          // Instructions
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.25,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.white70, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        "Point camera at a barcode or QR code",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Manual entry button
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
            child: Center(
              child: TextButton.icon(
                onPressed: () => _showManualEntry(),
                icon: const Icon(Icons.keyboard_outlined, color: Colors.white70, size: 18),
                label: const Text(
                  "Enter code manually",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Enter Code", style: Get.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Enter the barcode number or SKU from the product",
                style: Get.textTheme.bodySmall?.copyWith(
                  color: Get.theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "e.g. 8901234567890 or W0001",
                  prefixIcon: Icon(Icons.qr_code),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    Get.back(); // close dialog
                    _hasScanned = true;
                    _controller.stop();
                    Get.back(result: value.trim()); // close scanner with result
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () => Get.back(), // just close dialog
                      child: const Text("Cancel"),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          Get.back(); // close dialog
                          _hasScanned = true;
                          _controller.stop();
                          Get.back(result: controller.text.trim()); // close scanner with result
                        }
                      },
                      child: const Text("Find"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a semi-transparent overlay with a
/// rectangular cutout in the center for the scan area.
class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const scanAreaSize = 260.0;
    const cornerLength = 30.0;
    const cornerWidth = 4.0;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 40),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Dark overlay with cutout
    final overlayPaint = Paint()..color = Colors.black54;
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, Radius.zero))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(overlayPath, overlayPaint);

    // Corner accents
    final cornerPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top + cornerLength),
      Offset(scanRect.left, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.top),
      Offset(scanRect.left + cornerLength, scanRect.top),
      cornerPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.top),
      Offset(scanRect.right, scanRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.top),
      Offset(scanRect.right, scanRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom - cornerLength),
      Offset(scanRect.left, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.left, scanRect.bottom),
      Offset(scanRect.left + cornerLength, scanRect.bottom),
      cornerPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(scanRect.right - cornerLength, scanRect.bottom),
      Offset(scanRect.right, scanRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanRect.right, scanRect.bottom - cornerLength),
      Offset(scanRect.right, scanRect.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Utility to open the barcode scanner and process the result.
class BarcodeScannerHelper {
  /// Open the barcode scanner and return the raw scanned code.
  /// Does NOT process the code — just returns it.
  /// Useful for filling barcode fields in product add/edit dialogs.
  static Future<String?> scanAndLookupRaw() async {
    final result = await Get.to<String>(
      () => const BarcodeScannerPage(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 300),
    );
    return result;
  }

  /// Open the barcode scanner and handle the result.
  /// [onScanned] receives the scanned code string.
  static Future<void> scanAndLookup({
    required Function(String code) onScanned,
  }) async {
    final result = await Get.to<String>(
      () => const BarcodeScannerPage(),
      transition: Transition.downToUp,
      duration: const Duration(milliseconds: 300),
    );

    if (result != null && result.isNotEmpty) {
      onScanned(result);
    }
  }

  /// Look up a scanned/entered code and add it to cart.
  /// Searches by barcode first (real-world barcode from packaging),
  /// then falls back to internal SKU lookup.
  static void addSkuToCart(String code) {
    final productsController = Get.find<ProductsController>();
    final cartController = Get.find<CartController>();

    final product = productsController.findByBarcodeOrSku(code);
    if (product != null) {
      if (product.stock <= 0) {
        Get.snackbar(
          "Out of stock",
          "${product.name} is out of stock",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.danger,
          colorText: Colors.white,
        );
      } else {
        cartController.addToCart(product);
        Get.snackbar(
          "Added to cart",
          "${product.name}",
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(AppSpacing.md),
          duration: const Duration(milliseconds: 1200),
        );
      }
    } else {
      Get.snackbar(
        "Not found",
        "No product with barcode or SKU \"$code\"",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Look up a scanned/entered code and navigate to product edit.
  static void findProductByCode(String code) {
    final productsController = Get.find<ProductsController>();

    final product = productsController.findByBarcodeOrSku(code);
    if (product != null) {
      productsController.selectedCategory.value = 'All';
      productsController.searchQuery.value = product.name;
      Get.toNamed('/products');
      Get.snackbar(
        "Product found",
        "${product.name} — ${product.category}",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(milliseconds: 1500),
      );
    } else {
      Get.snackbar(
        "Not found",
        "No product with barcode or SKU \"$code\"",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
