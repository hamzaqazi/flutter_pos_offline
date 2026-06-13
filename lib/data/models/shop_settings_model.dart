class ShopSettingsModel {
  final String shopName;
  final String address;
  final String phone;
  final String receiptFooter;
  final String currencySymbol;

  ShopSettingsModel({
    this.shopName = 'My Shop',
    this.address = '',
    this.phone = '',
    this.receiptFooter = 'Thank you for shopping!',
    this.currencySymbol = 'Rs',
  });

  Map<String, dynamic> toMap() => {
        'shopName': shopName,
        'address': address,
        'phone': phone,
        'receiptFooter': receiptFooter,
        'currencySymbol': currencySymbol,
      };

  factory ShopSettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return ShopSettingsModel(
      shopName: map['shopName'] ?? 'My Shop',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      receiptFooter: map['receiptFooter'] ?? 'Thank you for shopping!',
      currencySymbol: map['currencySymbol'] ?? 'Rs',
    );
  }

  ShopSettingsModel copyWith({
    String? shopName,
    String? address,
    String? phone,
    String? receiptFooter,
    String? currencySymbol,
  }) {
    return ShopSettingsModel(
      shopName: shopName ?? this.shopName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }
}
