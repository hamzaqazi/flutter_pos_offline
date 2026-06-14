/// Represents a staff member / cashier who can process sales.
class StaffModel {
  final String id;
  final String name;
  final String role; // e.g. "Cashier", "Manager", "Owner"
  final String phone;
  final DateTime createdAt;

  StaffModel({
    required this.id,
    required this.name,
    this.role = 'Cashier',
    this.phone = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasPhone => phone.isNotEmpty;

  StaffModel copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    DateTime? createdAt,
  }) {
    return StaffModel(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory StaffModel.fromMap(Map<dynamic, dynamic> map) {
    return StaffModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Cashier',
      phone: map['phone'] ?? '',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
