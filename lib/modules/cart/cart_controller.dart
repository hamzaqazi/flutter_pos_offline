import 'package:get/get.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartController extends GetxController {
  final cartItems = <CartItemModel>[].obs;

  void addToCart(ProductModel product) {
    final existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity++;
      cartItems.refresh();
    } else {
      cartItems.add(CartItemModel(product: product, quantity: 1));
    }
  }

  void increaseQuantity(int index) {
    cartItems[index].quantity++;
    cartItems.refresh();
  }

  void decreaseQuantity(int index) {
    if (cartItems[index].quantity > 1) {
      cartItems[index].quantity--;
    } else {
      cartItems.removeAt(index);
    }

    cartItems.refresh();
  }

  /// Total using discounted prices.
  double get totalAmount {
    return cartItems.fold(0, (sum, item) => sum + item.total);
  }

  /// Total discount savings across all cart items.
  double get totalSavings {
    return cartItems.fold(0, (sum, item) => sum + item.savings);
  }

  /// Total profit across all cart items.
  double get totalProfit {
    return cartItems.fold(0, (sum, item) => sum + item.profit);
  }

  int get totalItems {
    return cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  void clearCart() {
    cartItems.clear();
  }
}
