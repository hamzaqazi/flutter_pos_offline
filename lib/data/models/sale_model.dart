import 'package:ad_shop_pos/data/models/cart_item_model.dart';

class SaleModel {
  final String id;
  final List<CartItemModel> items;
  final double subtotal;
  final double checkoutDiscount;
  final double taxAmount;
  final double total;
  final double cash;
  final double change;
  final double discount;
  final double profit;
  final String customerId;
  final String cashierId; // staff member who processed this sale
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
    this.customerId = '',
    this.cashierId = '',
    required this.date,
  });

  bool get hasCustomer => customerId.isNotEmpty;
  bool get hasCashier => cashierId.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items
          .map(
            (e) => {
              'productId': e.product.id,
              'name': e.product.name,
              'brand': e.product.brand,
              'sku': e.product.sku,
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
      'customerId': customerId,
      'cashierId': cashierId,
      'date': date.toIso8601String(),
    };
  }

  factory SaleModel.fromMap(Map data) {
    return SaleModel(
      id: data['id'],
      items: [],
      subtotal: (data['subtotal'] ?? data['total'] ?? 0).toDouble(),
      checkoutDiscount: (data['checkoutDiscount'] ?? 0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0).toDouble(),
      total: data['total'],
      cash: data['cash'],
      change: data['change'],
      discount: (data['discount'] ?? 0).toDouble(),
      profit: (data['profit'] ?? 0).toDouble(),
      customerId: data['customerId'] ?? '',
      cashierId: data['cashierId'] ?? '',
      date: DateTime.parse(data['date']),
    );
  }
}
