import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/returns/return_dialog.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
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
        final totalProfit =
            sales.fold<double>(0, (sum, s) => sum + s.profit);
        final totalDiscount =
            sales.fold<double>(0, (sum, s) => sum + s.discount);

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
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BannerStat(
                          label: "Revenue",
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
                          label: "Profit",
                          value: Formatters.currency(totalProfit),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 36,
                        color: Colors.white24,
                      ),
                      Expanded(
                        child: _BannerStat(
                          label: "Sales",
                          value: sales.length.toString(),
                        ),
                      ),
                    ],
                  ),
                  if (totalDiscount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.discount_outlined,
                              color: Colors.white70, size: 14),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            "Total discounts given: ${Formatters.currency(totalDiscount)}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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

                  // Check if there are returns for this sale
                  final returnsController = Get.find<ReturnsController>();
                  final saleReturns = returnsController.returnsForSale(sale.id);
                  final totalRefund = saleReturns.fold<double>(
                    0,
                    (sum, r) => sum + r.refundAmount,
                  );

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Get.to(
                          () => InvoicePreviewPage(
                            items: sale.items,
                            subtotal: sale.subtotal,
                            checkoutDiscount: sale.checkoutDiscount,
                            taxAmount: sale.taxAmount,
                            total: sale.total,
                            cash: sale.cash,
                            change: sale.change,
                            totalSavings: sale.discount,
                            customerId: sale.customerId,
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
                                  // Show customer name
                                  if (sale.hasCustomer)
                                    Builder(builder: (_) {
                                      final customersController = Get.find<CustomersController>();
                                      final customer = customersController.findById(sale.customerId);
                                      if (customer != null) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              Icon(Icons.person_outline, size: 12, color: cs.onSurfaceVariant),
                                              const SizedBox(width: 4),
                                              Text(
                                                customer.name,
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: cs.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Text(
                                        Formatters.dateTime(sale.date),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                      if (sale.profit > 0) ...[
                                        const SizedBox(width: AppSpacing.sm),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.success
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                                AppSpacing.radiusSm),
                                          ),
                                          child: Text(
                                            "+${Formatters.currency(sale.profit)} profit",
                                            style: const TextStyle(
                                              color: AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // Show refund badge if sale has returns
                                  if (totalRefund > 0) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
                                      ),
                                      child: Text(
                                        "Refunded: ${Formatters.currency(totalRefund)}",
                                        style: const TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Return button
                            Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.warning
                                          .withValues(alpha: 0.4),
                                    ),
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                  child: IconButton(
                                    onPressed: () => showReturnDialog(sale),
                                    icon: const Icon(
                                      Icons.assignment_return_outlined,
                                      size: 20,
                                    ),
                                    color: AppColors.warning,
                                    tooltip: "Process return",
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    constraints: const BoxConstraints(
                                      minWidth: 36,
                                      minHeight: 36,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Return",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: AppSpacing.sm),
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
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
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
