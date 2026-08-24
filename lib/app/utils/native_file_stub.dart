import 'package:flutter/material.dart';

/// Stub: createFile throws on web.
dynamic createFile(String path) => throw UnsupportedError('File not available on web');

/// Stub: createFileImage returns a placeholder on web.
ImageProvider<Object> createFileImage(String path) => const AssetImage('lib/assets/images/cn_pos_logo_rm.png');
