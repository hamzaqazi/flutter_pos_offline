import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import '../../data/services/hive_service.dart';

class ProductsController extends GetxController {
  final products = <ProductModel>[].obs;

  final searchQuery = ''.obs;
  final selectedCategory = 'All'.obs;

  @override
  void onInit() {
    loadProducts();
    super.onInit();
  }

  void loadProducts() {
    final data = HiveService.productBox.values.toList();

    products.assignAll(
      data.map(
        (e) => ProductModel(
          id: e['id'],
          name: e['name'],
          category: e['category'],
          price: e['price'],
          stock: e['stock'],
        ),
      ),
    );
  }

  void addProduct(ProductModel product) {
    HiveService.productBox.put(product.id, {
      'id': product.id,
      'name': product.name,
      'category': product.category,
      'price': product.price,
      'stock': product.stock,
    });

    products.add(product);
  }

  void updateStock(String id, int newStock) {
    final index = products.indexWhere((p) => p.id == id);

    if (index != -1) {
      final product = products[index];

      final updated = product.copyWith(stock: newStock);

      products[index] = updated;

      HiveService.productBox.put(id, {
        'id': updated.id,
        'name': updated.name,
        'category': updated.category,
        'price': updated.price,
        'stock': updated.stock,
      });
    }
  }

  void deleteProduct(int id) {
    products.removeWhere((e) => e.id == id);
    HiveService.productBox.delete(id);
  }

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(
        searchQuery.value.toLowerCase(),
      );

      final matchesCategory =
          selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
