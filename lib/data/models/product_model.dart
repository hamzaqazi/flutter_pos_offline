class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double purchasePrice;
  final double discount;
  final int stock;
  final String? image;
  final String sku; // internal SKU code (e.g. W0001, P0002)
  final String barcode; // real-world barcode from product packaging (EAN, UPC, etc.)

  ProductModel({
    required this.id,
    required this.name,
    this.brand = '',
    required this.category,
    required this.price,
    this.purchasePrice = 0,
    this.discount = 0,
    required this.stock,
    this.image,
    this.sku = '',
    this.barcode = '',
  });

  /// Anything closer together than this counts as the same amount of money, so
  /// a rounding artefact cannot turn a break-even price into a reported loss —
  /// the same tolerance the currency formatter uses to decide a value is whole.
  static const double _moneyTolerance = 0.005;

  /// Selling price after a discount of [discountPercent] applied to [price].
  static double discountedPriceFor(double price, double discountPercent) {
    if (discountPercent <= 0) return price;
    return price - (price * discountPercent / 100);
  }

  /// The money lost on a single unit sold at [price] after [discountPercent]
  /// off, given what it cost.
  ///
  /// Zero when the unit still sells at or above cost — including when the
  /// purchase price is unknown (0), which must never read as a loss.
  static double lossFor({
    required double price,
    required double purchasePrice,
    required double discountPercent,
  }) {
    final profit = discountedPriceFor(price, discountPercent) - purchasePrice;
    return profit < -_moneyTolerance ? -profit : 0;
  }

  /// Selling price after applying discount percentage.
  double get discountedPrice => discountedPriceFor(price, discount);

  /// Profit per unit (selling price after discount minus purchase price).
  double get profitPerUnit => discountedPrice - purchasePrice;

  /// Money lost per unit at this price and discount; 0 when it still sells at
  /// or above cost.
  double get lossPerUnit => lossFor(
    price: price,
    purchasePrice: purchasePrice,
    discountPercent: discount,
  );

  /// Whether this price and discount sell the item at a loss.
  bool get sellsBelowCost => lossPerUnit > 0;

  /// Whether this product has a brand set.
  bool get hasBrand => brand.isNotEmpty;

  /// Whether this product has an SKU set.
  bool get hasSku => sku.isNotEmpty;

  /// Whether this product has a barcode set (real-world barcode for scanning).
  bool get hasBarcode => barcode.isNotEmpty;

  /// Whether this product has a photo set.
  bool get hasImage => image != null && image!.isNotEmpty;

  /// Returns a copy with [image] explicitly set (allows clearing to null,
  /// which [copyWith] cannot do).
  ProductModel withImage(String? image) {
    return ProductModel(
      id: id,
      name: name,
      brand: brand,
      category: category,
      price: price,
      purchasePrice: purchasePrice,
      discount: discount,
      stock: stock,
      image: image,
      sku: sku,
      barcode: barcode,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    double? price,
    double? purchasePrice,
    double? discount,
    int? stock,
    String? image,
    String? sku,
    String? barcode,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      price: price ?? this.price,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      discount: discount ?? this.discount,
      stock: stock ?? this.stock,
      image: image ?? this.image,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
    );
  }
}
