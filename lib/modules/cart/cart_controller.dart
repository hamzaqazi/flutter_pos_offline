import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/held_cart_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class CartController extends GetxController {
  final cartItems = <CartItemModel>[].obs;
  final heldCarts = <HeldCartModel>[].obs;

  @override
  void onInit() {
    loadHeldCarts();
    super.onInit();
  }

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
      return subtotalAmount - (subtotalAmount / (1 + settings.taxRate / 100));
    } else {
      return subtotalAmount * settings.taxRate / 100;
    }
  }

  /// Total including tax.
  double get totalAmount {
    final settings = SettingsService.getSettings();
    if (settings.taxInclusive) {
      return subtotalAmount;
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

  // ========== Hold / Suspend Cart ==========

  /// Hold (suspend) the current cart for later retrieval.
  void holdCart({String label = ''}) {
    if (cartItems.isEmpty) return;

    final heldCart = HeldCartModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      items: List.from(cartItems),
      heldAt: DateTime.now(),
      label: label.isNotEmpty
          ? label
          : '${cartItems.length} item${cartItems.length == 1 ? '' : 's'}',
    );

    final box = Hive.box('held_carts');
    box.put(heldCart.id, heldCart.toMap());
    heldCarts.add(heldCart);
    cartItems.clear();

    Get.snackbar(
      "Cart held",
      "Cart saved — ${heldCart.totalItems} items",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Resume a held cart (adds items back to active cart).
  void resumeCart(String heldCartId) {
    final index = heldCarts.indexWhere((c) => c.id == heldCartId);
    if (index == -1) return;

    // If current cart has items, hold them first
    if (cartItems.isNotEmpty) {
      holdCart();
    }

    final heldCart = heldCarts[index];
    cartItems.assignAll(heldCart.items);
    deleteHeldCart(heldCartId);

    Get.snackbar(
      "Cart resumed",
      "${heldCart.totalItems} items restored",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Delete a held cart without resuming it.
  void deleteHeldCart(String heldCartId) {
    heldCarts.removeWhere((c) => c.id == heldCartId);
    Hive.box('held_carts').delete(heldCartId);
  }

  /// Load held carts from Hive.
  void loadHeldCarts() {
    final box = Hive.box('held_carts');
    final loaded = box.values.map((e) {
      return HeldCartModel.fromMap(Map<String, dynamic>.from(e));
    }).toList();
    heldCarts.assignAll(loaded);
  }

  /// Number of held carts.
  int get heldCartCount => heldCarts.length;
}
