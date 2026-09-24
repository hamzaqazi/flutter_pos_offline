import 'package:ad_shop_pos/data/models/cart_item_model.dart';

class SaleModel {
  final String id;
  final String invoiceNumber; // e.g. "INV-0001"
  final List<CartItemModel> items;
  final double subtotal;

  /// The checkout discount. Normally an absolute amount in the shop's
  /// currency — read it through [checkoutDiscountAmount], which also handles
  /// older records that stored a percentage here.
  final double checkoutDiscount;

  /// True only for sales recorded back when a checkout discount was entered as
  /// a percentage. New sales always store an amount, so this is false
  /// everywhere going forward; it exists so historical records are still read
  /// with the meaning they were written with.
  final bool checkoutDiscountIsPercent;

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
    this.invoiceNumber = '',
    required this.items,
    required this.subtotal,
    this.checkoutDiscount = 0,
    this.checkoutDiscountIsPercent = false,
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

  /// The checkout discount as money, whichever way the record stored it.
  double get checkoutDiscountAmount => checkoutDiscountIsPercent
      ? subtotal * checkoutDiscount / 100
      : checkoutDiscount;

  bool get hasCustomer => customerId.isNotEmpty;
  bool get hasCashier => cashierId.isNotEmpty;
  bool get hasInvoiceNumber => invoiceNumber.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'items': items
          .map(
            (e) => {
              'productId': e.product.id,
              'name': e.product.name,
              'brand': e.product.brand,
              'sku': e.product.sku,
              'barcode': e.product.barcode,
              'price': e.product.price,
              'purchasePrice': e.product.purchasePrice,
              'discount': e.product.discount,
              'discountedPrice': e.product.discountedPrice,
              'qty': e.quantity,
              'category': e.product.category,
            },
          )
          .toList(),
      'subtotal': subtotal,
      'checkoutDiscount': checkoutDiscount,
      // Marks the meaning of the field above and is always written, so a
      // backup/restore round-trip keeps it. A *missing* key is what identifies
      // records written before checkout discounts became fixed amounts.
      'checkoutDiscountIsPercent': checkoutDiscountIsPercent,
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
      invoiceNumber: data['invoiceNumber'] ?? '',
      items: [],
      subtotal: (data['subtotal'] ?? data['total'] ?? 0).toDouble(),
      checkoutDiscount: (data['checkoutDiscount'] ?? 0).toDouble(),
      // Legacy records have no flag and stored a percentage; everything
      // written from now on stores an amount.
      checkoutDiscountIsPercent: data['checkoutDiscountIsPercent'] ?? true,
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
