/// Web stub implementation of backup I/O operations.
/// This file is used on web platforms where dart:io is unavailable.
/// All native filesystem/Workmanager calls are no-ops or throw.
library;

import 'package:flutter/foundation.dart';

/// No-op on web. Backups stored in Hive.
Future<String> ensureBackupDir() async {
  throw UnsupportedError('Filesystem not available on web');
}

/// No-op on web. Backups stored in Hive.
Future<void> writeBackupFile(String filename, String content) async {
  throw UnsupportedError('Filesystem not available on web');
}

/// No-op on web.
Future<String> readNativeFile(String path) async {
  throw UnsupportedError('Filesystem not available on web');
}

/// No-op on web.
Future<String> getBackupDirPath() async {
  throw UnsupportedError('Filesystem not available on web');
}

/// No-op on web.
Future<bool> backupDirExists() async => false;

/// No-op on web. Returns empty list.
Future<List<Map<String, dynamic>>> listNativeBackupFiles() async => [];

/// No-op on web. Pruning handled by Hive-based logic in AutoBackupService.
Future<void> pruneNativeBackups(int keepLast) async {}

/// No-op on web.
Future<void> deleteNativeFile(String path) async {}

/// No-op on web.
Future<void> deleteBackupDir() async {}

/// No-op on web. Use browser download instead.
Future<void> shareNativeFile(
  String filePath, {
  String? subject,
  String? text,
}) async {
  throw UnsupportedError('Use browser download on web');
}

/// No-op on web.
Future<String> writeTempFile(String filename, String content) async {
  throw UnsupportedError('Filesystem not available on web');
}

/// No-op on web. Workmanager not available on web.
Future<void> initWorkmanager() async {}

/// No-op on web.
Future<void> registerPeriodicBackupTask(Duration frequency) async {}

/// No-op on web.
Future<void> cancelPeriodicBackupTask() async {}

/// Stub callback dispatcher for web (never invoked).
@pragma('vm:entry-point')
void callbackDispatcher() {
  // No-op on web
}
