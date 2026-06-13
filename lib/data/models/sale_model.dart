// import 'cart_item_model.dart';

import 'package:ad_shop_pos/data/models/cart_item_model.dart';

class SaleModel {
  final String id;
  final List<CartItemModel> items;
  final double subtotal;        // total before checkout discount & tax
  final double checkoutDiscount; // additional discount applied at checkout (%)
  final double taxAmount;       // tax collected on this sale
  final double total;           // final total after all discounts & tax
  final double cash;
  final double change;
  final double discount;   // total discount amount (product discounts + checkout discount)
  final double profit;     // total profit for this sale
  final DateTime date;

  SaleModel({
    required this.id,
    required this.items,
    required this.subtotal,
    this.checkoutDiscount = 0,
    this.taxAmount = 0,
    required this.total,
    required this.cash,
    required this.change,
    this.discount = 0,
    this.profit = 0,
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
              'brand': e.product.brand,
              'price': e.product.price,
              'purchasePrice': e.product.purchasePrice,
              'discount': e.product.discount,
              'discountedPrice': e.product.discountedPrice,
              'qty': e.quantity,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'checkoutDiscount': checkoutDiscount,
      'taxAmount': taxAmount,
      'total': total,
      'cash': cash,
      'change': change,
      'discount': discount,
      'profit': profit,
      'date': date.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map data) {
    return SaleModel(
      id: data['id'],
      items: [], // you can rebuild later if needed
      subtotal: (data['subtotal'] ?? data['total'] ?? 0).toDouble(),
      checkoutDiscount: (data['checkoutDiscount'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      total: data['total'],
      cash: data['cash'],
      change: data['change'],
      discount: (data['discount'] ?? 0).toDouble(),
      profit: (data['profit'] ?? 0).toDouble(),
      date: DateTime.parse(data['date']),
    );
  }
}
