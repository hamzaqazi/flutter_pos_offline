/// Represents a customer who can be linked to sales.
class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasPhone => phone.isNotEmpty;
  bool get hasEmail => email.isNotEmpty;
  bool get hasAddress => address.isNotEmpty;

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomerModel.fromMap(Map<dynamic, dynamic> map) {
    return CustomerModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
