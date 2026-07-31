import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/cart/cart_page.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_page.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/products/products_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_history_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Main navigation shell — hosts all 5 tab pages in an [IndexedStack].
///
/// Tab switching is instant (no rebuild/splash) because all pages stay alive.
/// The bottom [NavigationBar] is the [Scaffold]'s [bottomNavigationBar],
/// so FABs and content are correctly positioned above it.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _destinations = [
    _NavDestination(
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      label: 'Home',
    ),
    _NavDestination(
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
      label: 'Products',
    ),
    _NavDestination(
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale_rounded,
      label: 'POS',
    ),
    _NavDestination(
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long_rounded,
      label: 'Sales',
    ),
    _NavDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final shellCtrl = Get.find<ShellController>();

    return Obx(() {
      final index = shellCtrl.currentIndex;

      return Scaffold(
        body: IndexedStack(
          index: index,
          children: const [
            DashboardPage(),
            ProductsPage(),
            CartPage(),
            SalesHistoryPage(),
            SettingsPage(),
          ],
        ),
        bottomNavigationBar: Container(
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
            onDestinationSelected: shellCtrl.switchTab,
            height: 64,
            elevation: 0,
            backgroundColor: cs.surface,
            indicatorColor: cs.primary.withValues(alpha: 0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: _destinations.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              // Products tab (index 1) gets low stock badge
              if (i == 1) {
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
      );
    });
  }
}

/// Products icon with low stock badge.
class _ProductsIcon extends StatelessWidget {
  const _ProductsIcon({required this.d, required this.selected});
  final _NavDestination d;
  final bool selected;

  @override
  Widget build(BuildContext context) {
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

/// Navigation destination data.
class _NavDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
