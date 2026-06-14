import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:ad_shop_pos/modules/staff/staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/services/invoice_pdf_service.dart';
import 'package:printing/printing.dart';

class InvoicePreviewPage extends StatelessWidget {
  final List<CartItemModel> items;
  final double subtotal;
  final double checkoutDiscount; // checkout discount percentage
  final double taxRate;         // tax rate %
  final bool taxInclusive;      // whether tax is included in price
  final double taxAmount;       // calculated tax amount
  final double total;
  final double cash;
  final double change;
  final double totalSavings;
  final String customerId;      // linked customer
  final String cashierId;       // staff who processed this sale

  /// When true, this is a past receipt being viewed (no sale completion).
  final bool readOnly;

  const InvoicePreviewPage({
    super.key,
    required this.items,
    this.subtotal = 0,
    this.checkoutDiscount = 0,
    this.taxRate = 0,
    this.taxInclusive = false,
    this.taxAmount = 0,
    required this.total,
    required this.cash,
    required this.change,
    this.totalSavings = 0,
    this.customerId = '',
    this.cashierId = '',
    this.readOnly = false,
  });

  double get _checkoutDiscountAmount => subtotal * checkoutDiscount / 100;

  String get _customerName {
    if (customerId.isEmpty) return '';
    final controller = Get.find<CustomersController>();
    final customer = controller.findById(customerId);
    return customer?.name ?? '';
  }

  String get _cashierName {
    if (cashierId.isEmpty) return '';
    final controller = Get.find<StaffController>();
    final staff = controller.findById(cashierId);
    return staff?.name ?? '';
  }

  Future<void> _printInvoice() async {
    final pdfBytes = await InvoicePdfService.generateInvoice(
      items: items,
      subtotal: subtotal,
      checkoutDiscount: checkoutDiscount,
      taxRate: taxRate,
      taxInclusive: taxInclusive,
      taxAmount: taxAmount,
      total: total,
      cash: cash,
      change: change,
      totalSavings: totalSavings,
      customerName: _customerName,
      cashierName: _cashierName,
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
                          Obx(() {
                            final settings = Get.find<SettingsController>();
                            return Column(
                              children: [
                                Text(
                                  settings.shopName.toUpperCase(),
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                  ),
                                ),
                                if (settings.address.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    settings.address,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (settings.phone.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    settings.phone,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          }),
                          const SizedBox(height: 4),
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

                    // ---------- Customer ----------
                    if (customerId.isNotEmpty && _customerName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "Customer: $_customerName",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _DashedDivider(),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // ---------- Cashier ----------
                    if (cashierId.isNotEmpty && _cashierName.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.badge_outlined,
                              size: 16, color: cs.onSurfaceVariant),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "Cashier: $_cashierName",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _DashedDivider(),
                      const SizedBox(height: AppSpacing.md),
                    ],

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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                        if (item.product.hasBrand)
                                          Text(
                                            item.product.brand,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                        if (item.product.hasSku)
                                          Text(
                                            "SKU: ${item.product.sku}",
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 9,
                                              fontFamily: 'monospace',
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
                    _row(theme, "Subtotal", Formatters.currency(subtotal)),
                    const SizedBox(height: AppSpacing.sm),
                    // Product-level discount savings
                    if (totalSavings - _checkoutDiscountAmount > 0) ...[
                      _row(
                        theme,
                        "Product discounts",
                        "-${Formatters.currency(totalSavings - _checkoutDiscountAmount)}",
                        valueColor: AppColors.success,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    // Checkout discount
                    if (checkoutDiscount > 0) ...[
                      _row(
                        theme,
                        "Checkout discount (${checkoutDiscount.toStringAsFixed(0)}%)",
                        "-${Formatters.currency(_checkoutDiscountAmount)}",
                        valueColor: AppColors.danger,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    // Tax
                    if (taxAmount > 0) ...[
                      _row(
                        theme,
                        taxInclusive
                            ? "Tax incl. (${taxRate.toStringAsFixed(1)}%)"
                            : "Tax (${taxRate.toStringAsFixed(1)}%)",
                        Formatters.currency(taxAmount),
                        valueColor: AppColors.accent,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.sm),
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
                      child: Obx(() {
                        final settings = Get.find<SettingsController>();
                        return Text(
                          settings.receiptFooter,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        );
                      }),
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
                            checkoutDiscount: checkoutDiscount,
                            taxAmount: taxAmount,
                            customerId: customerId,
                            cashierId: cashierId,
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
