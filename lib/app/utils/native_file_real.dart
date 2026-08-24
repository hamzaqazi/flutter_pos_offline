import 'dart:io';
import 'package:flutter/material.dart';

/// Create a dart:io File object (native only).
File createFile(String path) => File(path);

/// Create an Image.file widget (native only).
ImageProvider<Object> createFileImage(String path) => FileImage(File(path));
