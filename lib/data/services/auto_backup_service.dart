import 'dart:convert';
import 'package:ad_shop_pos/app/utils/backup_io_bridge.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/data/services/google_drive_service.dart';
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

/// Service for automatic backup scheduling.
///
/// Saves full JSON backups:
/// - **Native (Android/iOS/desktop)**: To the device's Documents filesystem.
/// - **Web**: To a dedicated Hive box (`web_backups`) backed by IndexedDB.
///
/// Scheduling:
/// - **Native**: Uses Workmanager for periodic background tasks.
/// - **Web**: In-app check on launch only (no background tasks on web).
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

  /// Hive box name for web backups (stored in IndexedDB on web).
  static const webBackupBoxName = 'web_backups';

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
  /// On web, this is a no-op (web uses in-app check on launch only).
  static Future<void> scheduleAutoBackup() async {
    if (!isEnabled || frequency == 'manual') {
      await cancelAutoBackup();
      return;
    }

    if (kIsWeb) {
      debugPrint('✅ Web: auto-backup will use in-app check on launch');
      return;
    }

    // Native: use Workmanager for periodic background task.
    final duration = frequency == 'daily'
        ? const Duration(hours: 24)
        : const Duration(days: 7);

    await registerPeriodicBackupTask(duration);
  }

  /// Cancel the auto-backup task.
  /// On web, this is a no-op.
  static Future<void> cancelAutoBackup() async {
    if (kIsWeb) return;
    await cancelPeriodicBackupTask();
  }

  // ─── In-App Check ────────────────────────────────────────────

  /// Check if a backup is due and run one if needed.
  /// Call this on app start and periodically while the app is open.
  /// Works on both web and native.
  static Future<bool> checkAndRunIfNeeded() async {
    if (!isEnabled || frequency == 'manual') return false;

    final lastDate = lastBackupDate;
    if (lastDate == null) {
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

  /// Perform an automatic backup.
  /// - **Web**: Saves to Hive box `web_backups` (IndexedDB).
  /// - **Native**: Saves to filesystem directory.
  /// Returns true if successful.
  static Future<bool> performAutoBackup() async {
    try {
      debugPrint('🔄 Running auto-backup...');

      final backupData = await _collectBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-')
          .substring(0, 22);
      final filename = 'auto_backup_$timestamp.json';

      if (kIsWeb) {
        // ── Web: save to Hive box (persisted in IndexedDB) ──
        final box = Hive.box(webBackupBoxName);
        await box.put(filename, jsonStr);
        debugPrint('✅ Auto-backup saved to web storage: $filename');
      } else {
        // ── Native: save to filesystem ──
        await writeBackupFile(filename, jsonStr);
        debugPrint('✅ Auto-backup saved to filesystem: $filename');
      }

      // Update last backup time
      await _settingsBox.put(_keyLastBackup, DateTime.now().toIso8601String());

      // Prune old backups
      await _pruneOldBackups();

      // Also upload to Google Drive if opted in and signed in.
      if (GoogleDriveService.isEnabled && GoogleDriveService.isSignedIn) {
        final uploaded = await GoogleDriveService.uploadBackup(jsonStr);
        debugPrint(uploaded
            ? '☁️ Auto-backup uploaded to Drive'
            : '⚠️ Auto-backup Drive upload failed');
      }

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

  /// Prune old backups beyond the keep limit.
  static Future<void> _pruneOldBackups() async {
    final limit = keepLast;

    if (kIsWeb) {
      final box = Hive.box(webBackupBoxName);
      final keys = box.keys
          .where((k) => k.toString().startsWith('auto_backup_'))
          .toList();

      // Sort newest first (lexicographic on timestamp part)
      keys.sort((a, b) {
        final ta = a
            .toString()
            .replaceAll('auto_backup_', '')
            .replaceAll('.json', '');
        final tb = b
            .toString()
            .replaceAll('auto_backup_', '')
            .replaceAll('.json', '');
        return tb.compareTo(ta);
      });

      if (keys.length > limit) {
        for (var i = limit; i < keys.length; i++) {
          await box.delete(keys[i]);
          debugPrint('🗑️ Deleted old web backup: ${keys[i]}');
        }
      }
    } else {
      await pruneNativeBackups(limit);
    }
  }

  /// List all auto-backup files with metadata.
  static Future<List<BackupFileInfo>> listBackups() async {
    if (kIsWeb) {
      return _listWebBackups();
    } else {
      return _listNativeBackups();
    }
  }

  /// List web backups from Hive box.
  static Future<List<BackupFileInfo>> _listWebBackups() async {
    final box = Hive.box(webBackupBoxName);
    final keys = box.keys
        .where((k) => k.toString().startsWith('auto_backup_'))
        .toList();

    final files = <BackupFileInfo>[];

    for (final key in keys) {
      final filename = key.toString();
      final content = box.get(key) as String?;
      if (content == null) continue;

      final sizeKB = (content.length / 1024).round();
      final date = _parseTimestampFromFilename(filename) ?? DateTime.now();

      files.add(
        BackupFileInfo(
          filename: filename,
          date: date,
          sizeKB: sizeKB,
          storageKey: filename,
        ),
      );
    }

    // Sort newest first
    files.sort((a, b) => b.date.compareTo(a.date));
    return files;
  }

  /// List native backup files from filesystem.
  static Future<List<BackupFileInfo>> _listNativeBackups() async {
    try {
      final rawFiles = await listNativeBackupFiles();
      return rawFiles.map((f) {
        return BackupFileInfo(
          filename: f['filename'] as String,
          date: DateTime.fromMillisecondsSinceEpoch(f['modified'] as int),
          sizeKB: f['sizeKB'] as int,
          nativeFilePath: f['path'] as String,
        );
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint('⚠️ List native backups failed: $e');
      return [];
    }
  }

  /// Parse DateTime from auto_backup filename.
  /// Format: auto_backup_2024-01-15T10-30-00-123.json
  static DateTime? _parseTimestampFromFilename(String filename) {
    try {
      final tsPart = filename
          .replaceAll('auto_backup_', '')
          .replaceAll('.json', '');
      final parts =
          tsPart.split(RegExp(r'[^0-9]')).where((s) => s.isNotEmpty).toList();
      if (parts.length >= 6) {
        return DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
          int.parse(parts[3]),
          int.parse(parts[4]),
          int.parse(parts[5]),
          parts.length > 6
              ? int.parse(parts[6].padRight(3, '0').substring(0, 3)) * 1000
              : 0,
        );
      }
    } catch (_) {}
    return null;
  }

  /// Delete a specific backup.
  static Future<void> deleteBackup(BackupFileInfo info) async {
    if (kIsWeb) {
      final box = Hive.box(webBackupBoxName);
      await box.delete(info.storageKey ?? info.filename);
    } else if (info.nativeFilePath != null) {
      await deleteNativeFile(info.nativeFilePath!);
    }
  }

  /// Delete all auto-backup files.
  static Future<void> deleteAllBackups() async {
    if (kIsWeb) {
      final box = Hive.box(webBackupBoxName);
      await box.clear();
    } else {
      await deleteBackupDir();
    }
    await _settingsBox.delete(_keyLastBackup);
  }

  /// Get total size of all backups in KB.
  static Future<int> totalBackupSizeKB() async {
    final backups = await listBackups();
    return backups.fold<int>(0, (sum, b) => sum + b.sizeKB);
  }

  /// Read a backup and return its parsed JSON content.
  static Future<Map<String, dynamic>?> readBackupFile(
      BackupFileInfo info) async {
    try {
      String? content;

      if (kIsWeb) {
        final box = Hive.box(webBackupBoxName);
        content = box.get(info.storageKey ?? info.filename) as String?;
      } else if (info.nativeFilePath != null) {
        content = await readNativeFile(info.nativeFilePath!);
      }

      if (content == null) return null;
      final data = jsonDecode(content) as Map<String, dynamic>;
      if (data['app'] != 'ad_shop_pos') return null;
      return data;
    } catch (e) {
      debugPrint('⚠️ Failed to read backup: $e');
      return null;
    }
  }

  /// Perform a manual backup now.
  static Future<bool> backupNow() async {
    return await performAutoBackup();
  }

  /// Upload a fresh backup to Google Drive.
  /// Works on both web and native (GoogleDriveService is web-safe).
  static Future<bool> uploadToDriveNow() async {
    try {
      final backupData = await _collectBackupData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(backupData);
      return await GoogleDriveService.uploadBackup(jsonStr);
    } catch (e) {
      debugPrint('🔥 Drive backup-now failed: $e');
      return false;
    }
  }

  /// Create a fresh backup JSON string (for download/share).
  static Future<String?> createBackupJson() async {
    try {
      final backupData = await _collectBackupData();
      return const JsonEncoder.withIndent('  ').convert(backupData);
    } catch (e) {
      debugPrint('🔥 Create backup JSON failed: $e');
      return null;
    }
  }
}

/// Info about a backup file.
///
/// On **native**: [nativeFilePath] is set (filesystem path), [storageKey] is null.
/// On **web**: [storageKey] is set (Hive box key), [nativeFilePath] is null.
class BackupFileInfo {
  final String filename;
  final DateTime date;
  final int sizeKB;

  /// Native filesystem path (null on web).
  final String? nativeFilePath;

  /// Web Hive box key (null on native).
  final String? storageKey;

  const BackupFileInfo({
    required this.filename,
    required this.date,
    required this.sizeKB,
    this.nativeFilePath,
    this.storageKey,
  });

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (sizeKB < 1024) return '$sizeKB KB';
    return '${(sizeKB / 1024).toStringAsFixed(1)} MB';
  }
}
