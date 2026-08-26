import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_widgets.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/widgets/premium_gate.dart';
import 'package:get/get.dart';

class ReturnsPage extends GetView<ReturnsController> {
  const ReturnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("Returns History")),
      body: PremiumGate(
        feature: 'Returns & Refunds',
        child: Obx(() {
          if (controller.returns.isEmpty) {
            return _EmptyReturns();
          }

          final returnsList = controller.returns.reversed.toList();
          final totalRefund = returnsList.fold<double>(
            0,
            (sum, r) => sum + r.refundAmount,
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
                      AppColors.warning,
                      AppColors.warning.withValues(alpha: 0.75),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _BannerStat(
                        label: "Total Refunds",
                        value: Formatters.currency(totalRefund),
                      ),
                    ),
                    Container(width: 1, height: 36, color: Colors.white24),
                    Expanded(
                      child: _BannerStat(
                        label: "Returns",
                        value: returnsList.length.toString(),
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
                  itemCount: returnsList.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (_, index) {
                    final ret = returnsList[index];
                    return _ReturnCard(returnRecord: ret);
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnModel returnRecord;
  const _ReturnCard({required this.returnRecord});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final controller = Get.find<ReturnsController>();

    return RepaintBoundary(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.assignment_return,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Refund ${Formatters.currency(returnRecord.refundAmount)}",
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        Formatters.dateTime(returnRecord.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, controller),
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppColors.danger.withValues(alpha: 0.6),
                  ),
                  tooltip: "Delete return record",
                ),
              ],
            ),

            // Reason
            if (returnRecord.reason.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  children: [
                    Icon(Icons.notes, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      returnRecord.reason,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Items
            ...returnRecord.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusSm,
                        ),
                      ),
                      child: Text(
                        "×${item.returnQty}",
                        style: const TextStyle(
                          color: AppColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      Formatters.currency(item.totalRefund),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Invoice reference
            const SizedBox(height: AppSpacing.sm),
            Builder(
              builder: (_) {
                String saleRef;
                try {
                  final salesCtrl = Get.find<SalesController>();
                  final sale = salesCtrl.sales.firstWhereOrNull(
                    (s) => s.id == returnRecord.saleId,
                  );
                  if (sale != null && sale.hasInvoiceNumber) {
                    saleRef = sale.invoiceNumber;
                  } else {
                    final shortId = returnRecord.saleId.length > 8
                        ? returnRecord.saleId.substring(
                            returnRecord.saleId.length - 8,
                          )
                        : returnRecord.saleId;
                    saleRef = "Sale #$shortId";
                  }
                } catch (_) {
                  final shortId = returnRecord.saleId.length > 8
                      ? returnRecord.saleId.substring(
                          returnRecord.saleId.length - 8,
                        )
                      : returnRecord.saleId;
                  saleRef = "Sale #$shortId";
                }
                return Row(
                  children: [
                    Icon(Icons.link, size: 12, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      saleRef,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ReturnsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Return"),
        content: const Text(
          "This will remove the return record but will NOT undo the restock. Are you sure?",
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Cancel")),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
            ),
            onPressed: () {
              controller.deleteReturn(returnRecord.id);
              Get.back();
            },
            child: const Text("Delete"),
          ),
        ],
      ),
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

class _EmptyReturns extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.assignment_return_outlined,
      title: 'No returns yet',
      subtitle: 'Processed returns will appear here',
    );
  }
}
