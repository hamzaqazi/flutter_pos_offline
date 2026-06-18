class ShopSettingsModel {
  final String shopName;
  final String address;
  final String phone;
  final String receiptFooter;
  final String currencySymbol;
  final double taxRate;           // Tax percentage (e.g. 16.0 for 16%)
  final bool taxInclusive;        // true = price includes tax, false = tax added on top
  final int lowStockThreshold;    // Alert when stock <= this value (default 5)

  ShopSettingsModel({
    this.shopName = 'My Shop',
    this.address = '',
    this.phone = '',
    this.receiptFooter = 'Thank you for shopping!',
    this.currencySymbol = 'Rs',
    this.taxRate = 0,
    this.taxInclusive = false,
    this.lowStockThreshold = 5,
  });

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'address': address,
        'phone': phone,
        'receiptFooter': receiptFooter,
        'currencySymbol': currencySymbol,
        'taxRate': taxRate,
        'taxInclusive': taxInclusive,
        'lowStockThreshold': lowStockThreshold,
      };

  factory ShopSettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return ShopSettingsModel(
      shopName: map['shopName'] ?? 'My Shop',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      receiptFooter: map['receiptFooter'] ?? 'Thank you for shopping!',
      currencySymbol: map['currencySymbol'] ?? 'Rs',
      taxRate: (map['taxRate'] ?? 0).toDouble(),
      taxInclusive: map['taxInclusive'] ?? false,
      lowStockThreshold: map['lowStockThreshold'] ?? 5,
    );
  }

  ShopSettingsModel copyWith({
    String? shopName,
    String? address,
    String? phone,
    String? receiptFooter,
    String? currencySymbol,
    double? taxRate,
    bool? taxInclusive,
    int? lowStockThreshold,
  }) {
    return ShopSettingsModel(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
    );
  }
}
