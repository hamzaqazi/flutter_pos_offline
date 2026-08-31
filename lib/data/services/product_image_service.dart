import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles picking + storing product photos.
///
/// Images are copied from the picker's temp cache into the app's documents
/// directory (`product_images/`) so they survive cache clears. The stored
/// file path is saved on the product in Hive.
class ProductImageService {
  /// Pick an image from [source] (camera or gallery), downscale it, copy it
  /// into permanent app storage, and return the saved file path.
  /// Returns null if the user cancelled.
  static Future<String?> pickAndSave(ImageSource source) async {
    // The app manifest declares CAMERA (for the barcode scanner), so
    // image_picker requires the permission to be granted before using
    // the camera source.
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) return null;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docs.path}/product_images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final ext = picked.path.contains('.')
        ? picked.path.split('.').last
        : 'jpg';
    final fileName = 'prod_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final saved = await File(picked.path).copy('${imagesDir.path}/$fileName');
    return saved.path;
  }

  /// Delete a stored product image file (safe to call with null/missing path).
  static Future<void> deleteImage(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore — worst case an orphan file stays on disk.
    }
  }
}
