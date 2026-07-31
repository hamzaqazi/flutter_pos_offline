import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main navigation shell — wraps pages with a bottom navigation bar.
///
/// Usage: Wrap any main page's Scaffold body with AppShell:
///   Scaffold(body: AppShell(child: MyPageContent()))
///
/// Or use the convenience builder:
///   AppShell(currentRoute: '/products', child: ProductsPage())
///
/// The shell detects the current route from GetX routing and highlights
/// the correct tab. Tapping a tab navigates via Get.toNamed().
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    this.currentRoute,
  });

  /// The page content to display above the nav bar.
  final Widget child;

  /// Override the current route detection (optional).
  /// If null, uses Get.currentRoute.
  final String? currentRoute;

  // ── Navigation destinations ──
  static const _destinations = [
    _NavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
      route: '/',
    ),
    _NavDestination(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Products',
      route: '/products',
    ),
    _NavDestination(
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale_rounded,
      label: 'POS',
      route: '/cart',
    ),
    _NavDestination(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Sales',
      route: '/sales',
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'More',
      route: '/settings',
    ),
  ];

  int _currentIndex(String route) {
    // Exact match first
    for (int i = 0; i < _destinations.length; i++) {
      if (_destinations[i].route == route) return i;
    }
    // Prefix match (e.g. /sales matches /sales, /sales/123)
    for (int i = 0; i < _destinations.length; i++) {
      if (route.startsWith(_destinations[i].route)) return i;
    }
    // Default to home
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final route = currentRoute ?? Get.currentRoute;
    final index = _currentIndex(route);

    return Column(
      children: [
        // ── Page content ──
        Expanded(child: child),

        // ── Bottom navigation ──
        Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.borderLight,
                width: 0.5,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (i) {
              if (i == index) return;
              // Use offAllNamed to clear the navigation stack
              // so back button doesn't go through old pages
              Get.offAllNamed(_destinations[i].route);
            },
            height: 64,
            elevation: 0,
            backgroundColor: cs.surface,
            indicatorColor: cs.primary.withValues(alpha: 0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _destinations.map((d) {
              // Add badge for low stock on Products tab
              if (d.route == '/products') {
                return NavigationDestination(
                  icon: _ProductsIcon(d: d, selected: false),
                  selectedIcon: _ProductsIcon(d: d, selected: true),
                  label: d.label,
                );
              }
              return NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Products icon with low stock badge.
class _ProductsIcon extends StatelessWidget {
  const _ProductsIcon({required this.d, required this.selected});
  final _NavDestination d;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = Icon(selected ? d.activeIcon : d.icon);

    try {
      final ctrl = Get.find<ProductsController>();
      final settings = SettingsService.getSettings();
      return Obx(() {
        final count = ctrl.products
            .where((p) => p.stock <= settings.lowStockThreshold)
            .length;
        if (count == 0) return icon;
        return Badge(
          label: Text('$count'),
          isLabelVisible: count > 0,
          child: icon,
        );
      });
    } catch (_) {
      return icon;
    }
  }
}

/// ── Navigation destination data ──
class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String route;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });
}
