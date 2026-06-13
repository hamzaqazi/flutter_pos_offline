import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'reports_controller.dart';

class ReportsPage extends GetView<ReportsController> {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Column(
        children: [
          // ---------- Date range filter ----------
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date range", style: theme.textTheme.titleSmall),
                const SizedBox(height: AppSpacing.sm),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _dateChip("Today", controller.setToday),
                      _dateChip("This week", controller.setThisWeek),
                      _dateChip("This month", controller.setThisMonth),
                      _dateChip("Last month", controller.setLastMonth),
                      _dateChip("All time", controller.setAllTime),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ---------- Report tabs ----------
          Expanded(
            child: DefaultTabController(
              length: 4,
              child: Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    tabs: const [
                      Tab(text: "Summary"),
                      Tab(text: "Top Products"),
                      Tab(text: "Categories"),
                      Tab(text: "Inventory"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _SummaryTab(),
                        _TopProductsTab(),
                        _CategoriesTab(),
                        _InventoryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ActionChip(label: Text(label), onPressed: onTap),
    );
  }
}

// =================== Summary Tab ===================

class _SummaryTab extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue & Profit banner
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.seed,
                    AppColors.seed.withValues(alpha: 0.75),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BannerStat(
                          label: "Revenue",
                          value: Formatters.currency(controller.totalRevenue),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Profit",
                          value: Formatters.currency(controller.totalProfit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _BannerStat(
                          label: "Margin",
                          value: "${controller.margin.toStringAsFixed(1)}%",
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Avg. Sale",
                          value: Formatters.currency(
                            controller.averageTransaction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.receipt_long_outlined,
                    label: "Transactions",
                    value: controller.totalTransactions.toString(),
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.shopping_bag_outlined,
                    label: "Items sold",
                    value: controller.totalItemsSold.toString(),
                    color: AppColors.seed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.discount_outlined,
                    label: "Discounts given",
                    value: Formatters.currency(controller.totalDiscount),
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Cost of goods",
                    value: Formatters.currency(controller.totalCOGS),
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =================== Top Products Tab ===================

class _TopProductsTab extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final products = controller.topProductsByRevenue;
      if (products.isEmpty) {
        return _EmptyReport(message: "No sales data for this period");
      }

      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (_, index) {
          final p = products[index];
          final accent = AppColors.forCategory(p.category);
          final rank = index + 1;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: rank <= 3
                          ? AppColors.warning.withValues(alpha: 0.15)
                          : cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: rank <= 3
                          ? Icon(
                              Icons.emoji_events_outlined,
                              size: 18,
                              color: AppColors.warning,
                            )
                          : Text(
                              "$rank",
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
                              ),
                              child: Text(
                                p.category,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              "${p.quantity} sold",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Revenue & Profit
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        Formatters.currency(p.revenue),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (p.profit > 0)
                        Text(
                          "+${Formatters.currency(p.profit)}",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// =================== Categories Tab ===================

class _CategoriesTab extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final categories = controller.categoryBreakdownList;
      if (categories.isEmpty) {
        return _EmptyReport(message: "No sales data for this period");
      }

      final maxRevenue = categories.first.revenue;

      return ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (_, index) {
          final cat = categories[index];
          final accent = AppColors.forCategory(cat.category);
          final pct = maxRevenue > 0 ? cat.revenue / maxRevenue : 0.0;

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            cat.category,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.currency(cat.revenue),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${cat.quantity} items sold",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        "Profit: ${Formatters.currency(cat.profit)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}

// =================== Inventory Tab ===================

class _InventoryTab extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Inventory valuation cards
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.inventory_2_outlined,
                    label: "Total units",
                    value: controller.totalStockUnits.toString(),
                    color: AppColors.seed,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.sell_outlined,
                    label: "Retail value",
                    value: Formatters.currency(controller.inventoryRetailValue),
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.payments_outlined,
                    label: "Cost value",
                    value: Formatters.currency(controller.inventoryCostValue),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.trending_up_outlined,
                    label: "Potential profit",
                    value: Formatters.currency(
                      controller.inventoryPotentialProfit,
                    ),
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),

            // Out of stock
            if (controller.outOfStockProducts.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(
                    Icons.cancel_outlined,
                    color: AppColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    "Out of Stock (${controller.outOfStockProducts.length})",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...controller.outOfStockProducts.map(
                (p) => _InventoryTile(product: p, theme: theme, cs: cs),
              ),
            ],

            // Low stock
            if (controller.lowStockProducts
                .where((p) => p.stock > 0)
                .isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    "Low Stock (${controller.lowStockProducts.where((p) => p.stock > 0).length})",
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ...controller.lowStockProducts
                  .where((p) => p.stock > 0)
                  .map((p) => _InventoryTile(product: p, theme: theme, cs: cs)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final ProductModel product;
  final ThemeData theme;
  final ColorScheme cs;

  const _InventoryTile({
    required this.product,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.forCategory(product.category);
    final isOut = product.stock <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Center(
                child: Text(
                  "${product.stock}",
                  style: TextStyle(
                    color: isOut ? AppColors.danger : accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (product.hasBrand)
                    Text(
                      product.brand,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              Formatters.currency(product.purchasePrice * product.stock),
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== Shared Widgets ===================

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: AppSpacing.sm),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  final String message;
  const _EmptyReport({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
