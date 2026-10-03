import 'dart:io';

import 'package:ad_shop_pos/app/shell/app_shell_app_bar.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/app/widgets/premium_license_banner.dart';
import 'package:ad_shop_pos/app/widgets/tooltip_label.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/data/services/auto_backup_service.dart';
import 'package:ad_shop_pos/data/services/google_drive_service.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends GetView<DashboardController> {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppShellAppBar(
        title: Text('Dashboard'),
        helpTopicId: 'getting-started',
        actions: const [_AutoBackupAppBarAction()],
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.refreshData,
          color: cs.primary,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    // Obx: license banners must refresh right after the user
                    // activates a license (trial → paid) without a restart.
                    Obx(() {
                      LicenseService.revision.value;
                      return _buildBanners(context);
                    }),

                    const SizedBox(height: AppSpacing.xxl),
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
      ),
    );
  }

  // ── Banners ──
  Widget _buildBanners(BuildContext context) {
    final banners = <Widget>[];

    void openLicense() {
      Get.toNamed('/license');
    }

    Widget banner({
      required String status,
      required String title,
      required String subtitle,
      required IconData icon,
      required Color accent,
      bool showUpgrade = false,
    }) {
      return PremiumLicenseBanner(
        status: status,
        title: title,
        subtitle: subtitle,
        icon: icon,
        accent: accent,
        onTap: openLicense,
        actionLabel: showUpgrade ? 'Enter Key' : null,
        onAction: showUpgrade ? () => _showUpgradeSheet(context) : null,
      );
    }

    if (LicenseService.isTrialActive) {
      final days = LicenseService.trialDaysRemaining;
      final isUrgent = days <= 3;

      banners.add(
        banner(
          status: isUrgent ? 'ENDING SOON' : 'PREMIUM TRIAL',
          title: isUrgent
              ? 'Trial ends in $days day${days == 1 ? '' : 's'}'
              : '$days days of Premium left',
          subtitle: 'Upgrade to keep all your Premium features.',
          icon: isUrgent ? Icons.timer_outlined : Icons.auto_awesome_outlined,
          accent: isUrgent ? const Color(0xFFD97706) : const Color(0xFF7C3AED),
          showUpgrade: true,
        ),
      );
    }

    if (LicenseService.isFreeTier) {
      banners.add(
        banner(
          status: 'FREE PLAN',
          title: 'Unlock your full potential',
          subtitle: 'Get Returns, Reports, and more with Premium.',
          icon: Icons.workspace_premium_outlined,
          accent: const Color(0xFF7C3AED),
          showUpgrade: true,
        ),
      );
    }

    if (LicenseService.isActivated) {
      final days = LicenseService.daysUntilExpiry;
      final expiresAt = LicenseService.expiresAt;

      if (days == null && LicenseService.storedPlan == 'lifetime') {
        banners.add(
          banner(
            status: 'LIFETIME ACCESS',
            title: 'Premium. Yours forever.',
            subtitle: LicenseService.shopName ?? '',
            icon: Icons.workspace_premium_rounded,
            accent: const Color(0xFF059669),
          ),
        );
      } else if (days != null && expiresAt != null) {
        final isCritical = days <= 7;
        final isWarning = days <= 30;

        banners.add(
          banner(
            status: isCritical
                ? 'EXPIRING SOON'
                : isWarning
                ? 'RENEWAL REMINDER'
                : 'PREMIUM ACTIVE',
            title: isWarning
                ? 'License expires in $days day${days == 1 ? '' : 's'}'
                : 'You’re all set',
            subtitle: 'Expires: ${formatDate(expiresAt)}',
            icon: isWarning ? Icons.vpn_key_outlined : Icons.verified_outlined,
            accent: isCritical
                ? const Color(0xFFDC2626)
                : isWarning
                ? const Color(0xFFD97706)
                : const Color(0xFF059669),
          ),
        );
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < banners.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          banners[i],
        ],
      ],
    );
  }

  // Widget _buildBanners(BuildContext context) {
  //   return GestureDetector(
  //     onTap: () => Get.toNamed("/license"),
  //     child: Column(
  //       children: [
  //         // Trial banner
  //         if (LicenseService.isTrialActive)
  //           Builder(
  //             builder: (context) {
  //               final days = LicenseService.trialDaysRemaining;
  //               final isUrgent = days <= 3;
  //               return AppBanner(
  //                 type: isUrgent ? AppBannerType.warning : AppBannerType.trial,
  //                 icon: isUrgent
  //                     ? Icons.timer_outlined
  //                     : Icons.celebration_outlined,
  //                 title: isUrgent
  //                     ? 'Trial expires in $days day${days == 1 ? '' : 's'}!'
  //                     : 'Free Trial — $days days remaining',
  //                 subtitle: 'Upgrade to keep all Premium features',
  //                 actionLabel: 'Enter Key',
  //                 onAction: () => _showUpgradeSheet(context),
  //               );
  //             },
  //           ),
  //         // Free tier banner
  //         if (LicenseService.isFreeTier)
  //           AppBanner.warning(
  //             title: 'Free Plan — Limited Features',
  //             subtitle: 'Upgrade to unlock Returns, Reports, and more',
  //             icon: Icons.workspace_premium_outlined,
  //             actionLabel: 'Enter Key',
  //             onAction: () => _showUpgradeSheet(context),
  //           ),
  //         // License info
  //         Builder(
  //           builder: (context) {
  //             if (!LicenseService.isActivated) return const SizedBox.shrink();
  //             final days = LicenseService.daysUntilExpiry;
  //             final expiresAt = LicenseService.expiresAt;
  //             if (days == null && LicenseService.storedPlan == 'lifetime') {
  //               return AppBanner(
  //                 type: AppBannerType.success,
  //                 icon: Icons.workspace_premium,
  //                 title: 'Lifetime License — Active',
  //                 subtitle: LicenseService.shopName,
  //               );
  //             }
  //             if (days == null || expiresAt == null)
  //               return const SizedBox.shrink();
  //             final isCritical = days <= 7;
  //             final isWarning = days <= 30;
  //             if (isCritical) {
  //               return AppBanner.danger(
  //                 title: 'License expires in $days day${days == 1 ? '' : 's'}!',
  //                 subtitle: 'Expires: ${formatDate(expiresAt)}',
  //                 icon: Icons.vpn_key_outlined,
  //               );
  //             }
  //             if (isWarning) {
  //               return AppBanner.warning(
  //                 title: 'License expires in $days days',
  //                 subtitle: 'Expires: ${formatDate(expiresAt)}',
  //                 icon: Icons.vpn_key_outlined,
  //               );
  //             }
  //             return AppBanner.success(
  //               title: 'License active',
  //               subtitle: 'Expires: ${formatDate(expiresAt)}',
  //             );
  //           },
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ── Today's Summary ──

  Widget _buildTodaySummary(ThemeData theme, ColorScheme cs) {
    final sales = controller.todaySales.value;
    final revenue = controller.todayRevenue.value;
    final profit = controller.todayProfit.value;
    final expenses = controller.todayExpenses.value;

    if (sales == 0 && revenue == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
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
                tooltip: FinancialTooltips.todaySales,
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
                tooltip: FinancialTooltips.todayRevenue,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: AppStatCard(
                label: 'Profit',
                value: Formatters.currency(profit),
                icon: Icons.trending_up_outlined,
                color: AppColors.violet,
                tooltip: FinancialTooltips.todayProfit,
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
                  tooltip: FinancialTooltips.netProfit,
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
        label: 'Profit',
        value: Formatters.currency(controller.totalProfit.value),
        icon: Icons.trending_up_outlined,
        color: AppColors.violet,
        tooltip: FinancialTooltips.profit,
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
      children: cards,
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
      children: actions,
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
//  AUTO BACKUP SHORTCUT — app bar button + status sheet
// ═══════════════════════════════════════════════════════════════

/// Trailing app-bar button that only appears while auto backup is switched
/// on. Tapping it opens [_AutoBackupSheet] with the current status and a
/// "Back up now" action.
class _AutoBackupAppBarAction extends StatelessWidget {
  const _AutoBackupAppBarAction();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Rebuild when auto backup is toggled / a backup completes.
      AutoBackupService.revision.value;

      if (!AutoBackupService.isEnabled) return const SizedBox.shrink();

      return IconButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            builder: (_) => const _AutoBackupSheet(),
          );
        },
        icon: Badge(
          // alignment: Alignment.topCenter,
          backgroundColor: AppColors.warning.withValues(alpha: 0.8),
          label: Text(
            AutoBackupService.lastBackupAgo,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
          ),
          child: const Icon(Icons.cloud_sync_outlined, size: 28),
        ),
        tooltip: 'Auto backup is on',
      );
    });
  }
}

/// Status sheet: what auto backup is doing right now + a manual trigger.
class _AutoBackupSheet extends StatefulWidget {
  const _AutoBackupSheet();

  @override
  State<_AutoBackupSheet> createState() => _AutoBackupSheetState();
}

class _AutoBackupSheetState extends State<_AutoBackupSheet> {
  bool _busy = false;

  Future<void> _backupNow() async {
    setState(() => _busy = true);
    final success = await AutoBackupService.backupNow();
    if (!mounted) return;
    setState(() => _busy = false);

    Get.snackbar(
      success ? 'Backup complete' : 'Backup failed',
      success
          ? 'Saved to this device'
          : 'Could not create the backup. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (success ? AppColors.success : AppColors.danger)
          .withValues(alpha: 0.15),
      colorText: success ? AppColors.success : AppColors.danger,
    );
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
      child: Obx(() {
        // Keeps the sheet in sync while it is open.
        AutoBackupService.revision.value;

        final frequency = switch (AutoBackupService.frequency) {
          'weekly' => 'Every week',
          'manual' => 'Manual only',
          _ => 'Every day',
        };
        final driveOn =
            GoogleDriveService.isEnabled && GoogleDriveService.isSignedIn;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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

            Icon(Icons.backup_outlined, size: 40, color: cs.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Auto backup is on',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AutoBackupService.frequency == 'manual'
                  ? 'Scheduling is set to manual — run a backup whenever you like.'
                  : 'Your data is being saved automatically. '
                        'You can also run a backup right now.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Status rows
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Column(
                children: [
                  _BackupInfoRow(
                    icon: Icons.schedule_outlined,
                    label: 'Schedule',
                    value: frequency,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BackupInfoRow(
                    icon: Icons.history_toggle_off_outlined,
                    label: 'Last backup',
                    value: AutoBackupService.lastBackupAgo,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BackupInfoRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Backups kept',
                    value: '${AutoBackupService.keepLast} latest',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _BackupInfoRow(
                    icon: Icons.cloud_outlined,
                    label: 'Google Drive',
                    value: driveOn ? 'Also uploading' : 'Off',
                    valueColor: driveOn ? AppColors.success : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary action
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _busy ? null : _backupNow,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.backup_outlined, size: 20),
                label: Text(_busy ? 'Backing up…' : 'Back up now'),
                style: FilledButton.styleFrom(backgroundColor: cs.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                ShellController.to.goSettings();
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text('Manage backup settings'),
            ),
          ],
        );
      }),
    );
  }
}

/// Label/value row used by [_AutoBackupSheet].
class _BackupInfoRow extends StatelessWidget {
  const _BackupInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 18, color: cs.onSurfaceVariant),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? cs.onSurface,
          ),
        ),
      ],
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
                  if (logoPath.isNotEmpty && !kIsWeb) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                      child: Image.file(
                        File(logoPath),
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
                  return Image.asset(
                    'lib/assets/images/cn_pos_logo_rm.png',
                    height: 38,
                    width: 38,
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
                    // styled it with googlefonts
                    style: GoogleFonts.slackey(
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // ── Greeting ──
          Text(
            "Welcome back 👋",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Here's your store at a glance",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
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
    return Card(
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
