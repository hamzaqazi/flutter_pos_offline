import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import 'products_controller.dart';

class ProductsPage extends GetView<ProductsController> {
  const ProductsPage({super.key});

  static const _categories = ["All", "Watches", "Caps", "Perfumes", "Glasses"];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          GetX<CartController>(
            builder: (cart) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Get.toNamed('/cart'),
                      icon: const Icon(Icons.shopping_cart_outlined),
                    ),
                    if (cart.cartItems.isNotEmpty)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            cart.totalItems.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Add product"),
      ),
      body: Column(
        children: [
          // ---------- Search with SKU scan icon ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search by name, brand or SKU...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Obx(() {
                  final query = controller.searchQuery.value;
                  if (query.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () => controller.searchQuery.value = '',
                  );
                }),
              ),
              onChanged: (value) => controller.searchQuery.value = value,
            ),
          ),

          // ---------- Category filter ----------
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _categoryChip(_categories[i], cs),
            ),
          ),

          // ---------- Grid ----------
          Expanded(
            child: Obx(() {
              final items = controller.filteredProducts;
              if (items.isEmpty) {
                return _EmptyState(
                  hasProducts: controller.products.isNotEmpty,
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                ),
                itemBuilder: (_, index) =>
                    ProductCard(product: items[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category, ColorScheme cs) {
    return Obx(() {
      final selected = controller.selectedCategory.value == category;
      return ChoiceChip(
        label: Text(category),
        selected: selected,
        onSelected: (_) => controller.selectedCategory.value = category,
        labelStyle: TextStyle(
          color: selected ? cs.onPrimary : cs.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: cs.primary,
        backgroundColor: cs.surface,
      );
    });
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    final skuController = TextEditingController();
    final priceController = TextEditingController();
    final purchasePriceController = TextEditingController();
    final discountController = TextEditingController();
    final stockController = TextEditingController();
    String selectedCategory = "Watches";

    // Auto-generate SKU when category changes
    void updateAutoSku(String category) {
      skuController.text = controller.generateSku(category);
    }

    updateAutoSku(selectedCategory);

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
                            Icons.add_box_outlined,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text("Add Product",
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
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: skuController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: "SKU / Barcode",
                              prefixIcon: Icon(Icons.qr_code_outlined),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.outlined(
                          onPressed: () {
                            updateAutoSku(selectedCategory);
                            setState(() {});
                          },
                          icon: const Icon(Icons.autorenew, size: 20),
                          tooltip: "Auto-generate SKU",
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
                      onChanged: (value) {
                        setState(() => selectedCategory = value!);
                        updateAutoSku(value!);
                      },
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

                              controller.addProduct(
                                ProductModel(
                                  id: UniqueKey().toString(),
                                  name: nameController.text,
                                  brand: brandController.text,
                                  category: selectedCategory,
                                  price:
                                      double.tryParse(priceController.text) ??
                                          0,
                                  purchasePrice: double.tryParse(
                                          purchasePriceController.text) ??
                                      0,
                                  discount: discountVal,
                                  stock:
                                      int.tryParse(stockController.text) ?? 0,
                                  sku: skuController.text.trim(),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasProducts});
  final bool hasProducts;

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
                hasProducts ? Icons.search_off : Icons.inventory_2_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasProducts ? "No matching products" : "No products yet",
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              hasProducts
                  ? "Try a different search or category"
                  : "Tap \"Add product\" to get started",
              textAlign: TextAlign.center,
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
