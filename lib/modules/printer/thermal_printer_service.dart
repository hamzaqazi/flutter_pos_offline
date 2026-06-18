import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/receipt_settings_model.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:image/image.dart' as img;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:get/get.dart';

/// Service for printing receipts to Bluetooth thermal printers.
class ThermalPrinterService {
  /// Discover available Bluetooth printers.
  static Future<List<BluetoothPrinter>> getAvailablePrinters() async {
    try {
      final listResult = await PrintBluetoothThermal.pairedBluetooths;
      if (listResult.isEmpty) return [];
      return listResult
          .map(
            (bluetooth) => BluetoothPrinter(
              name: bluetooth.name,
              mac: bluetooth.macAdress,
            ),
          )
          .where((p) => p.mac.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Connect to a Bluetooth printer by MAC address.
  static Future<bool> connect(String mac) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: mac,
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Disconnect from the current printer.
  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  /// Check if currently connected to a printer.
  static Future<bool> isConnected() async {
    try {
      final result = await PrintBluetoothThermal.connectionStatus;
      return result;
    } catch (_) {
      return false;
    }
  }

  /// Print a receipt to the connected thermal printer.
  static Future<Object?> printReceipt({
    required List<CartItemModel> items,
    double subtotal = 0,
    double checkoutDiscount = 0,
    double taxRate = 0,
    bool taxInclusive = false,
    double taxAmount = 0,
    required double total,
    required double cash,
    required double change,
    double totalSavings = 0,
    String customerName = '',
    String cashierName = '',
  }) async {
    try {
      final receiptSettings = SettingsService.getReceiptSettings();
      final shopSettings = SettingsService.getSettings();

      if (!receiptSettings.hasPrinter) {
        Get.snackbar(
          "No printer",
          "Please pair a printer in Settings",
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Connect
      final connected = await connect(receiptSettings.pairedPrinterMac);
      if (!connected) {
        Get.snackbar(
          "Connection failed",
          "Could not connect to printer",
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      // Generate ESC/POS commands
      final bytes = await _generateEscPos(
        items: items,
        subtotal: subtotal,
        checkoutDiscount: checkoutDiscount,
        taxRate: taxRate,
        taxInclusive: taxInclusive,
        taxAmount: taxAmount,
        total: total,
        cash: cash,
        change: change,
        totalSavings: totalSavings,
        customerName: customerName,
        cashierName: cashierName,
        receiptSettings: receiptSettings,
        shopSettings: shopSettings,
      );

      // Send to printer
      try {
        final List<int> printData = bytes.toList();
        final result = await PrintBluetoothThermal.writeBytes(printData);
        if (!result) {
          Get.snackbar(
            "Print error",
            "Failed to send data to printer",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } catch (e) {
        Get.snackbar(
          "Print error",
          "Failed to send data to printer: $e",
          snackPosition: SnackPosition.BOTTOM,
        );
      }

      // Disconnect after printing
      await Future.delayed(const Duration(seconds: 1));
      await disconnect();
    } catch (e) {
      Get.snackbar(
        "Print error",
        "Failed to print: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
  }

  /// Generate ESC/POS byte commands for the receipt.
  /// Optimized for 58mm (32 chars/line) and 80mm (48 chars/line).
  static Future<Uint8List> _generateEscPos({
    required List<CartItemModel> items,
    required double subtotal,
    required double checkoutDiscount,
    required double taxRate,
    required bool taxInclusive,
    required double taxAmount,
    required double total,
    required double cash,
    required double change,
    required double totalSavings,
    required String customerName,
    required String cashierName,
    required ReceiptSettingsModel receiptSettings,
    required shopSettings,
  }) async {
    final profile = await CapabilityProfile.load();
    final is58mm = receiptSettings.paperWidth == 58;
    final paperSize = is58mm ? PaperSize.mm58 : PaperSize.mm80;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    final cur = shopSettings.currencySymbol;

    // --- Logo ---
    if (receiptSettings.showLogo && receiptSettings.hasLogo) {
      try {
        final file = File(receiptSettings.logoPath);
        if (await file.exists()) {
          final imageBytes = await file.readAsBytes();
          final decoded = img.decodeImage(imageBytes);
          if (decoded != null) {
            // Resize logo to fit paper width (58mm ≈ 384px, 80mm ≈ 576px)
            final maxWidth = is58mm ? 280 : 500;
            if (decoded.width > maxWidth) {
              final ratio = maxWidth / decoded.width;
              final resized = img.copyResize(
                decoded,
                width: maxWidth,
                height: (decoded.height * ratio).round(),
              );
              bytes += generator.image(resized);
            } else {
              bytes += generator.image(decoded);
            }
            bytes += generator.feed(1);
          }
        }
      } catch (_) {}
    }

    // --- Shop header (bold but NOT double-size — fits on 58mm) ---
    if (receiptSettings.showShopName) {
      bytes += generator.text(
        shopSettings.shopName.toUpperCase(),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    // --- Address (small font) ---
    if (receiptSettings.showAddress && shopSettings.address.isNotEmpty) {
      bytes += generator.text(
        shopSettings.address,
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          fontType: PosFontType.fontB,
        ),
      );
    }

    // --- Phone (small font) ---
    if (receiptSettings.showPhone && shopSettings.phone.isNotEmpty) {
      bytes += generator.text(
        shopSettings.phone,
        styles: PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
        ),
      );
    }

    bytes += generator.hr();

    // --- Date ---
    if (receiptSettings.showDate) {
      final now = DateTime.now();
      bytes += generator.text(
        '${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    if (receiptSettings.showCustomer && customerName.isNotEmpty) {
      bytes += generator.text('Customer: $customerName');
    }

    if (receiptSettings.showCashier && cashierName.isNotEmpty) {
      bytes += generator.text('Cashier: $cashierName');
    }

    bytes += generator.hr();

    // --- Items ---
    for (final item in items) {
      // Name
      bytes += generator.text(
        item.product.name,
        styles: const PosStyles(bold: true),
      );

      // Small font for brand, SKU, barcode
      final smallStyle = PosStyles(
        height: PosTextSize.size1,
        width: PosTextSize.size1,
      );

      // Brand
      if (receiptSettings.showBrand && item.product.hasBrand) {
        bytes += generator.text(
          '  Brand: ${item.product.brand}',
          styles: smallStyle,
        );
      }

      // SKU
      if (receiptSettings.showSku && item.product.hasSku) {
        bytes += generator.text(
          '  SKU: ${item.product.sku}',
          styles: smallStyle,
        );
      }

      // Barcode
      if (receiptSettings.showBarcode && item.product.hasBarcode) {
        bytes += generator.text(
          '  Barcode: ${item.product.barcode}',
          styles: smallStyle,
        );
      }

      // Qty x Price = Total
      bytes += generator.text(
        '  ${item.quantity} x $cur ${item.product.discountedPrice.toStringAsFixed(0)} = $cur ${item.total.toStringAsFixed(0)}',
      );

      // Discount detail
      if (receiptSettings.showDiscountDetails && item.product.discount > 0) {
        bytes += generator.text(
          '  Orig: $cur ${item.product.price.toStringAsFixed(0)} (-${item.product.discount.toStringAsFixed(0)}%)',
          styles: smallStyle,
        );
      }
    }

    bytes += generator.hr();

    // --- Totals ---
    bytes += generator.text('Subtotal: $cur ${subtotal.toStringAsFixed(0)}');

    final checkoutDiscountAmount = subtotal * checkoutDiscount / 100;
    final productDiscountAmount = totalSavings - checkoutDiscountAmount;

    if (receiptSettings.showDiscountDetails) {
      if (productDiscountAmount > 0) {
        bytes += generator.text(
          'Product disc: -$cur ${productDiscountAmount.toStringAsFixed(0)}',
        );
      }
      if (checkoutDiscount > 0) {
        bytes += generator.text(
          'Checkout disc (${checkoutDiscount.toStringAsFixed(0)}%): -$cur ${checkoutDiscountAmount.toStringAsFixed(0)}',
        );
      }
    }

    if (receiptSettings.showTaxDetails && taxAmount > 0) {
      final taxLabel = taxInclusive
          ? 'Tax incl. (${taxRate.toStringAsFixed(1)}%)'
          : 'Tax (${taxRate.toStringAsFixed(1)}%)';
      bytes += generator.text(
        '$taxLabel: $cur ${taxAmount.toStringAsFixed(0)}',
      );
    }

    bytes += generator.hr();

    // TOTAL in bold only (not double-size, fits 58mm)
    bytes += generator.text(
      'TOTAL: $cur ${total.toStringAsFixed(0)}',
      styles: const PosStyles(
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.hr();

    bytes += generator.text('Cash: $cur ${cash.toStringAsFixed(0)}');
    bytes += generator.text('Change: $cur ${change.toStringAsFixed(0)}');

    // --- Footer ---
    if (receiptSettings.showFooter) {
      bytes += generator.feed(1);
      bytes += generator.text(
        shopSettings.receiptFooter,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }

    // --- Powered by Codynest ---
    bytes += generator.feed(1);
    bytes += generator.text(
      'Powered by Codynest.com',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );
    bytes += generator.text(
      'Support & WhatsApp:',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );
    bytes += generator.text(
      '0315-3507075 / 0345-3333316',
      styles: const PosStyles(
        align: PosAlign.center,
        fontType: PosFontType.fontB,
      ),
    );

    bytes += generator.feed(1);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }
}

/// Simple model for a discovered Bluetooth printer.
class BluetoothPrinter {
  final String name;
  final String mac;

  BluetoothPrinter({required this.name, required this.mac});

  @override
  String toString() => '$name ($mac)';
}
