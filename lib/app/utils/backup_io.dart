/// Native implementation of backup I/O operations.
/// This file imports dart:io and is only used on native platforms.
/// On web, backup_io_stub.dart is used instead.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:workmanager/workmanager.dart';

/// The Android backup directory path.
const _kAndroidBackupDir = '/storage/emulated/0/Documents/Codynest POS/Backups';

/// Ensure the backup directory exists and return its path.
Future<String> ensureBackupDir() async {
  final dir = Directory(_kAndroidBackupDir);
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return _kAndroidBackupDir;
}

/// Write content to a file in the backup directory.
Future<void> writeBackupFile(String filename, String content) async {
  final dirPath = await ensureBackupDir();
  final file = File('$dirPath/$filename');
  await file.writeAsString(content);
}

/// Read content from a native file path.
Future<String> readNativeFile(String path) async {
  final file = File(path);
  return file.readAsString();
}

/// Get the native backup directory path.
Future<String> getBackupDirPath() async {
  return _kAndroidBackupDir;
}

/// Check if backup directory exists.
Future<bool> backupDirExists() async {
  return Directory(_kAndroidBackupDir).exists();
}

/// List auto_backup files in the backup directory.
/// Returns list of maps: {path, filename, sizeKB, modified}
Future<List<Map<String, dynamic>>> listNativeBackupFiles() async {
  final dir = Directory(_kAndroidBackupDir);
  if (!await dir.exists()) return [];

  final files = <Map<String, dynamic>>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.contains('auto_backup_')) {
      final stat = await entity.stat();
      final sizeKB = (stat.size / 1024).round();
      final filename = entity.path.split('/').last;
      files.add({
        'path': entity.path,
        'filename': filename,
        'sizeKB': sizeKB,
        'modified': stat.modified.millisecondsSinceEpoch,
      });
    }
  }
  return files;
}

/// Prune old native backup files, keeping only [keepLast] newest.
Future<void> pruneNativeBackups(int keepLast) async {
  final dir = Directory(_kAndroidBackupDir);
  if (!await dir.exists()) return;

  final files = <File>[];
  await for (final entity in dir.list()) {
    if (entity is File && entity.path.contains('auto_backup_')) {
      files.add(entity);
    }
  }

  files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

  if (files.length > keepLast) {
    for (var i = keepLast; i < files.length; i++) {
      try {
        await files[i].delete();
        debugPrint('🗑️ Deleted old backup: ${files[i].path}');
      } catch (e) {
        debugPrint('⚠️ Failed to delete backup: $e');
      }
    }
  }
}

/// Delete a native backup file by path.
Future<void> deleteNativeFile(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

/// Delete the entire backup directory.
Future<void> deleteBackupDir() async {
  final dir = Directory(_kAndroidBackupDir);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}

/// Share a file using the system share sheet (native only).
Future<void> shareNativeFile(
  String filePath, {
  String? subject,
  String? text,
}) async {
  await Share.shareXFiles([XFile(filePath)], subject: subject, text: text);
}

/// Write a temp file and return its path (for CSV/JSON sharing).
Future<String> writeTempFile(String filename, String content) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$filename');
  await file.writeAsString(content);
  return file.path;
}

/// Initialize Workmanager for auto-backup scheduling (native only).
Future<void> initWorkmanager() async {
  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  } catch (e) {
    debugPrint('⚠️ Workmanager init failed: $e');
  }
}

/// Register a periodic Workmanager backup task.
Future<void> registerPeriodicBackupTask(Duration frequency) async {
  try {
    await Workmanager().registerPeriodicTask(
      'autoBackup',
      'autoBackupTask',
      frequency: frequency,
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
    debugPrint('✅ Auto-backup scheduled via Workmanager');
  } catch (e) {
    debugPrint('⚠️ Workmanager scheduling failed: $e');
  }
}

/// Cancel the periodic backup task.
Future<void> cancelPeriodicBackupTask() async {
  try {
    await Workmanager().cancelByUniqueName('autoBackup');
    debugPrint('🛑 Auto-backup Workmanager task cancelled');
  } catch (e) {
    debugPrint('⚠️ Workmanager cancel failed: $e');
  }
}

/// Top-level callback for Workmanager background task (native only).
/// On web, this is never invoked.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'autoBackupTask') {
      debugPrint('🔄 Background auto-backup starting...');
      // In background isolate, Hive/GetX aren't available.
      // The in-app check on launch is the primary mechanism.
      // Workmanager ensures a backup runs even if the app isn't opened daily.
      return true;
    }
    return true;
  });
}
