import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/sale_model.dart';
import '../../data/services/hive_service.dart';
import '../cart/cart_controller.dart';
import '../products/products_controller.dart';

class SalesController extends GetxController {
  final sales = <SaleModel>[].obs;

  @override
  void onInit() {
    loadSales();
    super.onInit();
  }

  void loadSales() {
    final data = HiveService.salesBox.values.toList();

    sales.assignAll(
      data.map((e) {
        final rawItems = (e['items'] as List?) ?? [];

        final items = rawItems.map((item) {
          return CartItemModel(
            product: ProductModel(
              id: item['productId'] ?? '',
              name: item['name'] ?? '',
              price: (item['price'] ?? 0).toDouble(),
              purchasePrice: (item['purchasePrice'] ?? 0).toDouble(),
              discount: (item['discount'] ?? 0).toDouble(),
              category: '',
              stock: 0,
            ),
            quantity: item['qty'] ?? 1,
          );
        }).toList();

        return SaleModel(
          id: e['id'] ?? '',
          items: items,
          total: (e['total'] ?? 0).toDouble(),
          cash: (e['cash'] ?? 0).toDouble(),
          change: (e['change'] ?? 0).toDouble(),
          discount: (e['discount'] ?? 0).toDouble(),
          profit: (e['profit'] ?? 0).toDouble(),
          date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
        );
      }).toList(),
    );
  }

  void completeSale({required double cash, required double change}) {
    final cart = Get.find<CartController>();
    final products = Get.find<ProductsController>();

    if (cart.cartItems.isEmpty) return;

    final saleId = DateTime.now().microsecondsSinceEpoch.toString();

    final totalDiscount = cart.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.savings,
    );

    final totalProfit = cart.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.profit,
    );

    final sale = SaleModel(
      id: saleId,
      items: List.from(cart.cartItems),
      total: cart.totalAmount,
      cash: cash,
      change: change,
      discount: totalDiscount,
      profit: totalProfit,
      date: DateTime.now(),
    );

    // reduce stock
    for (final item in cart.cartItems) {
      final newStock = item.product.stock - item.quantity;
      products.updateStock(item.product.id, newStock);
    }

    // SAVE FULL INVOICE (IMPORTANT)
    HiveService.salesBox.put(saleId, {
      'id': sale.id,
      'items': sale.items
          .map(
            (e) => {
              'productId': e.product.id,
              'name': e.product.name,
              'price': e.product.price,
              'purchasePrice': e.product.purchasePrice,
              'discount': e.product.discount,
              'discountedPrice': e.product.discountedPrice,
              'qty': e.quantity,
            },
          )
          .toList(),
      'total': sale.total,
      'cash': sale.cash,
      'change': sale.change,
      'discount': sale.discount,
      'profit': sale.profit,
      'date': sale.date.toIso8601String(),
    });

    sales.add(sale);
    cart.clearCart();

    Get.snackbar("Success", "Sale completed");
  }
}
