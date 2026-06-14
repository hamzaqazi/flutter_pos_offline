import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
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
    final hasDiscount = product.discount > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tap out-of-stock → edit (restock), tap in-stock → add to cart
        onTap: outOfStock
            ? () => _showEditDialog(context)
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
        // Long-press any card → edit
        onLongPress: () => _showEditDialog(context),
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
                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Text(
                          "-${product.discount.toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  // SKU badge
                  if (product.hasSku)
                    Positioned(
                      top: AppSpacing.sm,
                      right: hasDiscount ? 60 : AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag,
                              color: Colors.white70,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.sku,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Barcode badge (shown below SKU badge if both exist)
                  if (product.hasBarcode)
                    Positioned(
                      top: product.hasSku ? 28 : AppSpacing.sm,
                      right: hasDiscount ? 60 : AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: Colors.white70,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.barcode.length > 8
                                  ? '${product.barcode.substring(0, 4)}...${product.barcode.substring(product.barcode.length - 4)}'
                                  : product.barcode,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Add-to-cart button (only when in stock)
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
                  // Edit button — always visible, above out-of-stock overlay
                  Positioned(
                    bottom: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: GestureDetector(
                      onTap: () => _showEditDialog(context),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cs.surface.withValues(alpha: 0.9),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  // Out-of-stock overlay — IgnorePointer so edit button still works
                  if (outOfStock)
                    IgnorePointer(
                      child: Container(
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
                  if (product.hasBrand) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasDiscount) ...[
                              Text(
                                Formatters.currency(product.price),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 1),
                            ],
                            Text(
                              Formatters.currency(product.discountedPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
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

  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: product.name);
    final brandController = TextEditingController(text: product.brand);
    final skuController = TextEditingController(text: product.sku);
    final barcodeController = TextEditingController(text: product.barcode);
    final priceController =
        TextEditingController(text: product.price.toStringAsFixed(0));
    final purchasePriceController =
        TextEditingController(text: product.purchasePrice.toStringAsFixed(0));
    final discountController =
        TextEditingController(text: product.discount.toStringAsFixed(0));
    final stockController =
        TextEditingController(text: product.stock.toString());
    String selectedCategory = product.category;

    final controller = Get.find<ProductsController>();

    Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: StatefulBuilder(
            builder: (context, setState) {
              final theme = Theme.of(context);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text("Edit Product",
                            style: theme.textTheme.titleLarge),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Product name",
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: brandController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: "Brand (optional)",
                        prefixIcon: Icon(Icons.branding_watermark_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // SKU field (internal code)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skuController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: "SKU",
                              hintText: "e.g. W0001",
                              prefixIcon: Icon(Icons.tag_outlined),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.outlined(
                          onPressed: () {
                            skuController.text = controller.generateSku(selectedCategory);
                            setState(() {});
                          },
                          icon: const Icon(Icons.autorenew, size: 20),
                          tooltip: "Auto-generate SKU",
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // Barcode field (real-world barcode from product packaging)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Barcode",
                              hintText: "e.g. 8901234567890",
                              prefixIcon: Icon(Icons.qr_code_outlined),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.outlined(
                          onPressed: () async {
                            final result = await BarcodeScannerHelper.scanAndLookupRaw();
                            if (result != null && result.isNotEmpty) {
                              setState(() => barcodeController.text = result);
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner, size: 20),
                          tooltip: "Scan barcode with camera",
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Sell price",
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: purchasePriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Purchase price",
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Discount %",
                              prefixIcon: Icon(Icons.discount_outlined),
                              suffixText: "%",
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: stockController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Stock",
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "Watches", child: Text("Watches")),
                        DropdownMenuItem(value: "Caps", child: Text("Caps")),
                        DropdownMenuItem(
                            value: "Perfumes", child: Text("Perfumes")),
                        DropdownMenuItem(
                            value: "Glasses", child: Text("Glasses")),
                      ],
                      onChanged: (value) =>
                          setState(() => selectedCategory = value!),
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
                            onPressed: () {
                              if (nameController.text.isEmpty ||
                                  priceController.text.isEmpty ||
                                  stockController.text.isEmpty) {
                                Get.snackbar(
                                  "Missing info",
                                  "Please fill all required fields",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              final discountVal =
                                  double.tryParse(discountController.text) ??
                                      0;
                              if (discountVal < 0 || discountVal > 100) {
                                Get.snackbar(
                                  "Invalid discount",
                                  "Discount must be between 0 and 100",
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }

                              controller.updateProduct(
                                product.copyWith(
                                  name: nameController.text,
                                  brand: brandController.text,
                                  category: selectedCategory,
                                  price: double.tryParse(
                                          priceController.text) ??
                                      product.price,
                                  purchasePrice: double.tryParse(
                                          purchasePriceController.text) ??
                                      0,
                                  discount: discountVal,
                                  stock: int.tryParse(
                                          stockController.text) ??
                                      product.stock,
                                  sku: skuController.text.trim(),
                                  barcode: barcodeController.text.trim(),
                                ),
                              );
                              Get.back();
                            },
                            child: const Text("Save"),
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
