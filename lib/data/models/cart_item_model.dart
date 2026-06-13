import 'product_model.dart';

class CartItemModel {
  ProductModel product;
  int quantity;

  CartItemModel({required this.product, required this.quantity});

  /// Total for this line item using the discounted selling price.
  double get total => product.discountedPrice * quantity;

  /// Savings amount for this line item due to discount.
  double get savings => (product.price - product.discountedPrice) * quantity;

  /// Profit for this line item (discounted price minus purchase price * qty).
  double get profit => product.profitPerUnit * quantity;
}
