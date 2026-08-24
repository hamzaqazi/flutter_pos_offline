import 'dart:convert';
import 'package:ad_shop_pos/app/utils/backup_io_bridge.dart';
import 'package:ad_shop_pos/app/utils/web_download_bridge.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/customer_model.dart';
import 'package:ad_shop_pos/data/models/expense_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/data/models/sale_model.dart';
import 'package:ad_shop_pos/data/models/staff_model.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Service for exporting data as CSV/JSON files.
///
/// - **Native**: Writes to temp file and shares via share_plus.
/// - **Web**: Triggers browser download using Blob + anchor download API
///   (proper file download with correct filename, restorable on import).
class ExportService {
  /// Export all products as CSV.
  static Future<void> exportProducts() async {
    final controller = Get.find<ProductsController>();
    final products = controller.products;

    final buffer = StringBuffer();
    buffer.writeln(
      'SKU,Barcode,Name,Brand,Category,Price,Purchase Price,Discount %,Stock',
    );

    for (final p in products) {
      buffer.writeln(
        '"${p.sku}","${p.barcode}","${p.name}","${p.brand}","${p.category}",'
        '${p.price},${p.purchasePrice},${p.discount},${p.stock}',
      );
    }

    await _exportFile(buffer.toString(), 'products', 'csv');
  }

  /// Export all sales as CSV.
  static Future<void> exportSales() async {
    final controller = Get.find<SalesController>();
    final sales = controller.sales;

    final buffer = StringBuffer();
    buffer.writeln(
      'Invoice No,Sale ID,Date,Subtotal,Checkout Discount %,Tax Amount,Total,'
      'Cash,Change,Discount Amount,Profit,Customer ID,Items',
    );

    for (final s in sales) {
      final itemsSummary = s.items
          .map((i) => '${i.product.name}x${i.quantity}')
          .join('; ');
      buffer.writeln(
        '"${s.invoiceNumber}","${s.id}","${Formatters.dateTime(s.date)}",${s.subtotal},'
        '${s.checkoutDiscount},${s.taxAmount},${s.total},'
        '${s.cash},${s.change},${s.discount},${s.profit},'
        '"${s.customerId}","$itemsSummary"',
      );
    }

    await _exportFile(buffer.toString(), 'sales', 'csv');
  }

  /// Export all expenses as CSV.
  static Future<void> exportExpenses() async {
    final controller = Get.find<ExpensesController>();
    final expenses = controller.expenses;

    final buffer = StringBuffer();
    buffer.writeln('Expense ID,Date,Category,Amount,Description');

    for (final e in expenses) {
      buffer.writeln(
        '"${e.id}","${Formatters.dateTime(e.date)}","${e.category}",'
        '${e.amount},"${e.description}"',
      );
    }

    await _exportFile(buffer.toString(), 'expenses', 'csv');
  }

  /// Export a full backup as JSON (lossless, restorable format).
  /// On web, this downloads a .json file that can be re-imported via
  /// "Restore from Backup" (FilePicker reads the file bytes).
  static Future<void> exportFullBackup() async {
    try {
      final productsController = Get.find<ProductsController>();
      final salesController = Get.find<SalesController>();
      final expensesController = Get.find<ExpensesController>();
      final returnsController = Get.find<ReturnsController>();
      final customersController = Get.find<CustomersController>();
      final staffController = Get.find<StaffController>();
      final settingsController = Get.find<SettingsController>();

      final backup = <String, dynamic>{
        'version': 1,
        'exportedAt': DateTime.now().toIso8601String(),
        'app': 'ad_shop_pos',
      };

      // Products
      backup['products'] = productsController.products
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'brand': p.brand,
              'category': p.category,
              'price': p.price,
              'purchasePrice': p.purchasePrice,
              'discount': p.discount,
              'stock': p.stock,
              'sku': p.sku,
              'barcode': p.barcode,
            },
          )
          .toList();

      // Sales
      backup['sales'] = salesController.sales.map((s) => s.toMap()).toList();

      // Expenses
      backup['expenses'] = expensesController.expenses
          .map((e) => e.toMap())
          .toList();

      // Returns
      backup['returns'] = returnsController.returns
          .map((r) => r.toMap())
          .toList();

      // Customers
      backup['customers'] = customersController.customers
          .map((c) => c.toMap())
          .toList();

      // Staff
      backup['staff'] = staffController.staff.map((s) => s.toMap()).toList();

      // Settings
      backup['settings'] = settingsController.settings.value.toMap();

      // Receipt settings
      backup['receiptSettings'] =
          settingsController.receiptSettings.value.toMap();

      // Categories
      final catController = Get.find<CategoryController>();
      backup['categories'] = catController.categories
          .map((c) => c.toMap())
          .toList();

      // Last invoice number
      final settingsBox = Hive.box('settings');
      final lastInvoiceNum = settingsBox.get(
        'lastInvoiceNumber',
        defaultValue: 0,
      );
      backup['lastInvoiceNumber'] = lastInvoiceNum;

      // Trial data
      final trialStart = settingsBox.get('trial_startDate');
      if (trialStart != null) {
        backup['trial_startDate'] = trialStart;
        backup['trial_expired'] =
            settingsBox.get('trial_expired', defaultValue: false);
        final trialPhone = settingsBox.get('trial_customerPhone');
        if (trialPhone != null) {
          backup['trial_customerPhone'] = trialPhone;
        }
      }

      // Active cashier
      if (staffController.activeCashierId.value != null) {
        backup['activeCashierId'] = staffController.activeCashierId.value;
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = 'full_backup_$timestamp.json';

      await _exportFile(jsonStr, filename.replaceAll('.json', ''), 'json',
          subject: 'Full Backup - $timestamp',
          text:
              'Shop POS Full Backup (${productsController.products.length} products, '
              '${salesController.sales.length} sales, '
              '${expensesController.expenses.length} expenses)');
    } catch (e) {
      Get.snackbar(
        "Export failed",
        "Could not export backup: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Export file content: native uses share_plus, web uses browser download.
  static Future<void> _exportFile(
    String content,
    String prefix,
    String ext, {
    String? subject,
    String? text,
  }) async {
    try {
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final filename = '${prefix}_$timestamp.$ext';

      if (kIsWeb) {
        // ── Web: trigger proper browser file download ──
        // Uses Blob + anchor download API for reliable download
        // with correct filename. The downloaded file can be
        // re-imported via "Restore from Backup".
        final mimeType = ext == 'csv' ? 'text/csv' : 'application/json';
        final success = await downloadFileOnWeb(content, filename, mimeType);

        if (!success) {
          debugPrint('⚠️ Web download failed');
          Get.snackbar(
            "Download failed",
            "Could not trigger browser download. Try saving via Google Drive instead.",
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      } else {
        // ── Native: write temp file and share ──
        final filePath = await writeTempFile(filename, content);
        await shareNativeFile(
          filePath,
          subject: subject ?? '$prefix export - $timestamp',
          text: text ?? 'Shop POS $prefix export',
        );
      }
    } catch (e) {
      Get.snackbar(
        "Export failed",
        "Could not export data: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
