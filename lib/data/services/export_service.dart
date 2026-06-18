import 'dart:convert';
import 'dart:io';
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
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Service for exporting data as CSV files and sharing them.
class ExportService {
  /// Export all products as CSV.
  static Future<void> exportProducts() async {
    final controller = Get.find<ProductsController>();
    final products = controller.products;

    final buffer = StringBuffer();
    buffer.writeln('SKU,Barcode,Name,Brand,Category,Price,Purchase Price,Discount %,Stock');

    for (final p in products) {
      buffer.writeln(
        '"${p.sku}","${p.barcode}","${p.name}","${p.brand}","${p.category}",'
        '${p.price},${p.purchasePrice},${p.discount},${p.stock}',
      );
    }

    await _shareCsv(buffer.toString(), 'products');
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

    await _shareCsv(buffer.toString(), 'sales');
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

    await _shareCsv(buffer.toString(), 'expenses');
  }

  /// Export a full backup as JSON (lossless, restorable format).
  /// This replaces the old CSV-based full backup with a proper JSON structure
  /// that preserves all nested data for lossless import.
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

      // Products — store as list of maps
      backup['products'] = productsController.products
          .map((p) => {
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
              })
          .toList();

      // Sales — store as list of maps (with full item details)
      backup['sales'] = salesController.sales
          .map((s) => s.toMap())
          .toList();

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
      backup['staff'] = staffController.staff
          .map((s) => s.toMap())
          .toList();

      // Settings
      backup['settings'] = settingsController.settings.value.toMap();

      // Receipt settings
      backup['receiptSettings'] = settingsController.receiptSettings.value.toMap();

      // Categories
      final catController = Get.find<CategoryController>();
      backup['categories'] = catController.categories.map((c) => c.toMap()).toList();

      // Last invoice number (for sequential numbering persistence)
      final settingsBox = Hive.box('settings');
      final lastInvoiceNum = settingsBox.get('lastInvoiceNumber', defaultValue: 0);
      backup['lastInvoiceNumber'] = lastInvoiceNum;

      // Active cashier
      if (staffController.activeCashierId.value != null) {
        backup['activeCashierId'] = staffController.activeCashierId.value;
      }

      final jsonStr = const JsonEncoder.withIndent('  ').convert(backup);

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File('${directory.path}/full_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Full Backup - $timestamp',
        text: 'Shop POS Full Backup (${productsController.products.length} products, '
            '${salesController.sales.length} sales, '
            '${expensesController.expenses.length} expenses)',
      );
    } catch (e) {
      Get.snackbar(
        "Export failed",
        "Could not export backup: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Write CSV to a temp file and share.
  static Future<void> _shareCsv(String csvContent, String prefix) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File('${directory.path}/${prefix}_$timestamp.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '$prefix export - $timestamp',
        text: 'Shop POS $prefix export',
      );
    } catch (e) {
      Get.snackbar(
        "Export failed",
        "Could not export data: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
