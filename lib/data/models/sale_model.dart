// import 'cart_item_model.dart';

import 'package:ad_shop_pos/data/models/cart_item_model.dart';

class SaleModel {
  final String id;
  final List<CartItemModel> items;
  final double total;
  final double cash;
  final double change;
  final DateTime date;

  SaleModel({
    required this.id,
    required this.items,
    required this.total,
    required this.cash,
    required this.change,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items
          .map(
            (e) => {
              'productId': e.product.id,
              'name': e.product.name,
              'price': e.product.price,
              'qty': e.quantity,
            },
          )
          .toList(),
      'total': total,
      'cash': cash,
      'change': change,
      'date': date.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map data) {
    return SaleModel(
      id: data['id'],
      items: [], // you can rebuild later if needed
      total: data['total'],
      cash: data['cash'],
      change: data['change'],
      date: DateTime.parse(data['date']),
    );
  }
}
