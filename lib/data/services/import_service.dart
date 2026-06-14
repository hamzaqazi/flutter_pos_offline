import 'dart:convert';
import 'dart:io';
import 'package:ad_shop_pos/data/services/hive_service.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// Service for importing data from a JSON backup file.
class ImportService {
  /// Pick a JSON backup file and return its parsed content.
  /// Returns null if user cancels or file is invalid.
  static Future<Map<String, dynamic>?> pickBackupFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Select Backup File',
      );

      if (result == null || result.files.isEmpty) return null;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();

      final data = jsonDecode(content) as Map<String, dynamic>;

      // Validate it's a valid backup
      if (data['app'] != 'ad_shop_pos') {
        Get.snackbar(
          "Invalid file",
          "This is not a valid Shop POS backup file",
          snackPosition: SnackPosition.BOTTOM,
        );
        return null;
      }

      return data;
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to read backup file: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  /// Analyze a backup and return a summary of what's in it.
  static BackupSummary analyzeBackup(Map<String, dynamic> data) {
    return BackupSummary(
      exportedAt: data['exportedAt'] as String? ?? 'Unknown',
      version: data['version'] as int? ?? 1,
      productCount: (data['products'] as List?)?.length ?? 0,
      saleCount: (data['sales'] as List?)?.length ?? 0,
      expenseCount: (data['expenses'] as List?)?.length ?? 0,
      returnCount: (data['returns'] as List?)?.length ?? 0,
      customerCount: (data['customers'] as List?)?.length ?? 0,
      staffCount: (data['staff'] as List?)?.length ?? 0,
      hasSettings: data.containsKey('settings'),
    );
  }

  /// Import all data from a backup, replacing existing data.
  /// Returns true on success.
  static Future<bool> importBackup(
    Map<String, dynamic> data, {
    bool replaceExisting = true,
  }) async {
    try {
      if (replaceExisting) {
        await _clearAllData();
      }

      // Import products
      final products = (data['products'] as List?) ?? [];
      final productBox = HiveService.productBox;
      for (final p in products) {
        final map = Map<String, dynamic>.from(p);
        productBox.put(map['id'], map);
      }

      // Import sales
      final sales = (data['sales'] as List?) ?? [];
      final salesBox = HiveService.salesBox;
      for (final s in sales) {
        final map = Map<String, dynamic>.from(s);
        // Ensure items list is properly stored
        if (map['items'] != null) {
          map['items'] = List<Map<String, dynamic>>.from(
            (map['items'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
        salesBox.put(map['id'], map);
      }

      // Import expenses
      final expenses = (data['expenses'] as List?) ?? [];
      final expensesBox = Hive.box('expenses');
      for (final e in expenses) {
        final map = Map<String, dynamic>.from(e);
        expensesBox.put(map['id'], map);
      }

      // Import returns
      final returns = (data['returns'] as List?) ?? [];
      final returnsBox = HiveService.returnsBox;
      for (final r in returns) {
        final map = Map<String, dynamic>.from(r);
        // Ensure items list is properly stored
        if (map['items'] != null) {
          map['items'] = List<Map<String, dynamic>>.from(
            (map['items'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
        }
        returnsBox.put(map['id'], map);
      }

      // Import customers
      final customers = (data['customers'] as List?) ?? [];
      final customersBox = HiveService.customersBox;
      for (final c in customers) {
        final map = Map<String, dynamic>.from(c);
        customersBox.put(map['id'], map);
      }

      // Import staff
      final staff = (data['staff'] as List?) ?? [];
      final staffBox = HiveService.staffBox;
      for (final s in staff) {
        final map = Map<String, dynamic>.from(s);
        // Skip the activeCashierId entry — handle separately
        if (map['id'] != null && map['id'] != 'activeCashierId') {
          staffBox.put(map['id'], map);
        }
      }

      // Import active cashier
      if (data['activeCashierId'] != null) {
        staffBox.put('activeCashierId', data['activeCashierId']);
      }

      // Import settings
      if (data['settings'] != null) {
        final settingsBox = Hive.box('settings');
        settingsBox.put('shop', Map<String, dynamic>.from(data['settings']));
      }

      // Reload all controllers
      await _reloadAllControllers();

      return true;
    } catch (e) {
      Get.snackbar(
        "Import failed",
        "Could not import backup: $e",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  /// Clear all data from Hive boxes (used before replace import).
  static Future<void> _clearAllData() async {
    await HiveService.productBox.clear();
    await HiveService.salesBox.clear();
    await Hive.box('expenses').clear();
    await HiveService.returnsBox.clear();
    await HiveService.customersBox.clear();
    await HiveService.staffBox.clear();
    await Hive.box('settings').clear();
  }

  /// Reload all controllers so they pick up the imported data.
  static Future<void> _reloadAllControllers() async {
    try {
      Get.find<ProductsController>().loadProducts();
    } catch (_) {}
    try {
      Get.find<SalesController>().loadSales();
    } catch (_) {}
    try {
      Get.find<ExpensesController>().loadExpenses();
    } catch (_) {}
    try {
      Get.find<ReturnsController>().loadReturns();
    } catch (_) {}
    try {
      Get.find<CustomersController>().loadCustomers();
    } catch (_) {}
    try {
      Get.find<StaffController>().loadStaff();
    } catch (_) {}
    try {
      Get.find<SettingsController>().loadSettings();
    } catch (_) {}
  }
}

/// Summary of a backup file's contents.
class BackupSummary {
  final String exportedAt;
  final int version;
  final int productCount;
  final int saleCount;
  final int expenseCount;
  final int returnCount;
  final int customerCount;
  final int staffCount;
  final bool hasSettings;

  BackupSummary({
    required this.exportedAt,
    required this.version,
    required this.productCount,
    required this.saleCount,
    required this.expenseCount,
    required this.returnCount,
    required this.customerCount,
    required this.staffCount,
    required this.hasSettings,
  });

  int get totalRecords =>
      productCount +
      saleCount +
      expenseCount +
      returnCount +
      customerCount +
      staffCount;

  String get formattedDate {
    try {
      final dt = DateTime.parse(exportedAt);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return exportedAt;
    }
  }
}
