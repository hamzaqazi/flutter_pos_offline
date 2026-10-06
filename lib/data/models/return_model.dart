import 'cart_item_model.dart';

/// Represents a return/refund for one or more items from a completed sale.
class ReturnModel {
  final String id;
  final String saleId; // the original sale ID
  final List<ReturnItemModel> items;
  final double refundAmount; // total money returned
  final double refundProfit; // profit reversed (deducted)
  final String reason; // optional reason for the return
  final DateTime date;

  ReturnModel({
    required this.id,
    required this.saleId,
    required this.items,
    required this.refundAmount,
    required this.refundProfit,
    this.reason = '',
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'items': items.map((e) => e.toMap()).toList(),
      'refundAmount': refundAmount,
      'refundProfit': refundProfit,
      'reason': reason,
      'date': date.toIso8601String(),
    };
  }

  factory ReturnModel.fromMap(Map<dynamic, dynamic> data) {
    final rawItems = (data['items'] as List?) ?? [];
    return ReturnModel(
      id: data['id'] ?? '',
      saleId: data['saleId'] ?? '',
      items: rawItems.map((e) => ReturnItemModel.fromMap(e)).toList(),
      refundAmount: (data['refundAmount'] ?? 0).toDouble(),
      refundProfit: (data['refundProfit'] ?? 0).toDouble(),
      reason: data['reason'] ?? '',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
    );
  }
}

/// A single item being returned from a sale.
class ReturnItemModel {
  final String productId;
  final String name;
  final String brand;
  final double price;          // original selling price
  final double purchasePrice;  // cost price
  final double discount;       // discount % on the product
  final int originalQty;       // qty in original sale
  final int returnQty;         // qty being returned now

  /// What the customer is refunded per unit. This is the price they actually
  /// paid — the line price after the product discount, scaled for any
  /// checkout discount and tax on the original sale — not the list price.
  final double refundPerUnit;

  /// Profit reversed per unit: the pre-tax margin less that unit's share of
  /// any checkout discount.
  final double profitPerUnit;

  ReturnItemModel({
    required this.productId,
    required this.name,
    this.brand = '',
    required this.price,
    this.purchasePrice = 0,
    this.discount = 0,
    required this.originalQty,
    required this.returnQty,
    required this.refundPerUnit,
    double? profitPerUnit,
  }) : profitPerUnit =
           profitPerUnit ?? (refundPerUnit - purchasePrice);

  /// Total refund for this line = returnQty × refundPerUnit
  double get totalRefund => returnQty * refundPerUnit;

  /// Profit reversed for this line = returnQty × profitPerUnit
  double get profitReversed => returnQty * profitPerUnit;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'brand': brand,
      'price': price,
      'purchasePrice': purchasePrice,
      'discount': discount,
      'originalQty': originalQty,
      'returnQty': returnQty,
      'refundPerUnit': refundPerUnit,
      'profitPerUnit': profitPerUnit,
    };
  }

  factory ReturnItemModel.fromMap(Map<dynamic, dynamic> data) {
    return ReturnItemModel(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      purchasePrice: (data['purchasePrice'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      originalQty: data['originalQty'] ?? 1,
      returnQty: data['returnQty'] ?? 1,
      refundPerUnit: (data['refundPerUnit'] ?? 0).toDouble(),
      // Returns recorded before profit per unit was tracked fall back to the
      // old derivation so historical records still load.
      profitPerUnit: data['profitPerUnit'] != null
          ? (data['profitPerUnit'] as num).toDouble()
          : null,
    );
  }

  /// Create from a CartItemModel (sale item).
  ///
  /// [refundPerUnit] and [profitPerUnit] should be the values from
  /// `OrderTotals.returnAllocation`, which knows what the customer actually
  /// paid. They default to the line price for callers with no checkout-level
  /// adjustment to account for.
  factory ReturnItemModel.fromCartItem(
    CartItemModel item, {
    int returnQty = 0,
    double? refundPerUnit,
    double? profitPerUnit,
  }) {
    return ReturnItemModel(
      productId: item.product.id,
      name: item.product.name,
      brand: item.product.brand,
      price: item.product.price,
      purchasePrice: item.product.purchasePrice,
      discount: item.product.discount,
      originalQty: item.quantity,
      returnQty: returnQty,
      refundPerUnit: refundPerUnit ?? item.product.discountedPrice,
      profitPerUnit: profitPerUnit,
    );
  }
}
