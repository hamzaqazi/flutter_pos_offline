class ExpenseModel {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;

  ExpenseModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'category': category,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory ExpenseModel.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseModel(
      id: map['id'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
    );
  }

  static const categories = [
    'Rent',
    'Salary',
    'Utilities',
    'Maintenance',
    'Supplies',
    'Transport',
    'Marketing',
    'Other',
  ];
}
