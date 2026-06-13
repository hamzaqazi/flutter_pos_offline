import 'package:get/get.dart';

import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';
import '../../data/services/settings_service.dart';

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

  /// Subtotal using discounted prices (before tax).
  double get subtotalAmount {
    return cartItems.fold(0, (sum, item) => sum + item.total);
  }

  /// Tax amount based on settings.
  double get taxAmount {
    final settings = SettingsService.getSettings();
    if (settings.taxRate <= 0) return 0;
    if (settings.taxInclusive) {
      // Tax is included in the price, extract it
      return subtotalAmount - (subtotalAmount / (1 + settings.taxRate / 100));
    } else {
      // Tax is added on top
      return subtotalAmount * settings.taxRate / 100;
    }
  }

  /// Total including tax (for tax-exclusive: subtotal + tax; for tax-inclusive: subtotal already includes tax).
  double get totalAmount {
    final settings = SettingsService.getSettings();
    if (settings.taxInclusive) {
      return subtotalAmount; // tax already included
    } else {
      return subtotalAmount + taxAmount;
    }
  }

  /// Total discount savings across all cart items.
  double get totalSavings {
    return cartItems.fold(0, (sum, item) => sum + item.savings);
  }

  /// Total profit across all cart items (before tax).
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
