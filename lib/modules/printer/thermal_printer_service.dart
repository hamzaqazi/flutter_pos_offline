import 'dart:io';
import 'dart:typed_data';
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
          .map((b) => BluetoothPrinter(name: b.name, mac: b.macAdress))
          .where((p) => p.mac.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<bool> connect(String mac) async {
    try {
      return await PrintBluetoothThermal.connect(macPrinterAddress: mac);
    } catch (e) {
      return false;
    }
  }

  static Future<void> disconnect() async {
    try {
      await PrintBluetoothThermal.disconnect;
    } catch (_) {}
  }

  static Future<bool> isConnected() async {
    try {
      return await PrintBluetoothThermal.connectionStatus;
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
        Get.snackbar("No printer", "Please pair a printer in Settings",
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

      final connected = await connect(receiptSettings.pairedPrinterMac);
      if (!connected) {
        Get.snackbar("Connection failed", "Could not connect to printer",
            snackPosition: SnackPosition.BOTTOM);
        return false;
      }

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

      try {
        final List<int> printData = bytes.toList();
        await PrintBluetoothThermal.writeBytes(printData);
      } catch (e) {
        Get.snackbar("Print error", "Failed to send: $e",
            snackPosition: SnackPosition.BOTTOM);
      }

      await Future.delayed(const Duration(seconds: 1));
      await disconnect();
    } catch (e) {
      Get.snackbar("Print error", "Failed to print: $e",
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  DOT-LINE HELPER
  // ─────────────────────────────────────────────────────────

  static String _dotLine(String left, String right, int width) {
    final gap = width - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${'.' * gap}$right';
  }

  static String _spaceLine(String left, String right, int width) {
    final gap = width - left.length - right.length;
    if (gap <= 1) return '$left $right';
    return '$left${' ' * gap}$right';
  }

  // ─────────────────────────────────────────────────────────
  //  COMMON: Logo + Header
  // ─────────────────────────────────────────────────────────

  static void _writeHeader(Generator g, List<int> bytes, ReceiptSettingsModel rs, shopSettings, bool is58mm) {
    // Logo
    if (rs.showLogo && rs.hasLogo) {
      try {
        final file = File(rs.logoPath);
        if (file.existsSync()) {
          final decoded = img.decodeImage(file.readAsBytesSync());
          if (decoded != null) {
            final maxW = is58mm ? 280 : 500;
            if (decoded.width > maxW) {
              final ratio = maxW / decoded.width;
              final resized = img.copyResize(decoded, width: maxW, height: (decoded.height * ratio).round());
              bytes += g.image(resized);
            } else {
              bytes += g.image(decoded);
            }
            bytes += g.feed(1);
          }
        }
      } catch (_) {}
    }

    // Shop name
    if (rs.showShopName) {
      bytes += g.text(shopSettings.shopName.toUpperCase(),
          styles: const PosStyles(align: PosAlign.center, bold: true));
    }
    if (rs.showAddress && shopSettings.address.isNotEmpty) {
      bytes += g.text(shopSettings.address,
          styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    }
    if (rs.showPhone && shopSettings.phone.isNotEmpty) {
      bytes += g.text(shopSettings.phone,
          styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    }
  }

  static void _writeFooter(Generator g, List<int> bytes, ReceiptSettingsModel rs, shopSettings) {
    if (rs.showFooter) {
      bytes += g.feed(1);
      bytes += g.text(shopSettings.receiptFooter,
          styles: const PosStyles(align: PosAlign.center, bold: true));
    }
    bytes += g.feed(1);
    bytes += g.hr(ch: '-');
    bytes += g.text('Powered by Codynest.com',
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    bytes += g.text('Support / WhatsApp:',
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    bytes += g.text('0315-3507075 / 0345-3333316',
        styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    bytes += g.feed(3);
    bytes += g.cut();
  }

  static String _receiptNo() {
    final now = DateTime.now();
    return 'R${now.millisecondsSinceEpoch.toString().substring(6)}';
  }

  static String _dateTimeStr() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────
  //  TEMPLATE 0: CLASSIC (dot-line alignment)
  // ─────────────────────────────────────────────────────────

  static Future<Uint8List> _templateClassic(Generator g, List<int> bytes, {
    required List<CartItemModel> items,
    required double subtotal, required double checkoutDiscount,
    required double taxRate, required bool taxInclusive, required double taxAmount,
    required double total, required double cash, required double change,
    required double totalSavings, required String customerName, required String cashierName,
    required ReceiptSettingsModel rs, required shopSettings, required int cw,
  }) async {
    final cur = shopSettings.currencySymbol;
    final small = PosStyles(height: PosTextSize.size1, width: PosTextSize.size1);

    _writeHeader(g, bytes, rs, shopSettings, cw == 32);
    bytes += g.hr(ch: '=');

    if (rs.showDate) bytes += g.text(_dotLine('No: ${_receiptNo()}', _dateTimeStr(), cw), styles: small);
    if (rs.showCustomer && customerName.isNotEmpty) bytes += g.text('Customer: $customerName', styles: small);
    if (rs.showCashier && cashierName.isNotEmpty) bytes += g.text('Cashier: $cashierName', styles: small);
    bytes += g.hr(ch: '-');

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      bytes += g.text(item.product.name, styles: const PosStyles(bold: true));

      final details = <String>[];
      if (rs.showBrand && item.product.hasBrand) details.add(item.product.brand);
      if (rs.showSku && item.product.hasSku) details.add('SKU:${item.product.sku}');
      if (rs.showBarcode && item.product.hasBarcode) details.add('BC:${item.product.barcode}');
      if (details.isNotEmpty) bytes += g.text('  ${details.join(' | ')}', styles: small);

      bytes += g.text(_dotLine('  ${item.quantity} x $cur${item.product.discountedPrice.toStringAsFixed(0)}', '$cur${item.total.toStringAsFixed(0)}', cw));

      if (rs.showDiscountDetails && item.product.discount > 0)
        bytes += g.text('  Save ${item.product.discount.toStringAsFixed(0)}% (was $cur${item.product.price.toStringAsFixed(0)})', styles: small);

      if (i < items.length - 1) bytes += g.hr(ch: '.', len: cw ~/ 2);
    }

    bytes += g.hr(ch: '=');
    bytes += g.text(_dotLine('Subtotal', '$cur${subtotal.toStringAsFixed(0)}', cw));

    final chkDiscAmt = subtotal * checkoutDiscount / 100;
    final prodDiscAmt = totalSavings - chkDiscAmt;
    if (rs.showDiscountDetails) {
      if (prodDiscAmt > 0) bytes += g.text(_dotLine('Product disc', '-$cur${prodDiscAmt.toStringAsFixed(0)}', cw));
      if (checkoutDiscount > 0) bytes += g.text(_dotLine('Checkout ${checkoutDiscount.toStringAsFixed(0)}% disc', '-$cur${chkDiscAmt.toStringAsFixed(0)}', cw));
    }
    if (rs.showTaxDetails && taxAmount > 0) {
      final tl = taxInclusive ? 'Tax incl. ${taxRate.toStringAsFixed(1)}%' : 'Tax ${taxRate.toStringAsFixed(1)}%';
      bytes += g.text(_dotLine(tl, '$cur${taxAmount.toStringAsFixed(0)}', cw));
    }

    bytes += g.hr(ch: '-');
    bytes += g.text(_dotLine('TOTAL', '$cur${total.toStringAsFixed(0)}', cw),
        styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1));
    bytes += g.feed(1);
    bytes += g.text(_dotLine('Cash', '$cur${cash.toStringAsFixed(0)}', cw));
    bytes += g.text(_dotLine('Change', '$cur${change.toStringAsFixed(0)}', cw));

    _writeFooter(g, bytes, rs, shopSettings);
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────
  //  TEMPLATE 1: MODERN (clean, space-aligned)
  // ─────────────────────────────────────────────────────────

  static Future<Uint8List> _templateModern(Generator g, List<int> bytes, {
    required List<CartItemModel> items,
    required double subtotal, required double checkoutDiscount,
    required double taxRate, required bool taxInclusive, required double taxAmount,
    required double total, required double cash, required double change,
    required double totalSavings, required String customerName, required String cashierName,
    required ReceiptSettingsModel rs, required shopSettings, required int cw,
  }) async {
    final cur = shopSettings.currencySymbol;
    final small = PosStyles(height: PosTextSize.size1, width: PosTextSize.size1);

    _writeHeader(g, bytes, rs, shopSettings, cw == 32);
    bytes += g.feed(1);

    // Info block with borders
    if (rs.showDate) {
      bytes += g.text(_spaceLine('No: ${_receiptNo()}', _dateTimeStr(), cw), styles: small);
    }
    if (rs.showCustomer && customerName.isNotEmpty) bytes += g.text('  Customer: $customerName', styles: small);
    if (rs.showCashier && cashierName.isNotEmpty) bytes += g.text('  Cashier: $cashierName', styles: small);

    bytes += g.hr(ch: '_');

    // Items: name on line 1, qty x price (right-aligned total) on line 2
    for (final item in items) {
      bytes += g.text(item.product.name);

      // Details line
      final details = <String>[];
      if (rs.showBrand && item.product.hasBrand) details.add(item.product.brand);
      if (rs.showSku && item.product.hasSku) details.add(item.product.sku);
      if (rs.showBarcode && item.product.hasBarcode) details.add(item.product.barcode);
      if (details.isNotEmpty) bytes += g.text('  ${details.join(' | ')}', styles: small);

      // Price line: right-aligned total
      bytes += g.text(
        _spaceLine('${item.quantity} x $cur${item.product.discountedPrice.toStringAsFixed(0)}', '$cur${item.total.toStringAsFixed(0)}', cw),
      );

      if (rs.showDiscountDetails && item.product.discount > 0) {
        bytes += g.text(
          '  Save ${item.product.discount.toStringAsFixed(0)}% (was $cur${item.product.price.toStringAsFixed(0)})',
          styles: small,
        );
      }
    }

    bytes += g.hr(ch: '_');

    // Totals: space-aligned, clean
    bytes += g.text(_spaceLine('Subtotal', '$cur${subtotal.toStringAsFixed(0)}', cw));

    final chkDiscAmt = subtotal * checkoutDiscount / 100;
    final prodDiscAmt = totalSavings - chkDiscAmt;
    if (rs.showDiscountDetails) {
      if (prodDiscAmt > 0) bytes += g.text(_spaceLine('Discounts', '-$cur${prodDiscAmt.toStringAsFixed(0)}', cw));
      if (checkoutDiscount > 0) bytes += g.text(_spaceLine('Extra ${checkoutDiscount.toStringAsFixed(0)}% off', '-$cur${chkDiscAmt.toStringAsFixed(0)}', cw));
    }
    if (rs.showTaxDetails && taxAmount > 0) {
      final tl = taxInclusive ? 'Tax incl.' : 'Tax';
      bytes += g.text(_spaceLine('$tl ${taxRate.toStringAsFixed(1)}%', '$cur${taxAmount.toStringAsFixed(0)}', cw));
    }

    bytes += g.feed(1);
    bytes += g.text(
      _spaceLine('TOTAL', '$cur${total.toStringAsFixed(0)}', cw),
      styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    bytes += g.feed(1);
    bytes += g.text(_spaceLine('Cash', '$cur${cash.toStringAsFixed(0)}', cw));
    bytes += g.text(_spaceLine('Change', '$cur${change.toStringAsFixed(0)}', cw));

    _writeFooter(g, bytes, rs, shopSettings);
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────
  //  TEMPLATE 2: COMPACT (minimal, saves paper)
  // ─────────────────────────────────────────────────────────

  static Future<Uint8List> _templateCompact(Generator g, List<int> bytes, {
    required List<CartItemModel> items,
    required double subtotal, required double checkoutDiscount,
    required double taxRate, required bool taxInclusive, required double taxAmount,
    required double total, required double cash, required double change,
    required double totalSavings, required String customerName, required String cashierName,
    required ReceiptSettingsModel rs, required shopSettings, required int cw,
  }) async {
    final cur = shopSettings.currencySymbol;
    final small = PosStyles(height: PosTextSize.size1, width: PosTextSize.size1);

    // Header: single line shop name, no extra spacing
    if (rs.showShopName) {
      bytes += g.text(shopSettings.shopName.toUpperCase(),
          styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size1, width: PosTextSize.size1));
    }

    // Address + phone on one line if possible
    final addrParts = <String>[];
    if (rs.showAddress && shopSettings.address.isNotEmpty) addrParts.add(shopSettings.address);
    if (rs.showPhone && shopSettings.phone.isNotEmpty) addrParts.add(shopSettings.phone);
    if (addrParts.isNotEmpty) bytes += g.text(addrParts.join(' | '), styles: small);

    bytes += g.hr(ch: '-');

    // Date + receipt no on one line
    if (rs.showDate) bytes += g.text('No:${_receiptNo()} ${_dateTimeStr()}', styles: small);
    if (rs.showCustomer && customerName.isNotEmpty) bytes += g.text('Cust: $customerName', styles: small);
    if (rs.showCashier && cashierName.isNotEmpty) bytes += g.text('Cash: $cashierName', styles: small);

    // Items: one line each — name x qty = total
    for (final item in items) {
      final disc = item.product.discount > 0
          ? ' (${item.product.discount.toStringAsFixed(0)}%off)'
          : '';
      bytes += g.text(
        '${item.product.name} x${item.quantity} $cur${item.total.toStringAsFixed(0)}$disc',
        styles: small,
      );
    }

    bytes += g.hr(ch: '-');

    // Totals compact
    bytes += g.text(_dotLine('Subtotal', '$cur${subtotal.toStringAsFixed(0)}', cw), styles: small);

    final chkDiscAmt = subtotal * checkoutDiscount / 100;
    final prodDiscAmt = totalSavings - chkDiscAmt;
    if (rs.showDiscountDetails && prodDiscAmt > 0)
      bytes += g.text(_dotLine('Disc', '-$cur${prodDiscAmt.toStringAsFixed(0)}', cw), styles: small);
    if (rs.showDiscountDetails && checkoutDiscount > 0)
      bytes += g.text(_dotLine('Extra', '-$cur${chkDiscAmt.toStringAsFixed(0)}', cw), styles: small);
    if (rs.showTaxDetails && taxAmount > 0)
      bytes += g.text(_dotLine('Tax', '$cur${taxAmount.toStringAsFixed(0)}', cw), styles: small);

    bytes += g.text(
      _dotLine('TOTAL', '$cur${total.toStringAsFixed(0)}', cw),
      styles: const PosStyles(bold: true),
    );
    bytes += g.text(_dotLine('Cash', '$cur${cash.toStringAsFixed(0)}', cw), styles: small);
    bytes += g.text(_dotLine('Change', '$cur${change.toStringAsFixed(0)}', cw), styles: small);

    if (rs.showFooter) {
      bytes += g.text(shopSettings.receiptFooter,
          styles: PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size1, width: PosTextSize.size1));
    }

    bytes += g.feed(1);
    bytes += g.text('Powered by Codynest.com', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    bytes += g.text('0315-3507075 / 0345-3333316', styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1, width: PosTextSize.size1));
    bytes += g.feed(2);
    bytes += g.cut();
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────
  //  TEMPLATE 3: DETAILED (box-style with full info)
  // ─────────────────────────────────────────────────────────

  static Future<Uint8List> _templateDetailed(Generator g, List<int> bytes, {
    required List<CartItemModel> items,
    required double subtotal, required double checkoutDiscount,
    required double taxRate, required bool taxInclusive, required double taxAmount,
    required double total, required double cash, required double change,
    required double totalSavings, required String customerName, required String cashierName,
    required ReceiptSettingsModel rs, required shopSettings, required int cw,
  }) async {
    final cur = shopSettings.currencySymbol;
    final small = PosStyles(height: PosTextSize.size1, width: PosTextSize.size1);

    _writeHeader(g, bytes, rs, shopSettings, cw == 32);

    // TAX INVOICE header
    bytes += g.hr(ch: '=');
    bytes += g.text('RECEIPT', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += g.hr(ch: '=');

    // Receipt info block
    if (rs.showDate) {
      bytes += g.text('Receipt: ${_receiptNo()}', styles: small);
      bytes += g.text('Date: ${_dateTimeStr()}', styles: small);
    }
    if (rs.showCustomer && customerName.isNotEmpty)
      bytes += g.text('Customer: $customerName', styles: small);
    if (rs.showCashier && cashierName.isNotEmpty)
      bytes += g.text('Cashier: $cashierName', styles: small);

    bytes += g.hr(ch: '-');

    // Column header
    bytes += g.text(_spaceLine('Item', 'Qty  Price  Total', cw), styles: small);
    bytes += g.hr(ch: '-', len: cw);

    // Items with full details
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final num = '${i + 1}.';

      bytes += g.text('$num ${item.product.name}', styles: const PosStyles(bold: true));

      // All details on separate small lines
      if (rs.showBrand && item.product.hasBrand)
        bytes += g.text('   Brand: ${item.product.brand}', styles: small);
      if (rs.showSku && item.product.hasSku)
        bytes += g.text('   SKU: ${item.product.sku}', styles: small);
      if (rs.showBarcode && item.product.hasBarcode)
        bytes += g.text('   Barcode: ${item.product.barcode}', styles: small);

      // Qty x Price = Total
      bytes += g.text(
        '   ${item.quantity} x $cur${item.product.discountedPrice.toStringAsFixed(0)} = $cur${item.total.toStringAsFixed(0)}',
      );

      if (rs.showDiscountDetails && item.product.discount > 0) {
        bytes += g.text(
          '   Discount: ${item.product.discount.toStringAsFixed(0)}% (Orig: $cur${item.product.price.toStringAsFixed(0)})',
          styles: small,
        );
      }
      bytes += g.hr(ch: '.', len: cw ~/ 2);
    }

    // Totals with full breakdown
    bytes += g.hr(ch: '=');

    bytes += g.text(_dotLine('Subtotal', '$cur${subtotal.toStringAsFixed(0)}', cw));

    final chkDiscAmt = subtotal * checkoutDiscount / 100;
    final prodDiscAmt = totalSavings - chkDiscAmt;

    if (rs.showDiscountDetails) {
      if (prodDiscAmt > 0) {
        bytes += g.text(_dotLine('  Product discounts', '-$cur${prodDiscAmt.toStringAsFixed(0)}', cw), styles: small);
      }
      if (checkoutDiscount > 0) {
        bytes += g.text(_dotLine('  Checkout ${checkoutDiscount.toStringAsFixed(0)}% off', '-$cur${chkDiscAmt.toStringAsFixed(0)}', cw), styles: small);
      }
      if (prodDiscAmt > 0 || checkoutDiscount > 0) {
        bytes += g.text(_dotLine('  Total savings', '-$cur${totalSavings.toStringAsFixed(0)}', cw));
      }
    }

    if (rs.showTaxDetails && taxAmount > 0) {
      final tl = taxInclusive ? 'Tax incl. ${taxRate.toStringAsFixed(1)}%' : 'Tax ${taxRate.toStringAsFixed(1)}%';
      bytes += g.text(_dotLine(tl, '$cur${taxAmount.toStringAsFixed(0)}', cw));
    }

    bytes += g.hr(ch: '-');
    bytes += g.text(
      _dotLine('TOTAL DUE', '$cur${total.toStringAsFixed(0)}', cw),
      styles: const PosStyles(bold: true, height: PosTextSize.size2, width: PosTextSize.size1),
    );
    bytes += g.feed(1);
    bytes += g.text(_dotLine('Cash received', '$cur${cash.toStringAsFixed(0)}', cw));
    bytes += g.text(_dotLine('Change', '$cur${change.toStringAsFixed(0)}', cw));

    _writeFooter(g, bytes, rs, shopSettings);
    return Uint8List.fromList(bytes);
  }

  // ─────────────────────────────────────────────────────────
  //  MAIN GENERATOR — dispatches to template
  // ─────────────────────────────────────────────────────────

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
    final cw = is58mm ? 32 : 48;

    final commonParams = {
      'items': items,
      'subtotal': subtotal,
      'checkoutDiscount': checkoutDiscount,
      'taxRate': taxRate,
      'taxInclusive': taxInclusive,
      'taxAmount': taxAmount,
      'total': total,
      'cash': cash,
      'change': change,
      'totalSavings': totalSavings,
      'customerName': customerName,
      'cashierName': cashierName,
      'rs': receiptSettings,
      'shopSettings': shopSettings,
      'cw': cw,
    };

    switch (receiptSettings.template) {
      case 1:
        return _templateModern(generator, [], items: items, subtotal: subtotal, checkoutDiscount: checkoutDiscount, taxRate: taxRate, taxInclusive: taxInclusive, taxAmount: taxAmount, total: total, cash: cash, change: change, totalSavings: totalSavings, customerName: customerName, cashierName: cashierName, rs: receiptSettings, shopSettings: shopSettings, cw: cw);
      case 2:
        return _templateCompact(generator, [], items: items, subtotal: subtotal, checkoutDiscount: checkoutDiscount, taxRate: taxRate, taxInclusive: taxInclusive, taxAmount: taxAmount, total: total, cash: cash, change: change, totalSavings: totalSavings, customerName: customerName, cashierName: cashierName, rs: receiptSettings, shopSettings: shopSettings, cw: cw);
      case 3:
        return _templateDetailed(generator, [], items: items, subtotal: subtotal, checkoutDiscount: checkoutDiscount, taxRate: taxRate, taxInclusive: taxInclusive, taxAmount: taxAmount, total: total, cash: cash, change: change, totalSavings: totalSavings, customerName: customerName, cashierName: cashierName, rs: receiptSettings, shopSettings: shopSettings, cw: cw);
      case 0:
      default:
        return _templateClassic(generator, [], items: items, subtotal: subtotal, checkoutDiscount: checkoutDiscount, taxRate: taxRate, taxInclusive: taxInclusive, taxAmount: taxAmount, total: total, cash: cash, change: change, totalSavings: totalSavings, customerName: customerName, cashierName: cashierName, rs: receiptSettings, shopSettings: shopSettings, cw: cw);
    }
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
