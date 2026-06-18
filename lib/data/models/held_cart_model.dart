import 'cart_item_model.dart';

/// A cart that has been put on hold for later retrieval.
class HeldCartModel {
  final String id;
  final List<CartItemModel> items;
  final DateTime heldAt;
  final String label; // e.g. "Customer name" or "3 items"

  HeldCartModel({
    required this.id,
    required this.items,
    required this.heldAt,
    this.label = '',
  });

  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items
          .map((e) => {
                'productId': e.product.id,
                'name': e.product.name,
                'brand': e.product.brand,
                'sku': e.product.sku,
                'barcode': e.product.barcode,
                'price': e.product.price,
                'purchasePrice': e.product.purchasePrice,
                'discount': e.product.discount,
                'category': e.product.category,
                'stock': e.product.stock,
                'qty': e.quantity,
              })
          .toList(),
      'heldAt': heldAt.toIso8601String(),
      'label': label,
    };
  }

  factory HeldCartModel.fromMap(Map data) {
    final rawItems = (data['items'] as List?) ?? [];
    final items = rawItems.map((item) {
      return CartItemModel(
        product: ProductModel(
          id: item['productId'] ?? '',
          name: item['name'] ?? '',
          brand: item['brand'] ?? '',
          sku: item['sku'] ?? '',
          barcode: item['barcode'] ?? '',
          price: (item['price'] ?? 0).toDouble(),
          purchasePrice: (item['purchasePrice'] ?? 0).toDouble(),
          discount: (item['discount'] ?? 0).toDouble(),
          category: item['category'] ?? '',
          stock: item['stock'] ?? 0,
        ),
        quantity: item['qty'] ?? 1,
      );
    }).toList();

    return HeldCartModel(
      id: data['id'] ?? '',
      items: items,
      heldAt: DateTime.tryParse(data['heldAt'] ?? '') ?? DateTime.now(),
      label: data['label'] ?? '',
    );
  }
}
