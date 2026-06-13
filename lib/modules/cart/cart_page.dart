import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'cart_controller.dart';

class CartPage extends GetView<CartController> {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        actions: [
          Obx(() {
            if (controller.cartItems.isEmpty) return const SizedBox.shrink();
            return TextButton.icon(
              onPressed: () => controller.clearCart(),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text("Clear"),
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            );
          }),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Obx(() {
        if (controller.cartItems.isEmpty) {
          return _EmptyCart();
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: controller.cartItems.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, index) {
                  final item = controller.cartItems[index];
                  return _CartTile(
                    item: item,
                    onIncrease: () => controller.increaseQuantity(index),
                    onDecrease: () => controller.decreaseQuantity(index),
                  );
                },
              ),
            ),
            _SummaryBar(
              total: controller.totalAmount,
              savings: controller.totalSavings,
              itemCount: controller.totalItems,
              onCheckout: () => _checkout(context),
            ),
          ],
        );
      }),
    );
  }

  void _checkout(BuildContext context) {
    final cart = Get.find<CartController>();
    final cashController = TextEditingController();
    final checkoutDiscountController = TextEditingController();

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);

              // Parse checkout discount %
              final checkoutDiscountPct =
                  double.tryParse(checkoutDiscountController.text.trim()) ?? 0;
              final checkoutDiscountAmount =
                  cart.totalAmount * checkoutDiscountPct / 100;
              final grandTotal =
                  cart.totalAmount - checkoutDiscountAmount;

              final cash = double.tryParse(cashController.text.trim()) ?? 0;
              final change = cash - grandTotal;
              final enough = cash >= grandTotal;

              final totalAllSavings =
                  cart.totalSavings + checkoutDiscountAmount;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Checkout", style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- Price summary ----------
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        children: [
                          // Subtotal (after product-level discounts)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Subtotal",
                                  style: theme.textTheme.bodyMedium),
                              Text(
                                Formatters.currency(cart.totalAmount),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          // Product-level savings
                          if (cart.totalSavings > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Product discounts",
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.success,
                                    )),
                                Text(
                                  "-${Formatters.currency(cart.totalSavings)}",
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Checkout discount
                          if (checkoutDiscountPct > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    "Checkout discount ($checkoutDiscountPct%)",
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.danger,
                                    )),
                                Text(
                                  "-${Formatters.currency(checkoutDiscountAmount)}",
                                  style:
                                      theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.danger,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                          // Grand total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total payable",
                                  style: theme.textTheme.titleMedium),
                              Text(
                                Formatters.currency(grandTotal),
                                style:
                                    theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          if (totalAllSavings > 0) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Total saved: ${Formatters.currency(totalAllSavings)}",
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- Checkout discount field ----------
                    TextField(
                      controller: checkoutDiscountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Additional discount %",
                        prefixIcon: Icon(Icons.discount_outlined),
                        suffixText: "%",
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _discountChip("0%", "0", checkoutDiscountController,
                            setState),
                        _discountChip("5%", "5", checkoutDiscountController,
                            setState),
                        _discountChip("10%", "10", checkoutDiscountController,
                            setState),
                        _discountChip("15%", "15", checkoutDiscountController,
                            setState),
                        _discountChip("20%", "20", checkoutDiscountController,
                            setState),
                        _discountChip("25%", "25", checkoutDiscountController,
                            setState),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // ---------- Cash field ----------
                    TextField(
                      controller: cashController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: "Cash received",
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        _quickChip("Exact", grandTotal, cashController,
                            setState),
                        _quickChip(
                            "+500", grandTotal + 500, cashController, setState),
                        _quickChip("+1000", grandTotal + 1000,
                            cashController, setState),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (cashController.text.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Change",
                              style: theme.textTheme.bodyMedium),
                          Text(
                            enough
                                ? Formatters.currency(change)
                                : "Insufficient",
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: enough
                                  ? AppColors.success
                                  : AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: Get.back,
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: FilledButton(
                            onPressed: enough
                                ? () {
                                    Get.back();
                                    Get.to(
                                      () => InvoicePreviewPage(
                                        items: cart.cartItems,
                                        subtotal: cart.totalAmount,
                                        checkoutDiscount:
                                            checkoutDiscountPct,
                                        total: grandTotal,
                                        cash: cash,
                                        change: change,
                                        totalSavings: totalAllSavings,
                                      ),
                                    );
                                  }
                                : null,
                            child: const Text("Pay"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _quickChip(
    String label,
    double value,
    TextEditingController controller,
    void Function(void Function()) setState,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = value.toStringAsFixed(0);
        setState(() {});
      },
    );
  }

  Widget _discountChip(
    String label,
    String value,
    TextEditingController controller,
    void Function(void Function()) setState,
  ) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        controller.text = value;
        setState(() {});
      },
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
  });

  final CartItemModel item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppColors.forCategory(item.product.category);
    final hasDiscount = item.product.discount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(Icons.shopping_bag_outlined, color: accent),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (hasDiscount) ...[
                    Row(
                      children: [
                        Text(
                          Formatters.currency(item.product.price),
                          style: theme.textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Text(
                            "-${item.product.discount.toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${Formatters.currency(item.product.discountedPrice)} each",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Text(
                      "${Formatters.currency(item.product.price)} each",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(item.total),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            // Quantity stepper
            Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepBtn(
                    icon: item.quantity > 1
                        ? Icons.remove
                        : Icons.delete_outline,
                    onTap: onDecrease,
                    color: item.quantity > 1 ? cs.onSurface : AppColors.danger,
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                      "${item.quantity}",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _StepBtn(icon: Icons.add, onTap: onIncrease, color: cs.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap, required this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.savings,
    required this.itemCount,
    required this.onCheckout,
  });

  final double total;
  final double savings;
  final int itemCount;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$itemCount item${itemCount == 1 ? '' : 's'}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      Formatters.currency(total),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (savings > 0)
                      Text(
                        "Saving ${Formatters.currency(savings)}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: onCheckout,
                  icon: const Icon(Icons.point_of_sale),
                  label: const Text("Checkout"),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(160, 52),
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

class _EmptyCart extends StatelessWidget {
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
                Icons.shopping_cart_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("Your cart is empty", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "Add products to start a sale",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => Get.toNamed('/products'),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text("Browse products"),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
