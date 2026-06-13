import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/services/invoice_pdf_service.dart';
import 'package:printing/printing.dart';

class InvoicePreviewPage extends StatelessWidget {
  final List<CartItemModel> items;
  final double total;
  final double cash;
  final double change;
  final double totalSavings;

  /// When true, this is a past receipt being viewed (no sale completion).
  final bool readOnly;

  const InvoicePreviewPage({
    super.key,
    required this.items,
    required this.total,
    required this.cash,
    required this.change,
    this.totalSavings = 0,
    this.readOnly = false,
  });

  Future<void> _printInvoice() async {
    final pdfBytes = await InvoicePdfService.generateInvoice(
      items: items,
      total: total,
      cash: cash,
      change: change,
      totalSavings: totalSavings,
    );
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(readOnly ? "Receipt" : "Invoice Preview")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ---------- Header ----------
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd),
                            ),
                            child: Icon(Icons.storefront,
                                color: cs.primary, size: 28),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            "SHOP RECEIPT",
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.dateTime(DateTime.now()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _DashedDivider(),
                    const SizedBox(height: AppSpacing.md),

                    // ---------- Items ----------
                    if (items.isEmpty)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Text(
                          "Item details not available",
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ...items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        if (item.product.hasBrand)
                                          Text(
                                            item.product.brand,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "${item.quantity} × ${Formatters.currency(item.product.discountedPrice)}",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Text(
                                    Formatters.currency(item.total),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.product.discount > 0)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 2, left: AppSpacing.xs),
                                  child: Text(
                                    "Original: ${Formatters.currency(item.product.price)} each (-${item.product.discount.toStringAsFixed(0)}%)",
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.success,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: AppSpacing.md),
                    const _DashedDivider(),
                    const SizedBox(height: AppSpacing.md),

                    // ---------- Totals ----------
                    if (totalSavings > 0) ...[
                      _row(theme, "Discount saved",
                          "-${Formatters.currency(totalSavings)}",
                          valueColor: AppColors.success),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _row(theme, "Total", Formatters.currency(total),
                        emphasize: true),
                    const SizedBox(height: AppSpacing.sm),
                    _row(theme, "Cash", Formatters.currency(cash)),
                    const SizedBox(height: AppSpacing.sm),
                    _row(theme, "Change", Formatters.currency(change)),

                    const SizedBox(height: AppSpacing.lg),
                    const _DashedDivider(),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Text(
                        "Thank you for shopping! 🙏",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: readOnly
              ? OutlinedButton.icon(
                  icon: const Icon(Icons.print_outlined),
                  label: const Text("Reprint receipt"),
                  onPressed: _printInvoice,
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.print_outlined),
                        label: const Text("Print"),
                        onPressed: _printInvoice,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Complete sale"),
                        onPressed: () async {
                          await _printInvoice();
                          Get.find<SalesController>().completeSale(
                            cash: cash,
                            change: change,
                          );
                          Get.offAllNamed('/');
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value,
      {bool emphasize = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: emphasize
              ? theme.textTheme.titleMedium
              : theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        Text(
          value,
          style: emphasize
              ? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? theme.colorScheme.primary,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
        );
      },
    );
  }
}
