import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../data/models/product_model.dart';
import '../modules/cart/cart_controller.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final CartController cartController = Get.find<CartController>();

  ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        cartController.addToCart(product);

        Get.snackbar(
          "Added",
          "${product.name} added to cart",
          snackPosition: SnackPosition.BOTTOM,
        );
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, size: 40),
              const SizedBox(height: 10),
              Text(product.name, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text("Rs ${product.price}"),
              Text("Stock: ${product.stock}"),
            ],
          ),
        ),
      ),
    );
  }
}
