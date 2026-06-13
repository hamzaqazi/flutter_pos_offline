import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import '../../data/models/sale_model.dart';
import '../products/products_controller.dart';
import '../sales/sales_controller.dart';

class ReportsController extends GetxController {
  final ProductsController _productsController = Get.find();
  final SalesController _salesController = Get.find();

  // Date range filter
  final startDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final endDate = DateTime.now().obs;

  void setToday() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, now.day);
    endDate.value = now;
  }

  void setThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    startDate.value = DateTime(weekStart.year, weekStart.month, weekStart.day);
    endDate.value = now;
  }

  void setThisMonth() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = now;
  }

  void setLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    startDate.value = DateTime(lastMonth.year, lastMonth.month, 1);
    endDate.value = DateTime(now.year, now.month, 0, 23, 59, 59);
  }

  void setAllTime() {
    startDate.value = DateTime(2000, 1, 1);
    endDate.value = DateTime.now();
  }

  /// Sales filtered by date range.
  List<SaleModel> get filteredSales {
    return _salesController.sales.where((sale) {
      return sale.date.isAfter(startDate.value) &&
          sale.date.isBefore(endDate.value.add(const Duration(days: 1)));
    }).toList();
  }

  // =================== Sales Summary ===================

  double get totalRevenue =>
      filteredSales.fold(0, (sum, s) => sum + s.total);

  double get totalProfit =>
      filteredSales.fold(0, (sum, s) => sum + s.profit);

  double get totalDiscount =>
      filteredSales.fold(0, (sum, s) => sum + s.discount);

  double get totalCOGS =>
      filteredSales.fold(0, (sum, s) {
        return sum + s.items.fold(0, (itemSum, item) {
          return itemSum + (item.product.purchasePrice * item.quantity);
        });
      });

  int get totalTransactions => filteredSales.length;

  int get totalItemsSold =>
      filteredSales.fold(0, (sum, s) {
        return sum + s.items.fold(0, (itemSum, item) => itemSum + item.quantity);
      });

  double get averageTransaction =>
      totalTransactions > 0 ? totalRevenue / totalTransactions : 0;

  double get margin =>
      totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0;

  // =================== Top Products ===================

  Map<String, _ProductSalesData> get _productSalesMap {
    final map = <String, _ProductSalesData>{};
    for (final sale in filteredSales) {
      for (final item in sale.items) {
        final key = '${item.product.name}|${item.product.category}';
        if (map.containsKey(key)) {
          map[key]!.quantity += item.quantity;
          map[key]!.revenue += item.total;
          map[key]!.profit += item.profit;
        } else {
          map[key] = _ProductSalesData(
            name: item.product.name,
            category: item.product.category,
            quantity: item.quantity,
            revenue: item.total,
            profit: item.profit,
          );
        }
      }
    }
    return map;
  }

  List<_ProductSalesData> get topProductsByQuantity {
    final list = _productSalesMap.values.toList();
    list.sort((a, b) => b.quantity.compareTo(a.quantity));
    return list;
  }

  List<_ProductSalesData> get topProductsByRevenue {
    final list = _productSalesMap.values.toList();
    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }

  // =================== Category Breakdown ===================

  Map<String, _CategoryData> get categoryBreakdown {
    final map = <String, _CategoryData>{};
    for (final sale in filteredSales) {
      for (final item in sale.items) {
        final cat = item.product.category.isEmpty ? 'Other' : item.product.category;
        if (map.containsKey(cat)) {
          map[cat]!.quantity += item.quantity;
          map[cat]!.revenue += item.total;
          map[cat]!.profit += item.profit;
        } else {
          map[cat] = _CategoryData(
            category: cat,
            quantity: item.quantity,
            revenue: item.total,
            profit: item.profit,
          );
        }
      }
    }
    return map;
  }

  List<_CategoryData> get categoryBreakdownList {
    final list = categoryBreakdown.values.toList();
    list.sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }

  // =================== Inventory Valuation ===================

  double get inventoryRetailValue {
    return _productsController.products.fold(
      0,
      (sum, p) => sum + (p.discountedPrice * p.stock),
    );
  }

  double get inventoryCostValue {
    return _productsController.products.fold(
      0,
      (sum, p) => sum + (p.purchasePrice * p.stock),
    );
  }

  double get inventoryPotentialProfit {
    return inventoryRetailValue - inventoryCostValue;
  }

  int get totalStockUnits {
    return _productsController.products.fold(0, (sum, p) => sum + p.stock);
  }

  List<ProductModel> get lowStockProducts {
    final list = _productsController.products.where((p) => p.stock <= 5).toList();
    list.sort((a, b) => a.stock.compareTo(b.stock));
    return list;
  }

  List<ProductModel> get outOfStockProducts {
    return _productsController.products.where((p) => p.stock <= 0).toList();
  }

  // =================== Daily Sales (for chart) ===================

  Map<String, double> get dailyRevenue {
    final map = <String, double>{};
    for (final sale in filteredSales) {
      final key =
          '${sale.date.year}-${sale.date.month.toString().padLeft(2, '0')}-${sale.date.day.toString().padLeft(2, '0')}';
      map[key] = (map[key] ?? 0) + sale.total;
    }
    return map;
  }
}

class _ProductSalesData {
  final String name;
  final String category;
  int quantity;
  double revenue;
  double profit;

  _ProductSalesData({
    required this.name,
    required this.category,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
}

class _CategoryData {
  final String category;
  int quantity;
  double revenue;
  double profit;

  _CategoryData({
    required this.category,
    required this.quantity,
    required this.revenue,
    required this.profit,
  });
}
