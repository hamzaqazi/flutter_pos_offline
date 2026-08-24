import 'package:ad_shop_pos/app/shell/app_shell_app_bar.dart';
import 'package:ad_shop_pos/app/utils/native_file.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: const AppShellAppBar(title: Text('Dashboard')),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // ── Clean header ──
            SliverToBoxAdapter(child: _Header(cs: cs)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.navClearance,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Banners ──
                  _buildBanners(context),

                  // ── Today's Summary ──
                  AppSectionHeader(
                    title: "Today's Summary",
                    subtitle: 'Your sales performance for today',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() => _buildTodaySummary(theme, cs)),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── All-Time Overview ──
                  AppSectionHeader(
                    title: 'All-Time Overview',
                    subtitle: 'Total business performance since you started',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Obx(() => _buildAllTimeGrid(theme, cs)),
                  const SizedBox(height: AppSpacing.md),

                  // ── Quick Actions ──
                  AppSectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickActions(theme, cs),
                  const SizedBox(height: AppSpacing.md),

                  // ── Notifications ──
                  AppSectionHeader(title: 'Notifications'),
                  const SizedBox(height: AppSpacing.md),
                  _buildNotifications(theme, cs),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Banners ──

  Widget _buildBanners(BuildContext context) {
    return Column(
      children: [
        // Trial banner
        if (LicenseService.isTrialActive)
          Builder(
            builder: (context) {
              final days = LicenseService.trialDaysRemaining;
              final isUrgent = days <= 3;
              return AppBanner(
                type: isUrgent ? AppBannerType.warning : AppBannerType.trial,
                icon: isUrgent
                    ? Icons.timer_outlined
                    : Icons.celebration_outlined,
                title: isUrgent
                    ? 'Trial expires in $days day${days == 1 ? '' : 's'}!'
                    : 'Free Trial — $days days remaining',
                subtitle: 'Upgrade to keep all Premium features',
                actionLabel: 'Enter Key',
                onAction: () => _showUpgradeSheet(context),
              );
            },
          ),
        // Free tier banner
        if (LicenseService.isFreeTier)
          AppBanner.warning(
            title: 'Free Plan — Limited Features',
            subtitle: 'Upgrade to unlock Returns, Reports, and more',
            icon: Icons.workspace_premium_outlined,
            actionLabel: 'Enter Key',
            onAction: () => _showUpgradeSheet(context),
          ),
        // License info
        Builder(
          builder: (context) {
            if (!LicenseService.isActivated) return const SizedBox.shrink();
            final days = LicenseService.daysUntilExpiry;
            final expiresAt = LicenseService.expiresAt;
            if (days == null && LicenseService.storedPlan == 'lifetime') {
              return AppBanner(
                type: AppBannerType.success,
                icon: Icons.workspace_premium,
                title: 'Lifetime License — Active',
                subtitle: LicenseService.shopName,
              );
            }
            if (days == null || expiresAt == null)
              return const SizedBox.shrink();
            final isCritical = days <= 7;
            final isWarning = days <= 30;
            if (isCritical) {
              return AppBanner.danger(
                title: 'License expires in $days day${days == 1 ? '' : 's'}!',
                subtitle: 'Expires: ${formatDate(expiresAt)}',
                icon: Icons.vpn_key_outlined,
              );
            }
            if (isWarning) {
              return AppBanner.warning(
                title: 'License expires in $days days',
                subtitle: 'Expires: ${formatDate(expiresAt)}',
                icon: Icons.vpn_key_outlined,
              );
            }
            return AppBanner.success(
              title: 'License active',
              subtitle: 'Expires: ${formatDate(expiresAt)}',
            );
          },
        ),
      ],
    );
  }

  // ── Today's Summary ──

  Widget _buildTodaySummary(ThemeData theme, ColorScheme cs) {
    final sales = controller.todaySales.value;
    final revenue = controller.todayRevenue.value;
    final profit = controller.todayProfit.value;
    final expenses = controller.todayExpenses.value;

    if (sales == 0 && revenue == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            children: [
              Icon(
                Icons.coffee_outlined,
                size: 40,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No sales yet today',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Start a sale from the POS tab',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Primary row: Sales, Revenue, Profit
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Sales',
                value: sales.toString(),
                icon: Icons.receipt_long_outlined,
                color: AppColors.seed,
                onTap: () => ShellController.to.goSales(),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppStatCard(
                label: 'Revenue',
                value: Formatters.currency(revenue),
                icon: Icons.payments_outlined,
                color: AppColors.success,
                tooltip: expenses > 0
                    ? 'Revenue includes expenses of ${Formatters.currency(expenses)}'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Gross Profit',
                value: Formatters.currency(profit),
                icon: Icons.trending_up_outlined,
                color: AppColors.violet,
              ),
            ),
            if (expenses > 0) ...[
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppStatCard(
                  label: 'Net Profit',
                  value: Formatters.currency(profit - expenses),
                  icon: Icons.account_balance_wallet_outlined,
                  color: (profit - expenses) >= 0
                      ? AppColors.success
                      : AppColors.danger,
                  trend: expenses > 0
                      ? 'Exp: ${Formatters.currency(expenses)}'
                      : null,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── All-Time Overview ──

  Widget _buildAllTimeGrid(ThemeData theme, ColorScheme cs) {
    final cards = [
      AppStatCard(
        label: 'Products',
        value: controller.totalProducts.value.toString(),
        icon: Icons.inventory_2_outlined,
        color: AppColors.seed,
        onTap: () => ShellController.to.goProducts(),
      ),
      AppStatCard(
        label: 'Sales',
        value: controller.totalSales.value.toString(),
        icon: Icons.receipt_long_outlined,
        color: AppColors.accent,
        onTap: () => ShellController.to.goSales(),
      ),
      AppStatCard(
        label: 'Revenue',
        value: Formatters.currency(controller.totalRevenue.value),
        icon: Icons.payments_outlined,
        color: AppColors.success,
      ),
      AppStatCard(
        label: 'Gross Profit',
        value: Formatters.currency(controller.totalProfit.value),
        icon: Icons.trending_up_outlined,
        color: AppColors.violet,
      ),
      AppStatCard(
        label: 'Low Stock',
        value: controller.lowStockCount.value.toString(),
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
        onTap: () => Get.toNamed('/low-stock'),
      ),
      AppStatCard(
        label: 'Margin',
        value: controller.totalRevenue.value > 0
            ? '${(controller.totalProfit.value / controller.totalRevenue.value * 100).toStringAsFixed(1)}%'
            : '0%',
        icon: Icons.pie_chart_outline,
        color: AppColors.rose,
      ),
      AppStatCard(
        label: 'Refunds',
        value: Formatters.currency(controller.totalRefunds.value),
        icon: Icons.assignment_return_outlined,
        color: AppColors.warning,
        onTap: () => Get.toNamed('/returns'),
      ),
      AppStatCard(
        label: 'Returns',
        value: controller.totalReturnCount.value.toString(),
        icon: Icons.undo_outlined,
        color: AppColors.violet,
        onTap: () => Get.toNamed('/returns'),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: AppAnimations.staggerList(children: cards),
    );
  }

  // ── Quick Actions ──

  Widget _buildQuickActions(ThemeData theme, ColorScheme cs) {
    final actions = [
      _QuickActionChip(
        icon: Icons.point_of_sale_rounded,
        label: 'POS',
        color: AppColors.seed,
        onTap: () => ShellController.to.goCart(),
      ),
      _QuickActionChip(
        icon: Icons.qr_code_scanner,
        label: 'Scan',
        color: AppColors.accent,
        onTap: () => BarcodeScannerHelper.scanAndLookup(
          onScanned: (code) => BarcodeScannerHelper.addSkuToCart(code),
        ),
      ),
      _QuickActionChip(
        icon: Icons.inventory_2_outlined,
        label: 'Products',
        color: AppColors.seed,
        onTap: () => ShellController.to.goProducts(),
      ),
      _QuickActionChip(
        icon: Icons.receipt_long_outlined,
        label: 'Sales',
        color: AppColors.success,
        onTap: () => ShellController.to.goSales(),
      ),
      _QuickActionChip(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        color: AppColors.violet,
        onTap: () => Get.toNamed('/reports'),
      ),
      _QuickActionChip(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Expenses',
        color: AppColors.danger,
        onTap: () => Get.toNamed('/expenses'),
      ),
      _QuickActionChip(
        icon: Icons.assignment_return_outlined,
        label: 'Returns',
        color: AppColors.warning,
        onTap: () => Get.toNamed('/returns'),
      ),
      _QuickActionChip(
        icon: Icons.people_outline,
        label: 'Customers',
        color: AppColors.seed,
        onTap: () => Get.toNamed('/customers'),
      ),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.8,
      children: AppAnimations.staggerList(
        children: actions,
        staggerDuration: const Duration(milliseconds: 40),
      ),
    );
  }

  // ── Notifications ──

  Widget _buildNotifications(ThemeData theme, ColorScheme cs) {
    return Obx(() {
      final productsCtrl = Get.find<ProductsController>();
      final settings = SettingsService.getSettings();
      final lowStock = productsCtrl.products
          .where((p) => p.stock <= settings.lowStockThreshold)
          .toList();
      final outOfStock = lowStock.where((p) => p.stock <= 0).length;
      final low = lowStock.where((p) => p.stock > 0).length;

      if (lowStock.isEmpty) {
        return AppBanner.success(
          title: 'All products are well-stocked',
          icon: Icons.check_circle_outline_rounded,
        );
      }

      return Column(
        children: [
          if (outOfStock > 0)
            AppBanner.danger(
              title: '$outOfStock out of stock',
              subtitle: 'Products need restocking immediately',
              icon: Icons.cancel_outlined,
              actionLabel: 'View',
              onAction: () => Get.toNamed('/low-stock'),
            ),
          if (low > 0)
            AppBanner.warning(
              title: '$low low stock',
              subtitle:
                  'Products running low (≤${settings.lowStockThreshold} units)',
              icon: Icons.warning_amber_rounded,
              actionLabel: 'View',
              onAction: () => Get.toNamed('/low-stock'),
            ),
        ],
      );
    });
  }

  void _showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _TrialUpgradeSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  HEADER — Clean, no gradient
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: logo + shop name + actions ──
          Row(
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Obx(() {
                  final settings = Get.find<SettingsController>();
                  final logoPath = settings.receiptSettings.value.logoPath;
                  if (logoPath.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Image(
                        image: createFileImage(logoPath),
                        height: 28,
                        width: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.storefront_rounded,
                          size: 28,
                          color: cs.primary,
                        ),
                      ),
                    );
                  }
                  return Icon(
                    Icons.storefront_rounded,
                    size: 28,
                    color: cs.primary,
                  );
                }),
              ),
              const SizedBox(width: AppSpacing.md),
              // Shop name
              Expanded(
                child: Obx(() {
                  final settings = Get.find<SettingsController>();
                  return Text(
                    settings.shopName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Greeting ──
          AppAnimations.slideUp(
            child: Text(
              "Welcome back 👋",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          AppAnimations.slideUp(
            delay: const Duration(milliseconds: 80),
            child: Text(
              "Here's your store at a glance",
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  QUICK ACTION CHIP — Compact action button for the grid
// ═══════════════════════════════════════════════════════════════

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TapScale(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  UPGRADE SHEET — Quick license key entry
// ═══════════════════════════════════════════════════════════════

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
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Activate License',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
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

// ═══════════════════════════════════════════════════════════════
//  UTILITY
// ═══════════════════════════════════════════════════════════════

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
