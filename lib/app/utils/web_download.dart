/// Web implementation of file download using the browser's anchor download API.
/// Uses dart:html to create a Blob, object URL, and invisible anchor click.
library;

import 'dart:html';
import 'dart:js_interop';

/// Trigger a browser file download with the given content and filename.
/// Works reliably on all modern browsers — creates a Blob, generates an
/// object URL, clicks an invisible <a download="filename">, then revokes.
Future<bool> downloadFileOnWeb(String content, String filename, String mimeType) async {
  try {
    // Create a Blob from the content string
    final jsContent = content.toJS;
    final jsArray = [jsContent].toJS;
    final blob = Blob(jsArray, '$mimeType;charset=utf-8');

    // Create an object URL from the Blob
    final url = Url.createObjectUrlFromBlob(blob);

    // Create an invisible anchor element
    final anchor = AnchorElement()
      ..href = url
      ..setAttribute('download', filename)
      ..style.display = 'none';

    // Add to DOM, click, then remove
    document.body!.append(anchor);
    anchor.click();
    anchor.remove();

    // Revoke the object URL to free memory
    Url.revokeObjectUrl(url);

    return true;
  } catch (e) {
    // Fallback: try window.open with data URI
    try {
      final encoded = Uri.encodeComponent(content);
      final dataUri = 'data:$mimeType;charset=utf-8,$encoded';
      window.open(dataUri, '_blank');
      return true;
    } catch (e2) {
      return false;
    }
  }
}
