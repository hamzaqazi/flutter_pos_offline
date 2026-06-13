class ShopSettingsModel {
  final String shopName;
  final String address;
  final String phone;
  final String receiptFooter;
  final String currencySymbol;
  final double taxRate;           // Tax percentage (e.g. 16.0 for 16%)
  final bool taxInclusive;        // true = price includes tax, false = tax added on top

  ShopSettingsModel({
    this.shopName = 'My Shop',
    this.address = '',
    this.phone = '',
    this.receiptFooter = 'Thank you for shopping!',
    this.currencySymbol = 'Rs',
    this.taxRate = 0,
    this.taxInclusive = false,
  });

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'address': address,
        'phone': phone,
        'receiptFooter': receiptFooter,
        'currencySymbol': currencySymbol,
        'taxRate': taxRate,
        'taxInclusive': taxInclusive,
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
  }) {
    return ShopSettingsModel(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
    );
  }
}
