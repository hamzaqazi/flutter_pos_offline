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
  final String sku; // auto-generated or manual SKU/barcode

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
  });

  /// Selling price after applying discount percentage.
  double get discountedPrice {
    if (discount <= 0) return price;
    return price - (price * discount / 100);
  }

  /// Profit per unit (selling price after discount minus purchase price).
  double get profitPerUnit => discountedPrice - purchasePrice;

  /// Whether this product has a brand set.
  bool get hasBrand => brand.isNotEmpty;

  /// Whether this product has an SKU set.
  bool get hasSku => sku.isNotEmpty;

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
    );
  }
}
