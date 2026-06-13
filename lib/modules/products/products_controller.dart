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
          brand: e['brand'] ?? '',
          category: e['category'],
          price: e['price'],
          purchasePrice: (e['purchasePrice'] ?? 0).toDouble(),
          discount: (e['discount'] ?? 0).toDouble(),
          stock: e['stock'],
        ),
      ),
    );
  }

  void addProduct(ProductModel product) {
    HiveService.productBox.put(product.id, _toMap(product));
    products.add(product);
  }

  /// Full update: edit name, brand, category, price, purchasePrice, discount, stock.
  void updateProduct(ProductModel product) {
    final index = products.indexWhere((p) => p.id == product.id);

    if (index != -1) {
      products[index] = product;
      HiveService.productBox.put(product.id, _toMap(product));
    }
  }

  /// Convenience: update stock only (for quick restock).
  void updateStock(String id, int newStock) {
    final index = products.indexWhere((p) => p.id == id);

    if (index != -1) {
      final product = products[index];
      final updated = product.copyWith(stock: newStock);
      products[index] = updated;
      HiveService.productBox.put(id, _toMap(updated));
    }
  }

  void deleteProduct(String id) {
    products.removeWhere((e) => e.id == id);
    HiveService.productBox.delete(id);
  }

  Map<String, dynamic> _toMap(ProductModel p) => {
        'id': p.id,
        'name': p.name,
        'brand': p.brand,
        'category': p.category,
        'price': p.price,
        'purchasePrice': p.purchasePrice,
        'discount': p.discount,
        'stock': p.stock,
      };

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
