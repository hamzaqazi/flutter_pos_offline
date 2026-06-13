import 'product_model.dart';

class CartItemModel {
  ProductModel product;
  int quantity;

  CartItemModel({required this.product, required this.quantity});

  double get total => product.price * quantity;
}
