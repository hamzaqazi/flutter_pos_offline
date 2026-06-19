import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';

class LowStockPage extends StatelessWidget {
  const LowStockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final threshold = SettingsService.getSettings().lowStockThreshold;

    // Get ProductsController (lazy-loaded with fenix, so find always works)
    final controller = Get.find<ProductsController>();

    return Scaffold(
      appBar: AppBar(
        title: Text("Low Stock (≤ $threshold)"),
      ),
      body: Obx(() {
        final outOfStock = controller.outOfStockProducts;
        final lowStock = controller.lowStockProducts
            .where((p) => p.stock > 0)
            .toList();

        if (lowStock.isEmpty && outOfStock.isEmpty) {
          return _EmptyState(threshold: threshold);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // Summary
            Container(
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
                    child: _SummaryStat(
                      label: "Out of stock",
                      value: outOfStock.length.toString(),
                      icon: Icons.cancel_outlined,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: "Low stock",
                      value: lowStock.length.toString(),
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _SummaryStat(
                      label: "Threshold",
                      value: "≤ $threshold",
                      icon: Icons.tune,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Out of stock section
            if (outOfStock.isNotEmpty) ...[
              _SectionHeader(
                title: "Out of Stock",
                count: outOfStock.length,
                color: AppColors.danger,
                icon: Icons.cancel_outlined,
              ),
              const SizedBox(height: AppSpacing.md),
              ...outOfStock.map((p) => _LowStockTile(product: p, isOutOfStock: true)),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Low stock section
            if (lowStock.isNotEmpty) ...[
              _SectionHeader(
                title: "Low Stock",
                count: lowStock.length,
                color: AppColors.warning,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              ...lowStock.map((p) => _LowStockTile(product: p, isOutOfStock: false)),
            ],
          ],
        );
      }),
    );
  }
}

class _LowStockTile extends StatelessWidget {
  const _LowStockTile({required this.product, required this.isOutOfStock});
  final ProductModel product;
  final bool isOutOfStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = isOutOfStock ? AppColors.danger : AppColors.warning;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                isOutOfStock ? Icons.cancel_outlined : Icons.warning_amber_rounded,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.hasBrand)
                    Text(
                      product.brand,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          isOutOfStock ? "0 left" : "${product.stock} left",
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.forCategory(product.category)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            color: AppColors.forCategory(product.category),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        Formatters.currency(product.discountedPrice),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Quick restock button
            SizedBox(
              width: 110,
              child: FilledButton.tonalIcon(
                onPressed: () => _quickRestock(context, product),
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text("Restock"),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _quickRestock(BuildContext context, ProductModel product) {
    final addController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text("Restock — ${product.name}")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Current stock: ${product.stock} units",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: addController,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                labelText: "Add stock",
                hintText: "Enter quantity to add",
                prefixIcon: const Icon(Icons.add),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    final add = int.tryParse(addController.text.trim()) ?? 0;
                    if (add > 0) {
                      final controller = Get.find<ProductsController>();
                      controller.updateStock(product.id, product.stock + add);
                      Navigator.of(ctx).pop();
                      Get.snackbar(
                        "Restocked",
                        "+$add units added to ${product.name}",
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    }
                  },
                ),
              ),
              onSubmitted: (value) {
                final add = int.tryParse(value.trim()) ?? 0;
                if (add > 0) {
                  final controller = Get.find<ProductsController>();
                  controller.updateStock(product.id, product.stock + add);
                  Navigator.of(ctx).pop();
                  Get.snackbar(
                    "Restocked",
                    "+$add units added to ${product.name}",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final add = int.tryParse(addController.text.trim()) ?? 0;
              if (add > 0) {
                final controller = Get.find<ProductsController>();
                controller.updateStock(product.id, product.stock + add);
                Navigator.of(ctx).pop();
                Get.snackbar(
                  "Restocked",
                  "+$add units added to ${product.name}",
                  snackPosition: SnackPosition.BOTTOM,
                );
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String title;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          "$title ($count)",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 4),
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
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.threshold});
  final int threshold;

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
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text("All stocked up!", style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "No products are at or below $threshold units",
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
