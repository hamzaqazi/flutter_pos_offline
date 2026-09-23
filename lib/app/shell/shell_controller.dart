import 'package:get/get.dart';

/// Controller for the AppShell navigation state.
/// Manages the current tab index and provides methods for tab switching.
class ShellController extends GetxController {
  static ShellController get to => Get.find();

  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  /// Switch to a tab by index. No-op if already on the same tab.
  void switchTab(int index) {
    if (index == _currentIndex.value) return;
    _currentIndex.value = index;
  }

  /// Navigate to a tab from anywhere (e.g., from a non-tab page).
  /// If not on the AppShell route, pops back first.
  Future<void> navigateToTab(int index) async {
    final currentRoute = Get.currentRoute;
    // If we're on a non-tab page, pop back to the shell first
    if (currentRoute != '/' && currentRoute != '/dashboard') {
      Get.until((route) {
        final name = route.settings.name;
        return name == '/' || name == '/dashboard';
      });
    }
    switchTab(index);
  }

  // Convenience methods
  void goHome() => switchTab(0);
  void goProducts() => switchTab(1);
  void goCart() => switchTab(2);
  void goSales() => switchTab(3);
  void goSettings() => switchTab(4);
}
