/// Native stub for web download — always throws since native uses share_plus instead.
library;

/// Not available on native platforms. Use share_plus instead.
Future<bool> downloadFileOnWeb(String content, String filename, String mimeType) async {
  throw UnsupportedError('downloadFileOnWeb is only available on web. Use share_plus on native.');
}
