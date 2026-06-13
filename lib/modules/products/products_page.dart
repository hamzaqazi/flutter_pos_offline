import 'package:ad_shop_pos/data/services/hive_service.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import 'products_controller.dart';

class ProductsPage extends GetView<ProductsController> {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Products"),
        actions: [
          GetX<CartController>(
            builder: (cart) {
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => Get.toNamed('/cart'),
                    icon: const Icon(Icons.shopping_cart),
                  ),
                  if (cart.cartItems.isNotEmpty)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: CircleAvatar(
                        radius: 8,
                        child: Text(
                          cart.totalItems.toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // await HiveService.salesBox.clear();
          _showAddProductDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search products...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                controller.searchQuery.value = value;
              },
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _categoryChip("All"),
                _categoryChip("Watches"),
                _categoryChip("Caps"),
                _categoryChip("Perfumes"),
                _categoryChip("Glasses"),
              ],
            ),
          ),

          Expanded(
            child: Obx(
              () => GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.filteredProducts.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: .9,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (_, index) {
                  final product = controller.filteredProducts[index];

                  return ProductCard(product: product);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Obx(
        () => ChoiceChip(
          label: Text(category),
          selected: controller.selectedCategory.value == category,
          onSelected: (_) {
            controller.selectedCategory.value = category;
          },
        ),
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    String selectedCategory = "Watches";

    Get.dialog(
      AlertDialog(
        title: const Text("Add Product"),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Product Name",
                    ),
                  ),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Price"),
                  ),
                  TextField(
                    controller: stockController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Stock"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: "Watches",
                        child: Text("Watches"),
                      ),
                      DropdownMenuItem(value: "Caps", child: Text("Caps")),
                      DropdownMenuItem(
                        value: "Perfumes",
                        child: Text("Perfumes"),
                      ),
                      DropdownMenuItem(
                        value: "Glasses",
                        child: Text("Glasses"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  stockController.text.isEmpty) {
                Get.snackbar("Error", "Please fill all fields");
                return;
              }
              controller.addProduct(
                ProductModel(
                  id: UniqueKey().toString(),
                  name: nameController.text,
                  category: selectedCategory,
                  price: double.tryParse(priceController.text) ?? 0,
                  stock: int.tryParse(stockController.text) ?? 0,
                ),
              );

              Get.back();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
