import 'dart:io';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/customer_model.dart';
import 'package:ad_shop_pos/data/models/expense_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/models/sale_model.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
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
    buffer.writeln('SKU,Name,Brand,Category,Price,Purchase Price,Discount %,Stock');

    for (final p in products) {
      buffer.writeln(
        '"${p.sku}","${p.name}","${p.brand}","${p.category}",'
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
      'Sale ID,Date,Subtotal,Checkout Discount %,Tax Amount,Total,'
      'Cash,Change,Discount Amount,Profit,Customer ID,Items',
    );

    for (final s in sales) {
      final itemsSummary = s.items
          .map((i) => '${i.product.name}x${i.quantity}')
          .join('; ');
      buffer.writeln(
        '"${s.id}","${Formatters.dateTime(s.date)}",${s.subtotal},'
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

  /// Export a full backup of all data as CSV files zipped.
  /// For simplicity, we'll share each file separately or combine into one.
  static Future<void> exportFullBackup() async {
    final productsController = Get.find<ProductsController>();
    final salesController = Get.find<SalesController>();
    final expensesController = Get.find<ExpensesController>();

    final buffer = StringBuffer();

    // Products section
    buffer.writeln('=== PRODUCTS ===');
    buffer.writeln('SKU,Name,Brand,Category,Price,Purchase Price,Discount %,Stock');
    for (final p in productsController.products) {
      buffer.writeln(
        '"${p.sku}","${p.name}","${p.brand}","${p.category}",'
        '${p.price},${p.purchasePrice},${p.discount},${p.stock}',
      );
    }

    buffer.writeln();
    buffer.writeln('=== SALES ===');
    buffer.writeln(
      'Sale ID,Date,Subtotal,Checkout Discount %,Tax Amount,Total,'
      'Cash,Change,Discount Amount,Profit,Customer ID,Items',
    );
    for (final s in salesController.sales) {
      final itemsSummary = s.items
          .map((i) => '${i.product.name}x${i.quantity}')
          .join('; ');
      buffer.writeln(
        '"${s.id}","${Formatters.dateTime(s.date)}",${s.subtotal},'
        '${s.checkoutDiscount},${s.taxAmount},${s.total},'
        '${s.cash},${s.change},${s.discount},${s.profit},'
        '"${s.customerId}","$itemsSummary"',
      );
    }

    buffer.writeln();
    buffer.writeln('=== EXPENSES ===');
    buffer.writeln('Expense ID,Date,Category,Amount,Description');
    for (final e in expensesController.expenses) {
      buffer.writeln(
        '"${e.id}","${Formatters.dateTime(e.date)}","${e.category}",'
        '${e.amount},"${e.description}"',
      );
    }

    await _shareCsv(buffer.toString(), 'full_backup');
  }

  /// Write CSV to a temp file and share.
  static Future<void> _shareCsv(String csvContent, String prefix) async {
    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
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
