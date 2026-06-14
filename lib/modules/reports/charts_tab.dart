import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/reports/reports_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Charts tab for Reports — shows visual analytics.
class ChartsTab extends GetView<ReportsController> {
  const ChartsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.filteredSales.isEmpty) {
        return _EmptyChart();
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue chart
            _ChartCard(
              title: "Daily Revenue",
              icon: Icons.trending_up_outlined,
              color: AppColors.seed,
              child: _RevenueChart(controller: controller),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Category pie chart
            _ChartCard(
              title: "Sales by Category",
              icon: Icons.pie_chart_outline,
              color: AppColors.accent,
              child: _CategoryPieChart(controller: controller),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Staff performance
            _ChartCard(
              title: "Staff Performance",
              icon: Icons.people_outline,
              color: const Color(0xFF8B5CF6),
              child: _StaffPerformance(controller: controller),
            ),
          ],
        ),
      );
    });
  }
}

// =================== Revenue Bar Chart ===================

class _RevenueChart extends StatelessWidget {
  final ReportsController controller;
  const _RevenueChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final dailyRevenue = controller.dailyRevenue;
    if (dailyRevenue.isEmpty) return const SizedBox.shrink();

    final entries = dailyRevenue.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    // Take last 14 days max
    final recent = entries.length > 14 ? entries.sublist(entries.length - 14) : entries;
    final maxVal = recent.fold<double>(0, (max, e) => e.value > max ? e.value : max);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.2 : 100,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final entry = recent[group.x.toInt()];
                return BarTooltipItem(
                  '${_shortDate(entry.key)}\n${Formatters.currency(rod.toY)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (v, _) => Text(
                  Formatters.currency(v),
                  style: const TextStyle(fontSize: 9),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= recent.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _shortDate(recent[idx].key),
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxVal > 0 ? maxVal / 4 : 100,
          ),
          barGroups: List.generate(recent.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: recent[i].value,
                  color: AppColors.seed,
                  width: recent.length > 10 ? 12 : 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _shortDate(String isoDate) {
    try {
      final parts = isoDate.split('-');
      return '${parts[2]}/${parts[1]}';
    } catch (_) {
      return isoDate;
    }
  }
}

// =================== Category Pie Chart ===================

class _CategoryPieChart extends StatelessWidget {
  final ReportsController controller;
  const _CategoryPieChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    final categories = controller.categoryBreakdownList;
    if (categories.isEmpty) return const SizedBox.shrink();

    final totalRevenue = categories.fold<double>(0, (s, c) => s + c.revenue);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sections: categories.map((cat) {
                final pct = totalRevenue > 0 ? cat.revenue / totalRevenue : 0.0;
                final accent = AppColors.forCategory(cat.category);
                return PieChartSectionData(
                  color: accent,
                  value: cat.revenue,
                  title: '${(pct * 100).toStringAsFixed(0)}%',
                  radius: 60,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Legend
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: categories.map((cat) {
            final accent = AppColors.forCategory(cat.category);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  cat.category,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

// =================== Staff Performance ===================

class _StaffPerformance extends StatelessWidget {
  final ReportsController controller;
  const _StaffPerformance({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final staffController = Get.find<StaffController>();
    final sales = controller.filteredSales;

    if (staffController.staff.isEmpty || sales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          "No staff sales data for this period",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    // Group sales by cashier
    final cashierStats = <String, _CashierStat>{};
    for (final sale in sales) {
      if (!sale.hasCashier) continue;
      final stat = cashierStats.putIfAbsent(
        sale.cashierId,
        () => _CashierStat(name: _getName(sale.cashierId, staffController)),
      );
      stat.salesCount++;
      stat.revenue += sale.total;
      stat.profit += sale.profit;
    }

    if (cashierStats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          "No cashier data linked to sales in this period",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final sorted = cashierStats.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return Column(
      children: sorted.map((stat) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.seed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      stat.name.isNotEmpty ? stat.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.seed,
                        fontWeight: FontWeight.w800,
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
                        stat.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "${stat.salesCount} sale${stat.salesCount == 1 ? '' : 's'}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.currency(stat.revenue),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      "+${Formatters.currency(stat.profit)}",
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
      }).toList(),
    );
  }

  String _getName(String id, StaffController ctrl) {
    final s = ctrl.findById(id);
    return s?.name ?? 'Unknown';
  }
}

// =================== Helper Classes ===================

class _CashierStat {
  final String name;
  int salesCount = 0;
  double revenue = 0;
  double profit = 0;

  _CashierStat({required this.name});
}

class _ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
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
            Text(
              "No data to chart",
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
