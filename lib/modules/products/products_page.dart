import 'package:ad_shop_pos/app/shell/app_shell_app_bar.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_empty_state.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/modules/manual/manual_nav.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:ad_shop_pos/app/shell/shell_controller.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:get/get.dart';

import 'products_controller.dart';
import 'product_form_page.dart';

class ProductsPage extends GetView<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppShellAppBar(
        title: Obx(() {
          // Rebuild the product cap counter when the plan changes.
          LicenseService.revision.value;
          if (LicenseService.isPremium) return const Text("Products");
          final count = controller.products.length;
          return Text("Products ($count/${LicenseService.freeMaxProducts})");
        }),
        // No app-bar help icon here — this bar already carries the scanner
        // and cart actions plus the free-plan product counter. The manual is
        // one tap away from the empty state below and from the More tab.
        actions: [
          // Barcode scanner button
          IconButton(
            onPressed: () => BarcodeScannerHelper.scanAndLookup(
              onScanned: (code) => BarcodeScannerHelper.addSkuToCart(code),
            ),
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: "Scan barcode",
          ),
          GetX<CartController>(
            builder: (cart) {
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => ShellController.to.goCart(),
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

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        child: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const ProductFormPage()),
          icon: const Icon(Icons.add),
          label: const Text("Add product"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.huge),
          ),
        ),
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
                hintText: "Search by name, brand, SKU or barcode...",
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

          // ---------- View toggle ----------
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Obx(
                () => SegmentedButton<ProductViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: ProductViewMode.grid,
                      icon: Icon(Icons.grid_view_rounded),
                      label: Text('Grid'),
                    ),
                    ButtonSegment(
                      value: ProductViewMode.list,
                      icon: Icon(Icons.view_list_rounded),
                      label: Text('List'),
                    ),
                  ],
                  selected: {controller.viewMode.value},
                  onSelectionChanged: (selected) {
                    controller.viewMode.value = selected.first;
                  },
                  showSelectedIcon: false,
                ),
              ),
            ),
          ),

          // ---------- Category filter ----------
          SizedBox(
            height: 44,
            child: Obx(() {
              final cats = [
                'All',
                ...Get.find<CategoryController>().categoryNames,
              ];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: cats.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, i) => _categoryChip(cats[i], cs),
              );
            }),
          ),

          // ---------- Products ----------
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshProducts,
              color: cs.primary,
              child: Obx(() {
                final items = controller.filteredProducts;
                if (items.isEmpty) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: _EmptyState(
                              hasProducts: controller.products.isNotEmpty,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                final padding = const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  // Floating nav clearance + room for the FAB above it
                  AppSpacing.navClearance + AppSpacing.huge,
                );

                if (controller.viewMode.value == ProductViewMode.list) {
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: padding,
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, index) =>
                        ProductCard(product: items[index], compact: true),
                  );
                }

                return GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: padding,
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemBuilder: (_, index) => ProductCard(product: items[index]),
                );
              }),
            ),
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasProducts});
  final bool hasProducts;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: hasProducts ? Icons.search_off : Icons.inventory_2_outlined,
      title: hasProducts ? 'No matching products' : 'No products yet',
      subtitle: hasProducts
          ? 'Try a different search or category'
          : 'Tap "Add product" to get started',
      // Point first-time users at the manual rather than leaving them at a
      // dead end.
      actionLabel: hasProducts ? null : 'How to add a product',
      onAction: hasProducts ? null : () => ManualNav.openGuide('add-product'),
    );
  }
}
