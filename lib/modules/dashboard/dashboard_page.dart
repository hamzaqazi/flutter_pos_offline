import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
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
            SliverToBoxAdapter(
              child: _Header(cs: cs),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text("Overview", style: theme.textTheme.titleMedium),
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
                          value: Formatters.currency(
                            controller.totalRevenue.value,
                          ),
                          icon: Icons.payments_outlined,
                          color: AppColors.success,
                        ),
                        _StatCard(
                          label: "Profit",
                          value: Formatters.currency(
                            controller.totalProfit.value,
                          ),
                          icon: Icons.trending_up_outlined,
                          color: const Color(0xFF8B5CF6), // Violet
                        ),
                        _StatCard(
                          label: "Low stock",
                          value: controller.lowStockCount.value.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          onTap: () => Get.toNamed('/products'),
                        ),
                        _StatCard(
                          label: "Margin",
                          value: controller.totalRevenue.value > 0
                              ? "${(controller.totalProfit.value / controller.totalRevenue.value * 100).toStringAsFixed(1)}%"
                              : "0%",
                          icon: Icons.pie_chart_outline,
                          color: const Color(0xFFEC4899), // Pink
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
                    icon: Icons.history,
                    title: "Sales history",
                    subtitle: "Past receipts & profit reports",
                    color: AppColors.success,
                    onTap: () => Get.toNamed('/sales'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.point_of_sale, color: Colors.white),
              ),
              const SizedBox(width: AppSpacing.md),
              const Text(
                "Shop POS",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Obx(
                () => IconButton(
                  onPressed: themeController.toggle,
                  icon: Icon(
                    themeController.isDark.value
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: Colors.white,
                  ),
                  tooltip: "Toggle theme",
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
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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
