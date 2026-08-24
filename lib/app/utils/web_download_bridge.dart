/// Conditional import bridge for web file download.
///
/// On web: imports web_download.dart (uses dart:html Blob + anchor download).
/// On native: imports web_download_stub.dart (throws — use share_plus instead).
export 'web_download_stub.dart' if (dart.library.html) 'web_download.dart';
