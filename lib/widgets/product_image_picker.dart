import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../app/theme/app_theme.dart';
import '../data/services/product_image_service.dart';

/// A compact "product photo" row used inside the Add/Edit product dialogs.
///
/// Shows a 64x64 thumbnail (or a placeholder icon), lets the user pick a
/// photo from camera/gallery via a bottom sheet, and remove it with an X.
/// The parent owns the state: it passes [imagePath] and gets updates
/// through [onChanged].
class ProductImagePicker extends StatelessWidget {
  const ProductImagePicker({
    super.key,
    required this.imagePath,
    required this.onChanged,
  });

  final String? imagePath;
  final ValueChanged<String?> onChanged;

  bool get _hasImage =>
      imagePath != null &&
      imagePath!.isNotEmpty &&
      File(imagePath!).existsSync();

  Future<void> _pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final path = await ProductImageService.pickAndSave(source);
    if (path != null) onChanged(path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasImage = _hasImage;

    return Row(
      children: [
        InkWell(
          onTap: () => _pick(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          child: Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: hasImage
                ? Image.file(
                    File(imagePath!),
                    fit: BoxFit.cover,
                    cacheWidth: 192,
                  )
                : Icon(Icons.add_a_photo_outlined, color: cs.primary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product photo',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                hasImage ? 'Tap to change' : 'Optional — tap to add',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (hasImage)
          IconButton(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Remove photo',
          ),
      ],
    );
  }
}
