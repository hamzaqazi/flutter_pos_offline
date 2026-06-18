import 'dart:async';
import 'dart:ui';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

/// A custom product category with a name and color.
class CategoryModel {
  final String name;
  final Color color;

  CategoryModel({required this.name, required this.color});

  Map<String, dynamic> toMap() => {
        'name': name,
        'color': color.toARGB32(),
      };

  factory CategoryModel.fromMap(Map<dynamic, dynamic> map) {
    return CategoryModel(
      name: map['name'] ?? '',
      color: Color(map['color'] ?? AppColors.seed.toARGB32()),
    );
  }

  CategoryModel copyWith({String? name, Color? color}) =>
      CategoryModel(name: name ?? this.name, color: color ?? this.color);
}

/// Controller that manages custom product categories.
/// Stored in Hive box 'categories'. Provides reactive list for UI.
class CategoryController extends GetxController {
  static const _boxName = 'categories';
  static const _defaultCategories = [
    {'name': 'Watches', 'color': 0xFF6366F1},
    {'name': 'Caps', 'color': 0xFF0EA5E9},
    {'name': 'Perfumes', 'color': 0xFFEC4899},
    {'name': 'Glasses', 'color': 0xFF14B8A6},
  ];

  final categories = <CategoryModel>[].obs;

  @override
  void onInit() {
    loadCategories();
    super.onInit();
  }

  void loadCategories() {
    final box = Hive.box(_boxName);
    final data = box.get('items');

    if (data == null) {
      // First time: seed with defaults
      categories.assignAll(
        _defaultCategories.map((e) => CategoryModel(
              name: e['name'] as String,
              color: Color(e['color'] as int),
            )),
      );
      _saveToBox();
    } else {
      final list = data as List;
      categories.assignAll(
        list.map((e) => CategoryModel.fromMap(e as Map<dynamic, dynamic>)),
      );
    }
  }

  void _saveToBox() {
    final box = Hive.box(_boxName);
    box.put('items', categories.map((c) => c.toMap()).toList());
  }

  /// Add a new category. Returns false if name already exists.
  bool addCategory(String name, Color color) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (categories.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }
    categories.add(CategoryModel(name: trimmed, color: color));
    _saveToBox();
    return true;
  }

  /// Update an existing category. Returns false if new name conflicts.
  bool updateCategory(String oldName, String newName, Color newColor) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;
    // Allow same name (color change only) or unique name
    if (trimmed.toLowerCase() != oldName.toLowerCase() &&
        categories.any((c) => c.name.toLowerCase() == trimmed.toLowerCase())) {
      return false;
    }
    final index = categories.indexWhere((c) => c.name == oldName);
    if (index == -1) return false;
    categories[index] = CategoryModel(name: trimmed, color: newColor);
    _saveToBox();
    return true;
  }

  /// Delete a category. Returns false if products still use it.
  bool deleteCategory(String name) {
    categories.removeWhere((c) => c.name == name);
    _saveToBox();
    return true;
  }

  /// Get color for a category name, with fallback.
  Color colorFor(String name) {
    try {
      return categories.firstWhere((c) => c.name == name).color;
    } catch (_) {
      return AppColors.seed;
    }
  }

  /// Get list of category names.
  List<String> get categoryNames => categories.map((c) => c.name).toList();

  /// Generate an auto SKU prefix from category name.
  String skuPrefix(String category) {
    if (category.isEmpty) return 'X';
    // Take first letter uppercase
    return category[0].toUpperCase();
  }
}
