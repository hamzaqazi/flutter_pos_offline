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
          sku: e['sku'] ?? '',
        ),
      ),
    );
  }

  void addProduct(ProductModel product) {
    HiveService.productBox.put(product.id, _toMap(product));
    products.add(product);
  }

  /// Full update: edit name, brand, category, price, purchasePrice, discount, stock, sku.
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

  /// Generate an auto SKU from category prefix + sequential number.
  String generateSku(String category) {
    final prefix = _categoryPrefix(category);
    // Find the highest existing number for this prefix
    int maxNum = 0;
    for (final p in products) {
      if (p.sku.startsWith(prefix)) {
        final numPart = p.sku.substring(prefix.length);
        final num = int.tryParse(numPart) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    final nextNum = maxNum + 1;
    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  String _categoryPrefix(String category) {
    switch (category) {
      case 'Watches':
        return 'W';
      case 'Caps':
        return 'C';
      case 'Perfumes':
        return 'P';
      case 'Glasses':
        return 'G';
      default:
        return 'X';
    }
  }

  /// Find a product by SKU (exact match, case-insensitive).
  ProductModel? findBySku(String sku) {
    if (sku.isEmpty) return null;
    try {
      return products.firstWhere(
        (p) => p.sku.toLowerCase() == sku.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
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
        'sku': p.sku,
      };

  List<ProductModel> get filteredProducts {
    return products.where((product) {
      final query = searchQuery.value.toLowerCase();
      final matchesSearch = product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query);

      final matchesCategory = selectedCategory.value == 'All' ||
          product.category == selectedCategory.value;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
