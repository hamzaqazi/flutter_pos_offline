import 'dart:io';

import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/tooltip_label.dart';
import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/app/widgets/premium_gate.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ---------- Gradient header ----------
            SliverToBoxAdapter(child: _Header(cs: cs)),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ---------- Today's Summary ----------
                  // ---------- Trial Banner ----------
                  if (LicenseService.isTrialActive)
                    Builder(
                      builder: (context) {
                        final days = LicenseService.trialDaysRemaining;
                        final isUrgent = days <= 3;
                        final color = isUrgent ? AppColors.warning : AppColors.seed;
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: color.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isUrgent
                                    ? Icons.timer_outlined
                                    : Icons.celebration_outlined,
                                color: color,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isUrgent
                                          ? 'Trial expires in $days day${days == 1 ? '' : 's'}!'
                                          : 'Free Trial — $days days remaining',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: color,
                                      ),
                                    ),
                                    Text(
                                      'Upgrade to keep all Premium features',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Enter Key button
                              SizedBox(
                                width: 96,
                                height: 32,
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => _TrialUpgradeSheet(),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  ),
                                  child: const Text('Enter Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // ---------- Free Tier Banner ----------
                  if (LicenseService.isFreeTier)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: AppColors.warning,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Free Plan — Limited Features',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.warning,
                                  ),
                                ),
                                Text(
                                  'Upgrade to unlock Returns, Reports, and more',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Enter Key button
                          SizedBox(
                            width: 96,
                            height: 32,
                            child: FilledButton.tonal(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => _TrialUpgradeSheet(),
                                );
                              },
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                              ),
                              child: const Text('Enter Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ---------- License Info Banner ----------
                  Builder(
                    builder: (context) {
                      if (!LicenseService.isActivated)
                        return const SizedBox.shrink();
                      // Lifetime plans have no expiry — show plan info instead
                      final days = LicenseService.daysUntilExpiry;
                      final expiresAt = LicenseService.expiresAt;
                      if (days == null && LicenseService.storedPlan == 'lifetime') {
                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.seed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.seed.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.workspace_premium,
                                color: AppColors.seed,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lifetime License — Active',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.seed,
                                      ),
                                    ),
                                    Text(
                                      LicenseService.shopName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Enter Key button
                              SizedBox(
                                width: 96,
                                height: 32,
                                child: FilledButton.tonal(
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(20),
                                        ),
                                      ),
                                      builder: (_) => _TrialUpgradeSheet(),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                  ),
                                  child: const Text('Enter Key', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      if (days == null || expiresAt == null)
                        return const SizedBox.shrink();

                      final isWarning = days <= 30;
                      final isCritical = days <= 7;
                      final color = isCritical
                          ? AppColors.danger
                          : isWarning
                          ? AppColors.warning
                          : AppColors.success;

                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              color: color,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCritical
                                        ? 'License expires in $days day${days == 1 ? '' : 's'}!'
                                        : isWarning
                                        ? 'License expires in $days days'
                                        : 'License active',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    // format date 4 january 2027
                                    'Expires: ${formatDate(expiresAt)}',
                                    // 'Expires: ${expiresAt.day}/${expiresAt.month}/${expiresAt.year}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  TooltipLabel(
                    label: "Today's Summary",
                    tooltip: 'Your sales performance for today',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Obx(
                    () => Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.success,
                            AppColors.success.withValues(alpha: 0.75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _TodayStat(
                                  icon: Icons.receipt_long_outlined,
                                  label: "Sales",
                                  value: controller.todaySales.value.toString(),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              Expanded(
                                child: _TodayStat(
                                  icon: Icons.payments_outlined,
                                  label: "Revenue",
                                  value: Formatters.currency(
                                    controller.todayRevenue.value,
                                  ),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24,
                              ),
                              Expanded(
                                child: _TodayStat(
                                  icon: Icons.trending_up_outlined,
                                  label: "Gross Profit",
                                  value: Formatters.currency(
                                    controller.todayProfit.value,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (controller.todayExpenses.value > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Divider(color: Colors.white24, height: 1),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: _TodayStatSmall(
                                    label: "Expenses",
                                    value: Formatters.currency(
                                      controller.todayExpenses.value,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.white24,
                                ),
                                Expanded(
                                  child: _TodayStatSmall(
                                    label: "Net Profit",
                                    value: Formatters.currency(
                                      controller.todayProfit.value -
                                          controller.todayExpenses.value,
                                    ),
                                    valueColor:
                                        (controller.todayProfit.value -
                                                controller
                                                    .todayExpenses
                                                    .value) >=
                                            0
                                        ? Colors.white
                                        : const Color(0xFFFFA726),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  TooltipLabel(
                    label: "All-Time Overview",
                    tooltip:
                        'Your total business performance since you started using the app',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ---------- Stat cards ----------
                  Obx(
                    () => GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.35,
                      children: [
                        _StatCard(
                          label: "Products",
                          value: controller.totalProducts.value.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.seed,
                          onTap: () => Get.toNamed('/products'),
                        ),
                        _StatCard(
                          label: "Sales",
                          value: controller.totalSales.value.toString(),
                          icon: Icons.receipt_long_outlined,
                          color: AppColors.accent,
                          onTap: () => Get.toNamed('/sales'),
                        ),
                        _StatCard(
                          label: "Revenue",
                          tooltip: FinancialTooltips.revenue,
                          value: Formatters.currency(
                            controller.totalRevenue.value,
                          ),
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          label: "Gross Profit",
                          tooltip: FinancialTooltips.grossProfit,
                          value: Formatters.currency(
                            controller.totalProfit.value,
                          ),
                          icon: Icons.trending_up_outlined,
                          color: const Color(0xFF8B5CF6), // Violet
                        ),
                        _StatCard(
                          label: "Low stock",
                          tooltip: FinancialTooltips.lowStock,
                          value: controller.lowStockCount.value.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          onTap: () => Get.toNamed('/low-stock'),
                        ),
                        _StatCard(
                          label: "Margin",
                          value: controller.totalRevenue.value > 0
                              ? "${(controller.totalProfit.value / controller.totalRevenue.value * 100).toStringAsFixed(1)}%"
                              : "0%",
                          icon: Icons.pie_chart_outline,
                          color: const Color(0xFFEC4899), // Pink
                          tooltip: FinancialTooltips.netMargin,
                        ),
                        _StatCard(
                          label: "Refunds",
                          value: Formatters.currency(
                            controller.totalRefunds.value,
                          ),
                          icon: Icons.assignment_return_outlined,
                          color: AppColors.warning,
                          onTap: () => Get.toNamed('/returns'),
                        ),
                        _StatCard(
                          label: "Returns",
                          value: controller.totalReturnCount.value.toString(),
                          icon: Icons.undo_outlined,
                          color: const Color(0xFF8B5CF6),
                          onTap: () => Get.toNamed('/returns'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Text("Quick actions", style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),

                  _ActionTile(
                    icon: Icons.storefront_outlined,
                    title: "Browse products",
                    subtitle: "View catalog & add items to cart",
                    color: AppColors.seed,
                    onTap: () => Get.toNamed('/products'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.shopping_cart_outlined,
                    title: "Open cart",
                    subtitle: "Review items & checkout",
                    color: AppColors.accent,
                    onTap: () => Get.toNamed('/cart'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.qr_code_scanner,
                    title: "Scan barcode",
                    subtitle: "Scan product barcode to quickly add to cart",
                    color: AppColors.accent,
                    onTap: () => BarcodeScannerHelper.scanAndLookup(
                      onScanned: (code) =>
                          BarcodeScannerHelper.addSkuToCart(code),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.history,
                    title: "Sales history",
                    subtitle: "Past receipts & profit reports",
                    color: AppColors.success,
                    onTap: () => Get.toNamed('/sales'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.bar_chart_outlined,
                    title: "Reports",
                    subtitle: "Sales, products & inventory analytics",
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Get.toNamed('/reports'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Expenses",
                    subtitle: "Track rent, salaries, utilities & more",
                    color: AppColors.danger,
                    onTap: () => Get.toNamed('/expenses'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.settings_outlined,
                    title: "Settings",
                    subtitle: "Shop info, tax, receipt & currency settings",
                    color: cs.onSurfaceVariant,
                    onTap: () => Get.toNamed('/settings'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.assignment_return_outlined,
                    title: "Returns",
                    subtitle: "View refund history & processed returns",
                    color: AppColors.warning,
                    onTap: () => Get.toNamed('/returns'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.people_outline,
                    title: "Customers",
                    subtitle: "Manage customer directory & purchase history",
                    color: AppColors.seed,
                    onTap: () => Get.toNamed('/customers'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ActionTile(
                    icon: Icons.badge_outlined,
                    title: "Staff",
                    subtitle: "Manage cashiers & track staff performance",
                    color: AppColors.accent,
                    onTap: () => Get.toNamed('/staff'),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                  Text("Notifications", style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),

                  // Low stock notification
                  Obx(() {
                    final productsCtrl = Get.find<ProductsController>();
                    final settings = SettingsService.getSettings();
                    final lowStock = productsCtrl.products
                        .where((p) => p.stock <= settings.lowStockThreshold)
                        .toList();
                    final outOfStock = lowStock
                        .where((p) => p.stock <= 0)
                        .length;
                    final low = lowStock.where((p) => p.stock > 0).length;

                    if (lowStock.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  "All products are well-stocked",
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        if (outOfStock > 0)
                          _NotificationTile(
                            icon: Icons.cancel_outlined,
                            title: "$outOfStock out of stock",
                            subtitle: "Products need restocking immediately",
                            color: AppColors.danger,
                            onTap: () => Get.toNamed('/low-stock'),
                          ),
                        if (outOfStock > 0 && low > 0)
                          const SizedBox(height: AppSpacing.md),
                        if (low > 0)
                          _NotificationTile(
                            icon: Icons.warning_amber_rounded,
                            title: "$low low stock",
                            subtitle:
                                "Products running low (≤${settings.lowStockThreshold} units)",
                            color: AppColors.warning,
                            onTap: () => Get.toNamed('/low-stock'),
                          ),
                      ],
                    );
                  }),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String formatDate(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _Header extends StatelessWidget {
  const _Header({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.seed, AppColors.seed.withValues(alpha: 0.75)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.storefront,
                          size: 32,
                          color: Colors.white,
                        );
                      },
                    );
                  }
                  return Image.asset(
                    'lib/assets/images/cn_pos_logo_rm.png',
                    height: 32,
                  );
                }),
              ),
              const SizedBox(width: AppSpacing.md),
              Obx(() {
                final settings = Get.find<SettingsController>();
                return Text(
                  settings.shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                );
              }),
              const Spacer(),
              Obx(
                () => Row(
                  children: [
                    IconButton(
                      onPressed: themeController.toggle,
                      icon: Icon(
                        themeController.isDark.value
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                        color: Colors.white,
                      ),
                      tooltip: "Toggle theme",
                    ),
                    // settings button
                    IconButton(
                      onPressed: () => Get.toNamed('/settings'),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                      tooltip: "Settings",
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            "Welcome back 👋",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            "Here's your store at a glance",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Flexible(
                child: tooltip != null
                    ? TooltipLabel(
                        label: label,
                        tooltip: tooltip!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

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
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
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

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

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
                child: Icon(icon, color: color, size: 20),
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

class _TodayStat extends StatelessWidget {
  const _TodayStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _TodayStatSmall extends StatelessWidget {
  const _TodayStatSmall({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

/// Quick license key entry sheet for trial users.
class _TrialUpgradeSheet extends StatefulWidget {
  @override
  State<_TrialUpgradeSheet> createState() => _TrialUpgradeSheetState();
}

class _TrialUpgradeSheetState extends State<_TrialUpgradeSheet> {
  final _keyController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _loading = true);
    final result = await LicenseService.validateLicense(key);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.of(context).pop();
      Get.snackbar(
        'Activated! 🎉',
        'Your ${result.plan ?? 'premium'} plan is now active.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Activation Failed',
        result.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Icon(Icons.vpn_key_outlined, size: 40, color: cs.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Activate Your License',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Enter the license key you received from Codynest',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),

          TextField(
            controller: _keyController,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'CNPO-XXXX-XXXX-XXXX',
              prefixIcon: const Icon(Icons.vpn_key_outlined, size: 20),
              filled: true,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
            ),
            onSubmitted: (_) => _activate(),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _loading ? null : _activate,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Activate License', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Need a key? Contact: 0315-3507075',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
