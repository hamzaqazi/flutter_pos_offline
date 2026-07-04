import 'dart:io';

import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/app/utils/responsive.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tablet-optimized dashboard with multi-column layout.
class DashboardTabletPage extends GetView<DashboardController> {
  const DashboardTabletPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final resp = Responsive.of(context);

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            // ─── Left panel: header + license + quick actions ───
            SizedBox(
              width: resp.width >= 1200 ? 360 : 300,
              child: _LeftPanel(cs: cs, theme: theme, controller: controller),
            ),

            // ─── Vertical divider ───
            Container(width: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),

            // ─── Right panel: stats + overview cards ───
            Expanded(
              child: _RightPanel(theme: theme, cs: cs, resp: resp, controller: controller),
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// LEFT PANEL
// ────────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.cs, required this.theme, required this.controller});

  final ColorScheme cs;
  final ThemeData theme;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.seed,
            AppColors.seed.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo + shop name row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Obx(() {
                    final settings = Get.find<SettingsController>();
                    final logoPath = settings.receiptSettings.value.logoPath;
                    if (logoPath.isNotEmpty) {
                      return Image.file(
                        File(logoPath),
                        height: 36,
                        width: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.storefront, size: 36, color: Colors.white,
                        ),
                      );
                    }
                    return Image.asset(
                      'lib/assets/images/cn_pos_logo_rm.png',
                      height: 36,
                    );
                  }),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Obx(() {
                    final settings = Get.find<SettingsController>();
                    return Text(
                      settings.shopName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    );
                  }),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Welcome text
            const Text(
              "Welcome back 👋",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              "Here's your store at a glance",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ─── Today's Summary ───
            const Text(
              "Today's Summary",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _TodaySummaryCard(controller: controller),

            const SizedBox(height: AppSpacing.xl),

            // ─── License Info ───
            Builder(
              builder: (context) {
                if (!LicenseService.isActivated) return const SizedBox.shrink();
                final days = LicenseService.daysUntilExpiry;
                final expiresAt = LicenseService.expiresAt;
                if (days == null || expiresAt == null) return const SizedBox.shrink();

                final isCritical = days <= 7;
                final isWarning = days <= 30;
                final label = isCritical
                    ? '$days day${days == 1 ? '' : 's'} left!'
                    : isWarning
                        ? '$days days left'
                        : 'License active';

                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isCritical
                            ? Icons.warning_amber_rounded
                            : isWarning
                                ? Icons.info_outline
                                : Icons.verified_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Expires: ${formatDate(expiresAt)}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ─── Quick Actions ───
            const Text(
              "Quick Actions",
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            _QuickActionBtn(
              icon: Icons.point_of_sale_outlined,
              label: "New Sale",
              onTap: () => Get.toNamed('/cart'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuickActionBtn(
              icon: Icons.add_circle_outline,
              label: "Add Product",
              onTap: () => Get.toNamed('/products'),
            ),
            const SizedBox(height: AppSpacing.sm),
            _QuickActionBtn(
              icon: Icons.qr_code_scanner,
              label: "Scan Barcode",
              onTap: () => Get.toNamed('/scanner'),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Theme + settings buttons
            Row(
              children: [
                Obx(() => IconButton(
                  onPressed: themeController.toggle,
                  icon: Icon(
                    themeController.isDark.value
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white70,
                  ),
                  tooltip: "Toggle theme",
                )),
                IconButton(
                  onPressed: () => Get.toNamed('/settings'),
                  icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                  tooltip: "Settings",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// RIGHT PANEL
// ────────────────────────────────────────────────────────────

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.theme,
    required this.cs,
    required this.resp,
    required this.controller,
  });

  final ThemeData theme;
  final ColorScheme cs;
  final Responsive resp;
  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(resp.horizontalPadding.toDouble()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── All-Time Overview Cards ───
          Text("All-Time Overview", style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),

          _StatCardGrid(
            columns: resp.statGridColumns,
            children: [
              _ObxStatCard(
                label: "Products",
                valueGetter: () => controller.totalProducts.value.toString(),
                icon: Icons.inventory_2_outlined,
                color: AppColors.seed,
                onTap: () => Get.toNamed('/products'),
              ),
              _ObxStatCard(
                label: "Sales",
                valueGetter: () => controller.totalSales.value.toString(),
                icon: Icons.receipt_long_outlined,
                color: AppColors.accent,
                onTap: () => Get.toNamed('/sales'),
              ),
              _ObxStatCard(
                label: "Revenue",
                valueGetter: () => Formatters.currency(controller.totalRevenue.value),
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
              _ObxStatCard(
                label: "Profit",
                valueGetter: () => Formatters.currency(controller.totalProfit.value),
                icon: Icons.trending_up_outlined,
                color: const Color(0xFF8B5CF6),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xl),

          // ─── Notifications + Actions row ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notifications", style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _NotificationsList(controller: controller),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xl),

              // Quick Actions
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Quick Actions", style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.md),
                    _ActionGrid(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// TODAY'S SUMMARY CARD (for left panel)
// ────────────────────────────────────────────────────────────

class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({required this.controller});

  final DashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: [
          _TodayStatRow(
            icon: Icons.receipt_long_outlined,
            label: "Sales",
            value: controller.todaySales.value.toString(),
          ),
          Divider(color: Colors.white24, height: AppSpacing.lg),
          _TodayStatRow(
            icon: Icons.payments_outlined,
            label: "Revenue",
            value: Formatters.currency(controller.todayRevenue.value),
          ),
          Divider(color: Colors.white24, height: AppSpacing.lg),
          _TodayStatRow(
            icon: Icons.trending_up_outlined,
            label: "Profit",
            value: Formatters.currency(controller.todayProfit.value),
          ),
        ],
      ),
    ));
  }
}

class _TodayStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TodayStatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
// QUICK ACTION BUTTON (for left panel)
// ────────────────────────────────────────────────────────────

class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.md),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_right, color: Colors.white54, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// STAT CARD GRID
// ────────────────────────────────────────────────────────────

class _StatCardGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _StatCardGrid({
    required this.columns,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.6,
      children: children,
    );
  }
}

// ────────────────────────────────────────────────────────────
// STAT CARD (for right panel)
// ────────────────────────────────────────────────────────────

/// Stat card that wraps itself in Obx for reactive updates.
class _ObxStatCard extends StatelessWidget {
  const _ObxStatCard({
    required this.label,
    required this.valueGetter,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String Function() valueGetter;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Obx(() => _StatCard(
      label: label,
      value: valueGetter(),
      icon: icon,
      color: color,
      onTap: onTap,
    ));
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// NOTIFICATIONS LIST
// ────────────────────────────────────────────────────────────

class _NotificationsList extends StatelessWidget {
  final DashboardController controller;

  const _NotificationsList({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
    final theme = Theme.of(context);
    final threshold = SettingsService.getSettings().lowStockThreshold;
    final lowStock = controller.lowStockCount.value;
    final returns = controller.totalReturnCount.value;
    final refunds = controller.totalRefunds.value;

    if (lowStock == 0 && returns == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 40,
                  color: AppColors.success.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.sm),
              Text("All good! No alerts right now.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (lowStock > 0)
          _NotificationCard(
            icon: Icons.warning_amber_rounded,
            title: "Low Stock Alert",
            subtitle: "$lowStock product${lowStock == 1 ? '' : 's'} at or below $threshold units",
            color: AppColors.warning,
            onTap: () => Get.toNamed('/low-stock'),
          ),
        if (returns > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          _NotificationCard(
            icon: Icons.undo_outlined,
            title: "Returns",
            subtitle: "$returns return${returns == 1 ? '' : 's'} processed (${Formatters.currency(refunds)})",
            color: AppColors.danger,
            onTap: () => Get.toNamed('/returns'),
          ),
        ],
      ],
    );
    });  // close Obx
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// QUICK ACTIONS GRID (right panel)
// ────────────────────────────────────────────────────────────

class _ActionGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.2,
      children: [
        _ActionChip(
          icon: Icons.inventory_2_outlined,
          label: "Products",
          color: AppColors.seed,
          onTap: () => Get.toNamed('/products'),
        ),
        _ActionChip(
          icon: Icons.receipt_long_outlined,
          label: "Sales",
          color: AppColors.accent,
          onTap: () => Get.toNamed('/sales'),
        ),
        _ActionChip(
          icon: Icons.account_balance_wallet_outlined,
          label: "Expenses",
          color: AppColors.danger,
          onTap: () => Get.toNamed('/expenses'),
        ),
        _ActionChip(
          icon: Icons.people_outline,
          label: "Customers",
          color: const Color(0xFF8B5CF6),
          onTap: () => Get.toNamed('/customers'),
        ),
        _ActionChip(
          icon: Icons.bar_chart_outlined,
          label: "Reports",
          color: AppColors.seed,
          onTap: () => Get.toNamed('/reports'),
        ),
        _ActionChip(
          icon: Icons.people_outline,
          label: "Staff",
          color: AppColors.accent,
          onTap: () => Get.toNamed('/staff'),
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// SHARED: formatDate
// ────────────────────────────────────────────────────────────

String formatDate(DateTime date) {
  const months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  return '${date.day} ${months[date.month]} ${date.year}';
}
