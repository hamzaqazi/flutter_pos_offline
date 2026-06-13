import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/product_model.dart';
import '../modules/cart/cart_controller.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final CartController cartController = Get.find<CartController>();

  ProductCard({super.key, required this.product});

  IconData _iconForCategory(String category) {
    switch (category) {
      case 'Watches':
        return Icons.watch_outlined;
      case 'Caps':
        return Icons.sports_baseball_outlined;
      case 'Perfumes':
        return Icons.spa_outlined;
      case 'Glasses':
        return Icons.remove_red_eye_outlined;
      default:
        return Icons.shopping_bag_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = AppColors.forCategory(product.category);
    final outOfStock = product.stock <= 0;
    final lowStock = product.stock > 0 && product.stock <= 5;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: outOfStock
            ? null
            : () {
                cartController.addToCart(product);
                Get.snackbar(
                  "Added to cart",
                  product.name,
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(AppSpacing.md),
                  duration: const Duration(milliseconds: 1200),
                  backgroundColor: cs.inverseSurface,
                  colorText: cs.onInverseSurface,
                  icon: Icon(Icons.check_circle, color: cs.onInverseSurface),
                );
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------- Image / icon area ----------
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          accent.withValues(alpha: 0.18),
                          accent.withValues(alpha: 0.06),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        _iconForCategory(product.category),
                        size: 40,
                        color: accent,
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Add button
                  if (!outOfStock)
                    Positioned(
                      bottom: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.primary,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  if (outOfStock)
                    Container(
                      color: cs.surface.withValues(alpha: 0.55),
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: const Text(
                          "Out of stock",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------- Details ----------
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.currency(product.price),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      _StockChip(
                        stock: product.stock,
                        low: lowStock,
                        out: outOfStock,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockChip extends StatelessWidget {
  const _StockChip({
    required this.stock,
    required this.low,
    required this.out,
  });

  final int stock;
  final bool low;
  final bool out;

  @override
  Widget build(BuildContext context) {
    final Color color = out
        ? AppColors.danger
        : low
            ? AppColors.warning
            : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        "$stock",
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
