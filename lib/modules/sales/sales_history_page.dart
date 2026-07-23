import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/returns/return_dialog.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/widgets/premium_gate.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/app/utils/launcher.dart';
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

        // Filtered sales
        final sales = controller.filteredSales;
        final returnsCtrl = Get.find<ReturnsController>();

        // Calculate refunds for filtered sales
        final saleIds = sales.map((s) => s.id).toSet();
        final filteredReturns = returnsCtrl.returns
            .where((r) => saleIds.contains(r.saleId))
            .toList();
        final totalRefundAmount = filteredReturns.fold<double>(
          0, (sum, r) => sum + r.refundAmount,
        );
        final totalProfitReversed = filteredReturns.fold<double>(
          0, (sum, r) => sum + r.refundProfit,
        );

        final totalRevenue = sales.fold<double>(0, (sum, s) => sum + s.total) - totalRefundAmount;
        final totalGrossProfit = sales.fold<double>(0, (sum, s) => sum + s.profit);
        final totalProfit = totalGrossProfit - totalProfitReversed;
        final totalDiscount = sales.fold<double>(
          0,
          (sum, s) => sum + s.discount,
        );

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
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: totalProfitReversed > 0 ? "Net Profit" : "Profit",
                          value: Formatters.currency(totalProfit),
                        ),
                      ),
                      Container(width: 1, height: 36, color: Colors.white24),
                      Expanded(
                        child: _BannerStat(
                          label: "Sales",
                          value: sales.length.toString(),
                        ),
                      ),
                    ],
                  ),
                  if (totalProfitReversed > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.assignment_return_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            "Refunds: ${Formatters.currency(totalRefundAmount)} (profit reversed: ${Formatters.currency(totalProfitReversed)})",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (totalDiscount > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.discount_outlined,
                            color: Colors.white70,
                            size: 14,
                          ),
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

            // ---------- Search bar ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by invoice no, customer or item...",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  filled: true,
                  suffixIcon: Obx(() {
                    if (controller.searchQuery.value.isEmpty)
                      return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => controller.searchQuery.value = '',
                    );
                  }),
                ),
                onChanged: (value) => controller.searchQuery.value = value,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // ---------- Date filter chips ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final filters = [
                      'All',
                      'Today',
                      'This Week',
                      'This Month',
                      'Custom',
                    ];
                    final filter = filters[i];
                    return Obx(() {
                      final selected = controller.dateFilter.value == filter;
                      return ChoiceChip(
                        label: Text(filter),
                        selected: selected,
                        onSelected: (_) async {
                          if (filter == 'Custom') {
                            final picked = await showDateRangePicker(
                              context: Get.context!,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange:
                                  controller.customStartDate != null &&
                                      controller.customEndDate != null
                                  ? DateTimeRange(
                                      start: controller.customStartDate!,
                                      end: controller.customEndDate!,
                                    )
                                  : null,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              controller.customStartDate = picked.start;
                              controller.customEndDate = picked.end;
                              controller.dateFilter.value = 'Custom';
                            }
                          } else {
                            controller.dateFilter.value = filter;
                          }
                        },
                      );
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Active filters indicator
            Obx(() {
              final hasFilter =
                  controller.dateFilter.value != 'All' ||
                  controller.searchQuery.value.isNotEmpty;
              if (!hasFilter) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 14,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      "${sales.length} result${sales.length == 1 ? '' : 's'}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => controller.clearFilters(),
                      icon: const Icon(Icons.clear_all, size: 14),
                      label: const Text(
                        "Clear filters",
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ),
              );
            }),

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
                  final itemCount = sale.items.fold<int>(
                    0,
                    (s, i) => s + i.quantity,
                  );

                  // Check if there are returns for this sale
                  final returnsController = Get.find<ReturnsController>();
                  final saleReturns = returnsController.returnsForSale(sale.id);
                  final totalRefund = saleReturns.fold<double>(
                    0,
                    (sum, r) => sum + r.refundAmount,
                  );
                  final saleProfitReversed = saleReturns.fold<double>(
                    0,
                    (sum, r) => sum + r.refundProfit,
                  );
                  final saleNetProfit = sale.profit - saleProfitReversed;

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
                            cashierId: sale.cashierId,
                            invoiceNumber: sale.invoiceNumber,
                            readOnly: true,
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusSm,
                                ),
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
                                  Row(
                                    children: [
                                      Text(
                                        Formatters.currency(sale.total),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      // if (sale.hasInvoiceNumber) ...[
                                      //   const SizedBox(width: AppSpacing.sm),
                                      //   Container(
                                      //     padding: const EdgeInsets.symmetric(
                                      //       horizontal: AppSpacing.xs,
                                      //       vertical: 1,
                                      //     ),
                                      //     decoration: BoxDecoration(
                                      //       color: cs.primary.withValues(
                                      //         alpha: 0.1,
                                      //       ),
                                      //       borderRadius: BorderRadius.circular(
                                      //         AppSpacing.radiusSm,
                                      //       ),
                                      //     ),
                                      //     child: Text(
                                      //       sale.invoiceNumber,
                                      //       style: TextStyle(
                                      //         color: cs.primary,
                                      //         fontSize: 10,
                                      //         fontWeight: FontWeight.w700,
                                      //         letterSpacing: 0.5,
                                      //       ),
                                      //     ),
                                      //   ),
                                      // ],
                                    ],
                                  ),
                                  if (sale.hasInvoiceNumber) ...[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.xs,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cs.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        sale.invoiceNumber,
                                        style: TextStyle(
                                          color: cs.primary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                  // Show customer name
                                  if (sale.hasCustomer)
                                    Builder(
                                      builder: (_) {
                                        final customersController =
                                            Get.find<CustomersController>();
                                        final customer = customersController
                                            .findById(sale.customerId);
                                        if (customer != null) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 12,
                                                  color: cs.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  customer.name,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color:
                                                            cs.onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }
                                        return const SizedBox.shrink();
                                      },
                                    ),
                                  const SizedBox(height: 2),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.xs,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        Formatters.dateTime(sale.date),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                      ),
                                      if (sale.profit > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.xs,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (saleProfitReversed > 0
                                                    ? AppColors.warning
                                                    : AppColors.success)
                                                .withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              AppSpacing.radiusSm,
                                            ),
                                          ),
                                          child: Text(
                                            saleProfitReversed > 0
                                                ? "${Formatters.currency(saleNetProfit)} net profit"
                                                : "+${Formatters.currency(sale.profit)} profit",
                                            style: TextStyle(
                                              color: saleProfitReversed > 0
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
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
                                        color: AppColors.warning.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusSm,
                                        ),
                                      ),
                                      child: Text(
                                        saleProfitReversed > 0
                                            ? "Refunded: ${Formatters.currency(totalRefund)} (profit −${Formatters.currency(saleProfitReversed)})"
                                            : "Refunded: ${Formatters.currency(totalRefund)}",
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
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                    child: Text(
                                      "$itemCount item${itemCount == 1 ? '' : 's'}",
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),

                                const SizedBox(height: 2),

                                Container(
                                  // decoration: BoxDecoration(
                                  //   border: Border.all(
                                  //     color: AppColors.warning.withValues(
                                  //       alpha: 0.4,
                                  //     ),
                                  //   ),
                                  //   borderRadius: BorderRadius.circular(
                                  //     AppSpacing.radiusSm,
                                  //   ),
                                  // ),
                                  child: IconButton.filledTonal(
                                    onPressed: () {
                                      if (!LicenseService.isPremium) {
                                        _showUpgradeDialog(context);
                                        return;
                                      }
                                      showReturnDialog(sale);
                                    },
                                    icon: const Icon(
                                      Icons.assignment_return_outlined,
                                      size: 20,
                                    ),
                                    color: AppColors.warning,
                                    tooltip: "Process return",
                                    padding: const EdgeInsets.all(
                                      AppSpacing.sm,
                                    ),
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
                            // if (itemCount > 0)
                            //   Container(
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: AppSpacing.sm,
                            //       vertical: AppSpacing.xs,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: cs.surfaceContainerHighest.withValues(
                            //         alpha: 0.6,
                            //       ),
                            //       borderRadius: BorderRadius.circular(
                            //         AppSpacing.radiusSm,
                            //       ),
                            //     ),
                            //     child: Text(
                            //       "$itemCount item${itemCount == 1 ? '' : 's'}",
                            //       style: theme.textTheme.bodySmall,
                            //     ),
                            //   ),
                            // const SizedBox(width: AppSpacing.sm),
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

void _showUpgradeDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Icon(Icons.lock_outline, size: 40, color: AppColors.warning),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Returns & Refunds',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'This feature is available on Premium plans.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            // WhatsApp purchase button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () => Launcher.openWhatsApp(
                  '923153507075',
                  'Hi, I want to purchase Codynest POS license.\nPlan: Any\nFeature: Returns & Refunds',
                ),
                icon: const Icon(Icons.chat, size: 20),
                label: const Text('Purchase via WhatsApp'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            // Call option
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => Launcher.makeCall('923153507075'),
                icon: const Icon(Icons.call, size: 18),
                label: const Text('Call: 0315-3507075'),
              ),
            ),
          ],
        ),
      );
    },
  );
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
