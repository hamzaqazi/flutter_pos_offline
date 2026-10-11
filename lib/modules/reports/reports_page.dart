import 'dart:typed_data';

import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/app/widgets/tooltip_label.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/data/services/shop_report_pdf_service.dart';
import 'package:ad_shop_pos/modules/reports/charts_tab.dart';
import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/widgets/premium_gate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import 'reports_controller.dart';

class ReportsPage extends GetView<ReportsController> {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: DefaultTextStyle.merge(
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            fontSize: 16,
          ),
          child: Text("Reports & Analytics"),
        ),
        actions: [
          Obx(() {
            LicenseService.revision.value;
            if (!LicenseService.isPremium) return const SizedBox.shrink();
            return IconButton(
              onPressed: () => _openReportSheet(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: 'Save, print or share a PDF report',
            );
          }),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        elevation: 20,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: PremiumGate(
        feature: 'Reports & Analytics',
        child: Column(
          children: [
            // ---------- Date range filter ----------
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Obx(() {
                final sel = controller.selectedRange.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date range", style: theme.textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.sm),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _rangeChip(
                            "Today",
                            selected: sel == ReportsRange.today,
                            onTap: controller.setToday,
                          ),
                          _rangeChip(
                            "This week",
                            selected: sel == ReportsRange.thisWeek,
                            onTap: controller.setThisWeek,
                          ),
                          _rangeChip(
                            "This month",
                            selected: sel == ReportsRange.thisMonth,
                            onTap: controller.setThisMonth,
                          ),
                          _rangeChip(
                            "Last month",
                            selected: sel == ReportsRange.lastMonth,
                            onTap: controller.setLastMonth,
                          ),
                          _rangeChip(
                            "All time",
                            selected: sel == ReportsRange.allTime,
                            onTap: controller.setAllTime,
                          ),
                          _rangeChip(
                            "Custom",
                            selected: sel == ReportsRange.custom,
                            onTap: () => _pickCustomRange(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Show the exact range in effect so it's obvious a filter
                    // is active (and which one), including the default window.
                    Row(
                      children: [
                        Icon(
                          Icons.date_range,
                          size: 14,
                          color: sel == null ? cs.onSurfaceVariant : cs.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _activeRangeLabel(sel),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: sel == null
                                  ? cs.onSurfaceVariant
                                  : cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
            const Divider(height: 1),

            // ---------- Report tabs ----------
            Expanded(
              child: DefaultTabController(
                length: 6,
                child: Column(
                  children: [
                    TabBar(
                      isScrollable: true,
                      labelColor: cs.primary,
                      unselectedLabelColor: cs.onSurfaceVariant,
                      indicatorColor: cs.primary,
                      tabs: const [
                        Tab(text: "Summary"),
                        Tab(text: "Charts"),
                        Tab(text: "Top Products"),
                        Tab(text: "Categories"),
                        Tab(text: "Expenses"),
                        Tab(text: "Inventory"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _SummaryTab(),
                          ChartsTab(),
                          _TopProductsTab(),
                          _CategoriesTab(),
                          _ExpensesTab(),
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
      ),
    );
  }

  /// A single-select date-range chip. The selected one is filled and shows a
  /// checkmark, so it's clear which filter is currently active.
  Widget _rangeChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  /// Text shown under the chips: the preset name + the exact dates in effect.
  String _activeRangeLabel(ReportsRange? sel) {
    final start = controller.startDate.value;
    final end = controller.endDate.value;
    final sameDay =
        start.year == end.year &&
        start.month == end.month &&
        start.day == end.day;
    final dates = sameDay
        ? Formatters.dateShort(start)
        : '${Formatters.dateShort(start)} – ${Formatters.dateShort(end)}';
    return '${_rangePrefix(sel)} · $dates';
  }

  String _rangePrefix(ReportsRange? sel) {
    switch (sel) {
      case ReportsRange.today:
        return 'Today';
      case ReportsRange.thisWeek:
        return 'This week';
      case ReportsRange.thisMonth:
        return 'This month';
      case ReportsRange.lastMonth:
        return 'Last month';
      case ReportsRange.allTime:
        return 'All time';
      case ReportsRange.custom:
        return 'Custom';
      case null:
        return 'Last 30 days';
    }
  }

  /// Open a date-range picker and apply the result as the custom filter.
  Future<void> _pickCustomRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: controller.startDate.value,
        end: controller.endDate.value,
      ),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      controller.setCustomRange(picked.start, picked.end);
    }
  }

  /// Opens the "save / print / share report" bottom sheet.
  Future<void> _openReportSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (_) => _ShopReportSheet(controller: controller),
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
                          tooltip: FinancialTooltips.revenue,
                          value: Formatters.currency(controller.totalRevenue),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Net Profit",
                          tooltip: FinancialTooltips.netProfit,
                          value: Formatters.currency(controller.netProfit),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _BannerStat(
                          label: "Net Margin",
                          tooltip: FinancialTooltips.netMargin,
                          // tooltip: FinancialTooltips.netMargin,
                          value: "${controller.netMargin.toStringAsFixed(1)}%",
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Avg. Sale",
                          tooltip: FinancialTooltips.avgSale,
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.receipt_outlined,
                    label: "Tax collected",
                    tooltip: FinancialTooltips.taxCollected,
                    value: Formatters.currency(controller.totalTax),
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.money_off_outlined,
                    label: "Expenses",
                    tooltip: FinancialTooltips.expenses,
                    value: Formatters.currency(controller.totalExpenses),
                    color: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    icon: Icons.assignment_return_outlined,
                    label: "Refunds",
                    tooltip: FinancialTooltips.refunds,
                    value: Formatters.currency(controller.totalRefunds),
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatBox(
                    icon: Icons.undo_outlined,
                    label: "Return transactions",
                    value: controller.totalReturnTransactions.toString(),
                    color: AppColors.violet,
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

// =================== Expenses Tab ===================

class _ExpensesTab extends GetView<ReportsController> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Obx(() {
      final breakdown = controller.expenseBreakdownList;
      final totalExp = controller.totalExpenses;
      final totalProf = controller.totalProfit;

      if (totalExp <= 0 && totalProf <= 0) {
        return _EmptyReport(message: "No expense data for this period");
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // P&L Summary
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    controller.netProfit >= 0
                        ? AppColors.success
                        : AppColors.danger,
                    (controller.netProfit >= 0
                            ? AppColors.success
                            : AppColors.danger)
                        .withValues(alpha: 0.75),
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
                          label: "Profit",
                          tooltip: FinancialTooltips.profit,
                          value: Formatters.currency(controller.totalProfit),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Expenses",
                          value: Formatters.currency(totalExp),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _BannerStat(
                          label: "Net Profit",
                          tooltip: FinancialTooltips.netProfit,
                          value: Formatters.currency(controller.netProfit),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Net Margin",
                          tooltip: FinancialTooltips.netMargin,
                          value: "${controller.netMargin.toStringAsFixed(1)}%",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Expense breakdown by category
            if (breakdown.isNotEmpty) ...[
              Text(
                "Expenses by Category",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...breakdown.map((cat) {
                final pct = totalExp > 0 ? cat.amount / totalExp : 0.0;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cat.category,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              Formatters.currency(cat.amount),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.danger.withValues(
                              alpha: 0.12,
                            ),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.danger,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${(pct * 100).toStringAsFixed(1)}% of total expenses",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
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
                    color: AppColors.violet,
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
  const _BannerStat({required this.label, required this.value, this.tooltip});
  final String label;
  final String value;
  final String? tooltip;

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
        if (tooltip != null)
          TooltipLabel(
            label: label,
            tooltip: tooltip!,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
            iconColor: Colors.white54,
          )
        else
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
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final String? tooltip;

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
            if (tooltip != null)
              TooltipLabel(
                label: label,
                tooltip: tooltip!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
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
  const _EmptyReport({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.bar_chart_outlined,
      title: message,
      subtitle: 'Data will appear as you make sales',
    );
  }
}

// =================== Shop Report (PDF) sheet ===================

/// Bottom sheet that lets the owner pick a date range and generate a
/// printable / shareable PDF report. Generation shows a loading
/// indicator; once ready, Preview and Share actions appear.
class _ShopReportSheet extends StatefulWidget {
  final ReportsController controller;

  const _ShopReportSheet({super.key, required this.controller});

  @override
  State<_ShopReportSheet> createState() => _ShopReportSheetState();
}

class _ShopReportSheetState extends State<_ShopReportSheet> {
  bool _busy = false;
  Uint8List? _bytes;

  ReportsController get _c => widget.controller;

  String get _rangeSummary {
    final s = _c.startDate.value;
    final e = _c.endDate.value;
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    final dates = sameDay
        ? Formatters.dateShort(s)
        : '${Formatters.dateShort(s)} – ${Formatters.dateShort(e)}';
    return '${_rangeName(_c.selectedRange.value)} · $dates';
  }

  String _rangeName(ReportsRange? sel) {
    switch (sel) {
      case ReportsRange.today:
        return 'Today';
      case ReportsRange.thisWeek:
        return 'This week';
      case ReportsRange.thisMonth:
        return 'This month';
      case ReportsRange.lastMonth:
        return 'Last month';
      case ReportsRange.allTime:
        return 'All time';
      case ReportsRange.custom:
        return 'Custom';
      case null:
        return 'Last 30 days';
    }
  }

  /// Apply a preset, then invalidate any previously generated PDF so a
  /// stale report can't be saved/shared for the wrong period.
  void _onPreset(VoidCallback apply) {
    apply();
    setState(() => _bytes = null);
  }

  Future<void> _generate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final bytes = await ShopReportPdfService.generate(_c.buildReportData());
      // Brief pause so the loading state is visible even when the
      // document generates in a few milliseconds.
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      Get.snackbar(
        'Could not generate report',
        '$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.dangerLight,
        colorText: AppColors.danger,
      );
    }
  }

  /// File name for the current period, e.g. shop_report_20251001_20251008.pdf.
  // String get _reportFilename {
  //   String d(DateTime x) =>
  //       '${x.year}${x.month.toString().padLeft(2, '0')}'
  //       '${x.day.toString().padLeft(2, '0')}';
  //   final s = _c.startDate.value;
  //   final e = _c.endDate.value;
  //   return 'shop_report_${d(s)}_${d(e)}.pdf';
  // }
  String get _reportFilename {
    String d(DateTime x) {
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${x.day.toString().padLeft(2, '0')}_${months[x.month - 1]}_${x.year}';
    }

    final s = _c.startDate.value;
    final e = _c.endDate.value;

    return 'shop_report_${d(s)}-${d(e)}.pdf';
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await Printing.sharePdf(bytes: bytes, filename: _reportFilename);
  }

  /// Open the report in the on-screen print/preview dialog: the system
  /// preview renders the pages so the owner can review the report, then
  /// print or "Save as PDF" from the dialog (or cancel without exporting).
  Future<void> _preview() async {
    final bytes = _bytes;
    if (bytes == null) return;
    await Printing.layoutPdf(onLayout: (format) async => bytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Obx(() {
      final sel = _c.selectedRange.value;
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: AppSpacing.md),
            Text(
              'Shop report',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a period, then generate a PDF to save, print or share.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip(
                    'Today',
                    sel == ReportsRange.today,
                    () => _onPreset(_c.setToday),
                  ),
                  _chip(
                    'This week',
                    sel == ReportsRange.thisWeek,
                    () => _onPreset(_c.setThisWeek),
                  ),
                  _chip(
                    'This month',
                    sel == ReportsRange.thisMonth,
                    () => _onPreset(_c.setThisMonth),
                  ),
                  _chip(
                    'Last month',
                    sel == ReportsRange.lastMonth,
                    () => _onPreset(_c.setLastMonth),
                  ),
                  _chip(
                    'All time',
                    sel == ReportsRange.allTime,
                    () => _onPreset(_c.setAllTime),
                  ),
                  _chip(
                    'Custom',
                    sel == ReportsRange.custom,
                    () => _pickCustom(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.date_range,
                  size: 14,
                  color: sel == null ? cs.onSurfaceVariant : cs.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _rangeSummary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: sel == null ? cs.onSurfaceVariant : cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (_busy)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Generating your report…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generate report'),
                  onPressed: _generate,
                ),
              ),
              if (_bytes != null) ...[
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Preview report'),
                    onPressed: _preview,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.primary,
                          side: BorderSide(color: cs.primary),
                        ),
                        icon: const Icon(Icons.ios_share),
                        label: const Text('Share'),
                        onPressed: _share,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      );
    });
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Future<void> _pickCustom(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _c.startDate.value,
        end: _c.endDate.value,
      ),
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _bytes = null);
      _c.setCustomRange(picked.start, picked.end);
    }
  }
}
