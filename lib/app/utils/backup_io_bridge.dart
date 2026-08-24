/// Conditional import bridge for backup I/O operations.
///
/// On native platforms: imports `backup_io.dart` (which uses dart:io).
/// On web: imports `backup_io_stub.dart` (which provides no-op stubs).
///
/// Usage: `import 'package:ad_shop_pos/app/utils/backup_io_bridge.dart';`
export 'backup_io_stub.dart' if (dart.library.io) 'backup_io.dart';
