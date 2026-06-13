import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'sales_controller.dart';
import '../invoice/invoice_preview_page.dart';

class SalesHistoryPage extends GetView<SalesController> {
  const SalesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Sales History")),
      body: Obx(() {
        if (controller.sales.isEmpty) {
          return _EmptySales();
        }

        // Newest first
        final sales = controller.sales.reversed.toList();
        final totalRevenue =
            sales.fold<double>(0, (sum, s) => sum + s.total);

        return Column(
          children: [
            // ---------- Summary banner ----------
            Container(
              margin: const EdgeInsets.all(AppSpacing.lg),
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
              child: Row(
                children: [
                  Expanded(
                    child: _BannerStat(
                      label: "Total revenue",
                      value: Formatters.currency(totalRevenue),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _BannerStat(
                      label: "Transactions",
                      value: sales.length.toString(),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: sales.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) {
                  final sale = sales[index];
                  final itemCount =
                      sale.items.fold<int>(0, (s, i) => s + i.quantity);
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Get.to(
                          () => InvoicePreviewPage(
                            items: sale.items,
                            total: sale.total,
                            cash: sale.cash,
                            change: sale.change,
                            readOnly: true,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: AppColors.success,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Formatters.currency(sale.total),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    Formatters.dateTime(sale.date),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (itemCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                                child: Text(
                                  "$itemCount item${itemCount == 1 ? '' : 's'}",
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: cs.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BannerStat extends StatelessWidget {
  const _BannerStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptySales extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("No sales yet", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Completed sales will appear here",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
