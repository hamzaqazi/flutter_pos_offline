import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/sale_model.dart';

/// Shows a dialog to process a return/refund for a completed sale.
void showReturnDialog(SaleModel sale) {
  final returnsController = Get.find<ReturnsController>();

  // Build return qty controllers from sale items
  final qtyControllers = <TextEditingController>[];
  for (final item in sale.items) {
    qtyControllers.add(TextEditingController(text: '0'));
  }

  final reasonController = TextEditingController();

  Get.dialog(
    Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            final cs = theme.colorScheme;

            // Calculate total refund
            double totalRefund = 0;
            double totalProfitReversed = 0;
            for (int i = 0; i < sale.items.length; i++) {
              final item = sale.items[i];
              final returnQty =
                  int.tryParse(qtyControllers[i].text.trim()) ?? 0;
              if (returnQty > 0) {
                totalRefund += returnQty * item.product.discountedPrice;
                totalProfitReversed += returnQty * item.product.profitPerUnit;
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: const Icon(
                          Icons.assignment_return,
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Process Return",
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              "Sale ${Formatters.dateTime(sale.date)} • ${Formatters.currency(sale.total)}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Items list with qty fields
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: sale.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) {
                      final item = sale.items[index];

                      // Check already returned
                      final alreadyReturned = returnsController
                          .alreadyReturnedQty(sale.id, item.product.id);
                      final maxReturnable = item.quantity - alreadyReturned;

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (item.product.hasBrand)
                                      Text(
                                        item.product.brand,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Sold: ${item.quantity} × ${Formatters.currency(item.product.discountedPrice)}",
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                    if (alreadyReturned > 0)
                                      Text(
                                        "Already returned: $alreadyReturned",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.warning,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    if (maxReturnable <= 0)
                                      Text(
                                        "Fully returned",
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: AppColors.danger,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                              // Return qty input
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  controller: qtyControllers[index],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  enabled: maxReturnable > 0,
                                  decoration: InputDecoration(
                                    labelText: "Return",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                      vertical: AppSpacing.xs,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm,
                                      ),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Reason field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: TextField(
                    controller: reasonController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: "Reason (optional)",
                      prefixIcon: Icon(Icons.notes_outlined),
                      isDense: true,
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Refund summary
                if (totalRefund > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Refund amount",
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              Formatters.currency(totalRefund),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Profit reversed",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              "-${Formatters.currency(totalProfitReversed)}",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Action buttons
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          onPressed: totalRefund > 0
                              ? () {
                                  // Build return items
                                  final returnItems = <ReturnItemModel>[];
                                  for (int i = 0; i < sale.items.length; i++) {
                                    final item = sale.items[i];
                                    final returnQty =
                                        int.tryParse(
                                          qtyControllers[i].text.trim(),
                                        ) ??
                                        0;

                                    // Validate
                                    final alreadyReturned = returnsController
                                        .alreadyReturnedQty(
                                          sale.id,
                                          item.product.id,
                                        );
                                    final maxReturnable =
                                        item.quantity - alreadyReturned;

                                    if (returnQty > 0 &&
                                        returnQty <= maxReturnable) {
                                      returnItems.add(
                                        ReturnItemModel.fromCartItem(
                                          item,
                                          returnQty: returnQty,
                                        ),
                                      );
                                    }
                                  }

                                  if (returnItems.isEmpty) {
                                    Get.snackbar(
                                      "Invalid",
                                      "No valid items to return",
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                    return;
                                  }

                                  // Close dialog FIRST, then process return
                                  // This avoids Get.back() conflicting with Get.snackbar
                                  final itemsToReturn =
                                      List<ReturnItemModel>.from(returnItems);
                                  final reason = reasonController.text.trim();

                                  Navigator.of(context).pop();

                                  // Process after dialog is closed
                                  Future.microtask(() {
                                    returnsController.processReturn(
                                      saleId: sale.id,
                                      returnItems: itemsToReturn,
                                      reason: reason,
                                    );
                                  });
                                }
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.warning,
                          ),
                          child: const Text(
                            "Process Refund",
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
