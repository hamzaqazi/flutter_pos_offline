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
/// The bottom nav is a floating pill that overlays the page content
/// ([Scaffold.extendBody]) rather than docking and reserving its own space —
/// tab pages add [AppSpacing.navClearance] of bottom clearance to their
/// scrollable content and any docked bars/FABs so nothing ends up hidden
/// underneath it.
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
      icon: Icons.shopping_cart_outlined,
      activeIcon: Icons.shopping_cart_rounded,
      label: 'Cart',
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

  /// The middle destination gets the raised circular treatment.
  static const _raisedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final shellCtrl = Get.find<ShellController>();

    return Obx(() {
      final index = shellCtrl.currentIndex;

      return Scaffold(
        extendBody: true,
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
        bottomNavigationBar: RepaintBoundary(
          child: _FloatingNavBar(
            selectedIndex: index,
            destinations: _destinations,
            raisedIndex: _raisedIndex,
            onSelect: shellCtrl.switchTab,
          ),
        ),
      );
    });
  }
}

/// Floating pill nav bar with a raised circular button for [raisedIndex].
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.destinations,
    required this.raisedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final List<_NavDestination> destinations;
  final int raisedIndex;
  final ValueChanged<int> onSelect;

  static const _barHeight = 64.0;
  static const _raisedSize = 60.0;
  // How far up from the true screen bottom the graduated blur reaches —
  // taller than the pill itself so the ramp has room to fade to nothing
  // before it would otherwise end in a hard edge.
  static const _blurHeight = 90.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Frosted-glass pill — translucent so the blurred content shows through,
    // like iOS's tab bar material.
    final barColor = (isDark ? AppColors.cardDark : Colors.white).withValues(
      alpha: 0.88,
    );

    return SizedBox(
      height: _blurHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Smooth gradient scrim behind the bar — fades content gracefully
          // before the pill with zero GPU blur passes for high-frame-rate scrolling.
          Positioned.fill(
            child: _EdgeScrim(
              height: _blurHeight,
              scrimColor: (isDark ? Colors.black : Colors.white).withValues(
                alpha: isDark ? 0.75 : 0.65,
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: SizedBox(
                height: _barHeight + _raisedSize / 2,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // ── Pill bar ──
                    Container(
                      height: _barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(_barHeight / 2),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black).withValues(
                            alpha: 0.06,
                          ),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.4 : 0.08,
                            ),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(_barHeight / 2),
                        child: Row(
                          children: List.generate(destinations.length, (i) {
                            if (i == raisedIndex) {
                              // Reserve the slot; the actual button is the
                              // Positioned circle drawn on top of the pill.
                              return const Expanded(child: SizedBox.shrink());
                            }
                            return Expanded(
                              child: _NavItem(
                                destination: destinations[i],
                                selected: selectedIndex == i,
                                showLowStockBadge: i == 1,
                                onTap: () => onSelect(i),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),

                    // ── Raised middle button ──
                    Positioned(
                      bottom: _barHeight - _raisedSize / 2,
                      child: _RaisedNavItem(
                        destination: destinations[raisedIndex],
                        selected: selectedIndex == raisedIndex,
                        ringColor: barColor,
                        onTap: () => onSelect(raisedIndex),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Smooth gradient scrim behind the floating bar.
/// Strongest at the bottom edge and ramps smoothly to zero above the bar,
/// with zero backdrop blur passes to maintain 60/120fps scrolling.
class _EdgeScrim extends StatelessWidget {
  const _EdgeScrim({
    required this.height,
    this.scrimColor,
  });

  final double height;
  final Color? scrimColor;

  @override
  Widget build(BuildContext context) {
    if (scrimColor == null) return const SizedBox.shrink();
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                scrimColor!,
                scrimColor!.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain icon nav item — icon + small active dot, no label.
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.showLowStockBadge = false,
  });

  final _NavDestination destination;
  final bool selected;
  final bool showLowStockBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.seed : AppColors.textTertiary;
    final icon = Icon(
      selected ? destination.activeIcon : destination.icon,
      color: color,
      size: 24,
    );

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          showLowStockBadge ? _LowStockBadge(child: icon) : icon,
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: AppDuration.fast,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: selected ? AppColors.seed : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// The raised circular nav item — bigger, filled, floats above the pill.
class _RaisedNavItem extends StatelessWidget {
  const _RaisedNavItem({
    required this.destination,
    required this.selected,
    required this.ringColor,
    required this.onTap,
  });

  final _NavDestination destination;
  final bool selected;
  final Color ringColor;
  final VoidCallback onTap;

  static const _size = 60.0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: AppColors.seed,
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.seed.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              selected ? destination.activeIcon : destination.icon,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: AppDuration.fast,
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: selected ? AppColors.seed : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Low-stock count badge, overlaid on the Products nav icon.
class _LowStockBadge extends StatelessWidget {
  const _LowStockBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    try {
      final ctrl = Get.find<ProductsController>();
      final settings = SettingsService.getSettings();
      return Obx(() {
        final count = ctrl.products
            .where((p) => p.stock <= settings.lowStockThreshold)
            .length;
        if (count == 0) return child;
        return Badge(label: Text('$count'), isLabelVisible: true, child: child);
      });
    } catch (_) {
      return child;
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
