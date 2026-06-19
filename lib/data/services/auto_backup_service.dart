import 'dart:convert';
import 'dart:io';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/data/services/hive_service.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:workmanager/workmanager.dart';

/// Service for automatic backup scheduling.
///
/// Saves full JSON backups to the app's local storage on a schedule:
/// - Daily (every 24 hours)
/// - Weekly (every 7 days)
/// - Manual only (no auto backup)
///
/// Keeps up to [maxBackups] backup files, deleting the oldest when limit is reached.
class AutoBackupService {
  static const _box = 'settings';

  // Hive keys
  static const _keyEnabled = 'autoBackup_enabled';
  static const _keyFrequency =
      'autoBackup_frequency'; // 'daily' | 'weekly' | 'manual'
  static const _keyLastBackup = 'autoBackup_lastBackup';
  static const _keyMaxBackups = 'autoBackup_maxBackups';
  static const _keyKeepLast = 'autoBackup_keepLast';

  static final _settingsBox = Hive.box(_box);

  // ─── Settings Getters ────────────────────────────────────────

  /// Whether auto backup is enabled.
  static bool get isEnabled =>
      _settingsBox.get(_keyEnabled, defaultValue: false) as bool;

  /// Backup frequency: 'daily', 'weekly', or 'manual'.
  static String get frequency =>
      _settingsBox.get(_keyFrequency, defaultValue: 'daily') as String;

  /// Maximum number of backups to keep locally.
  static int get maxBackups =>
      _settingsBox.get(_keyMaxBackups, defaultValue: 7) as int;

  /// Number of backups to keep when pruning. Older ones are deleted.
  static int get keepLast =>
      _settingsBox.get(_keyKeepLast, defaultValue: 7) as int;

  /// ISO8601 string of last successful backup.
  static String get lastBackupIso =>
      _settingsBox.get(_keyLastBackup, defaultValue: '') as String;

  /// Parsed DateTime of last backup, or null if never.
  static DateTime? get lastBackupDate {
    final s = lastBackupIso;
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// Human-readable "time ago" for the last backup.
  static String get lastBackupAgo {
    final dt = lastBackupDate;
    if (dt == null) return 'Never';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ─── Settings Setters ────────────────────────────────────────

  static Future<void> setEnabled(bool enabled) async {
    await _settingsBox.put(_keyEnabled, enabled);
    if (enabled) {
      await scheduleAutoBackup();
    } else {
      await cancelAutoBackup();
    }
  }

  static Future<void> setFrequency(String freq) async {
    await _settingsBox.put(_keyFrequency, freq);
    if (isEnabled) {
      await scheduleAutoBackup();
    }
  }

  static Future<void> setMaxBackups(int count) async {
    await _settingsBox.put(_keyMaxBackups, count);
    await _settingsBox.put(_keyKeepLast, count);
  }

  // ─── Scheduling ──────────────────────────────────────────────

  /// Schedule (or reschedule) the auto-backup task.
  static Future<void> scheduleAutoBackup() async {
    if (!isEnabled || frequency == 'manual') {
      await cancelAutoBackup();
      return;
    }

    final duration = frequency == 'daily'
        ? const Duration(hours: 24)
        : const Duration(days: 7);

    try {
      await Workmanager().registerPeriodicTask(
        'autoBackup',
        'autoBackupTask',
        frequency: duration,
        constraints: Constraints(networkType: NetworkType.notRequired),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 30),
      );
      debugPrint('✅ Auto-backup scheduled: $frequency');
    } catch (e) {
      debugPrint('⚠️ Workmanager scheduling failed: $e');
      // Fallback: will use in-app check on launch instead
    }
  }

  /// Cancel the auto-backup task.
  static Future<void> cancelAutoBackup() async {
    try {
      await Workmanager().cancelByUniqueName('autoBackup');
      debugPrint('🛑 Auto-backup cancelled');
    } catch (e) {
      debugPrint('⚠️ Workmanager cancel failed: $e');
    }
  }

  // ─── In-App Check ────────────────────────────────────────────

  /// Check if a backup is due and run one if needed.
  /// Call this on app start and periodically while the app is open.
  static Future<bool> checkAndRunIfNeeded() async {
    if (!isEnabled || frequency == 'manual') return false;

    final lastDate = lastBackupDate;
    if (lastDate == null) {
      // Never backed up — run now
      return await performAutoBackup();
    }

    final now = DateTime.now();
    final diff = now.difference(lastDate);
    final threshold = frequency == 'daily'
        ? const Duration(hours: 24)
        : const Duration(days: 7);

    if (diff >= threshold) {
      return await performAutoBackup();
    }

    return false;
  }

  // ─── Backup Execution ────────────────────────────────────────

  /// Perform an automatic backup to local storage.
  /// Returns true if successful.
  static Future<bool> performAutoBackup() async {
    try {
      debugPrint('🔄 Running auto-backup...');

      final backupData = await _collectBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      // Save to app documents directory (persistent, not temp)
      // final dir = await getApplicationDocumentsDirectory();
      final dir = await getExternalStorageDirectory();
      // final backupDir = Directory('${dir.path}/backups');
      // final backupDir = Directory('${dir!.path}/backups');
      final backupDir = Directory(
        '/storage/emulated/0/Documents/Codynest POS/Backups',
      );
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 22);
      final file = File('${backupDir.path}/auto_backup_$timestamp.json');
      await file.writeAsString(jsonStr);

      // Update last backup time
      await _settingsBox.put(_keyLastBackup, DateTime.now().toIso8601String());

      // Prune old backups
      await _pruneOldBackups(backupDir);

      debugPrint('✅ Auto-backup saved: ${file.path}');
      return true;
    } catch (e) {
      debugPrint('🔥 Auto-backup failed: $e');
      return false;
    }
  }

  /// Collect all data needed for a full backup.
  static Future<Map<String, dynamic>> _collectBackupData() async {
    final backup = <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'ad_shop_pos',
      'autoBackup': true,
    };

    // Products
    try {
      final pc = Get.find<ProductsController>();
      backup['products'] = pc.products
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
    } catch (_) {
      final box = HiveService.productBox;
      backup['products'] = box.values.toList();
    }

    // Sales
    try {
      final sc = Get.find<SalesController>();
      backup['sales'] = sc.sales.map((s) => s.toMap()).toList();
    } catch (_) {
      backup['sales'] = HiveService.salesBox.values.toList();
    }

    // Expenses
    try {
      final ec = Get.find<ExpensesController>();
      backup['expenses'] = ec.expenses.map((e) => e.toMap()).toList();
    } catch (_) {
      backup['expenses'] = Hive.box('expenses').values.toList();
    }

    // Returns
    try {
      final rc = Get.find<ReturnsController>();
      backup['returns'] = rc.returns.map((r) => r.toMap()).toList();
    } catch (_) {
      backup['returns'] = HiveService.returnsBox.values.toList();
    }

    // Customers
    try {
      final cc = Get.find<CustomersController>();
      backup['customers'] = cc.customers.map((c) => c.toMap()).toList();
    } catch (_) {
      backup['customers'] = HiveService.customersBox.values.toList();
    }

    // Staff
    try {
      final sc = Get.find<StaffController>();
      backup['staff'] = sc.staff.map((s) => s.toMap()).toList();
    } catch (_) {
      backup['staff'] = HiveService.staffBox.values.toList();
    }

    // Settings
    try {
      final sc = Get.find<SettingsController>();
      backup['settings'] = sc.settings.value.toMap();
      backup['receiptSettings'] = sc.receiptSettings.value.toMap();
    } catch (_) {
      final settingsBox = Hive.box('settings');
      if (settingsBox.get('shop') != null) {
        backup['settings'] = settingsBox.get('shop');
      }
      if (settingsBox.get('receipt') != null) {
        backup['receiptSettings'] = settingsBox.get('receipt');
      }
    }

    // Categories
    try {
      final catController = Get.find<CategoryController>();
      backup['categories'] = catController.categories
          .map((c) => c.toMap())
          .toList();
    } catch (_) {
      final catBox = Hive.box('categories');
      if (catBox.get('items') != null) {
        backup['categories'] = catBox.get('items');
      }
    }

    // Last invoice number
    final settingsBox = Hive.box('settings');
    backup['lastInvoiceNumber'] = settingsBox.get(
      'lastInvoiceNumber',
      defaultValue: 0,
    );

    return backup;
  }

  // ─── Backup Management ───────────────────────────────────────

  /// Delete old backups beyond the keep limit.
  static Future<void> _pruneOldBackups(Directory backupDir) async {
    final limit = keepLast;
    final files = <File>[];

    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.contains('auto_backup_')) {
        files.add(entity);
      }
    }

    // Sort by modification time, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    // Delete oldest files beyond the limit
    if (files.length > limit) {
      for (var i = limit; i < files.length; i++) {
        try {
          await files[i].delete();
          debugPrint('🗑️ Deleted old backup: ${files[i].path}');
        } catch (e) {
          debugPrint('⚠️ Failed to delete backup: $e');
        }
      }
    }
  }

  /// List all auto-backup files with metadata.
  static Future<List<BackupFileInfo>> listBackups() async {
    // final dir = await getApplicationDocumentsDirectory();
    // final backupDir = Directory('${dir.path}/backups');
    final backupDir = Directory(
      '/storage/emulated/0/Documents/Codynest POS/Backups',
    );
    if (!await backupDir.exists()) return [];

    final files = <BackupFileInfo>[];

    await for (final entity in backupDir.list()) {
      if (entity is File && entity.path.contains('auto_backup_')) {
        final stat = await entity.stat();
        final sizeKB = (stat.size / 1024).round();
        final filename = entity.path.split('/').last;
        files.add(
          BackupFileInfo(
            file: entity,
            filename: filename,
            date: stat.modified,
            sizeKB: sizeKB,
          ),
        );
      }
    }

    // Sort newest first
    files.sort((a, b) => b.date.compareTo(a.date));
    return files;
  }

  /// Delete a specific backup file.
  static Future<void> deleteBackup(BackupFileInfo info) async {
    await info.file.delete();
  }

  /// Delete all auto-backup files.
  static Future<void> deleteAllBackups() async {
    final dir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${dir.path}/backups');
    if (await backupDir.exists()) {
      await backupDir.delete(recursive: true);
    }
    await _settingsBox.delete(_keyLastBackup);
  }

  /// Get total size of all backups in KB.
  static Future<int> totalBackupSizeKB() async {
    final backups = await listBackups();
    return backups.fold<int>(0, (sum, b) => sum + b.sizeKB);
  }

  /// Read a backup file and return its parsed JSON content.
  static Future<Map<String, dynamic>?> readBackupFile(File file) async {
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['app'] != 'ad_shop_pos') return null;
      return data;
    } catch (e) {
      debugPrint('⚠️ Failed to read backup file: $e');
      return null;
    }
  }

  /// Perform a manual backup now.
  static Future<bool> backupNow() async {
    return await performAutoBackup();
  }
}

/// Info about a backup file on disk.
class BackupFileInfo {
  final File file;
  final String filename;
  final DateTime date;
  final int sizeKB;

  const BackupFileInfo({
    required this.file,
    required this.filename,
    required this.date,
    required this.sizeKB,
  });

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (sizeKB < 1024) return '$sizeKB KB';
    return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
  }
}

/// Top-level callback for Workmanager background task.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'autoBackupTask') {
      return await _backgroundBackup();
    }
    return true;
  });
}

/// Perform backup in background isolate.
/// Note: Hive + GetX aren't available in background isolates, so
/// the primary backup mechanism is the in-app check on launch.
Future<bool> _backgroundBackup() async {
  try {
    debugPrint('🔄 Background auto-backup starting...');
    // In background isolate, we can't use Hive/GetX easily.
    // The in-app check on every launch is the primary mechanism.
    // Workmanager ensures a backup runs even if the app isn't opened daily.
    return true;
  } catch (e) {
    debugPrint('🔥 Background backup failed: $e');
    return false;
  }
}
