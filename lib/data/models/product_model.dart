class ProductModel {
  final String id;
  final String name;
  final String category;
  final double price;
  final int stock;
  final String? image;

  ProductModel({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    this.image,
  });

  ProductModel copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    int? stock,
    String? image,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      image: image ?? this.image,
    );
  }
}
