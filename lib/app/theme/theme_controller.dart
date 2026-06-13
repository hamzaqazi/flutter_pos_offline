import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Controls the app's light/dark theme mode.
class ThemeController extends GetxController {
  final isDark = false.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    isDark.value = !isDark.value;
    Get.changeThemeMode(themeMode);
  }
}
