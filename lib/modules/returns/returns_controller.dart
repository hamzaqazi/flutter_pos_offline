import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/data/services/hive_service.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class ReturnsController extends GetxController {
  final returns = <ReturnModel>[].obs;

  @override
  void onInit() {
    loadReturns();
    super.onInit();
  }

  void loadReturns() {
    final data = HiveService.returnsBox.values.toList();
    returns.assignAll(
      data.map((e) => ReturnModel.fromMap(Map<dynamic, dynamic>.from(e))),
    );
  }

  /// Process a return/refund for a given sale.
  /// [saleId] - the original sale ID
  /// [returnItems] - list of ReturnItemModel with returnQty set
  /// [reason] - optional reason
  void processReturn({
    required String saleId,
    required List<ReturnItemModel> returnItems,
    String reason = '',
  }) {
    if (returnItems.isEmpty || returnItems.every((i) => i.returnQty <= 0)) {
      Get.snackbar("No items", "Select at least one item to return");
      return;
    }

    // Filter out items with 0 return qty
    final validItems = returnItems.where((i) => i.returnQty > 0).toList();

    final returnId = DateTime.now().microsecondsSinceEpoch.toString();

    final totalRefund = validItems.fold<double>(
      0,
      (sum, item) => sum + item.totalRefund,
    );
    final totalProfitReversed = validItems.fold<double>(
      0,
      (sum, item) => sum + item.profitReversed,
    );

    final returnRecord = ReturnModel(
      id: returnId,
      saleId: saleId,
      items: validItems,
      refundAmount: totalRefund,
      refundProfit: totalProfitReversed,
      reason: reason,
      date: DateTime.now(),
    );

    // Save to Hive
    HiveService.returnsBox.put(returnId, returnRecord.toMap());
    returns.add(returnRecord);

    // Auto-restock returned items
    final productsController = Get.find<ProductsController>();
    for (final item in validItems) {
      final product = productsController.products.firstWhereOrNull(
        (p) => p.id == item.productId,
      );
      if (product != null) {
        productsController.updateStock(
          product.id,
          product.stock + item.returnQty,
        );
      }
    }

    Get.snackbar(
      "Return processed",
      "Refund: ${_fmtCurrency(totalRefund)} • ${validItems.fold<int>(0, (s, i) => s + i.returnQty)} item(s) restocked",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  /// Delete a return record (does NOT undo the restock).
  void deleteReturn(String id) {
    returns.removeWhere((r) => r.id == id);
    HiveService.returnsBox.delete(id);
  }

  /// Returns for a specific sale.
  List<ReturnModel> returnsForSale(String saleId) {
    return returns.where((r) => r.saleId == saleId).toList();
  }

  /// Total refund amount across all returns.
  double get totalRefunds =>
      returns.fold(0, (sum, r) => sum + r.refundAmount);

  /// Total profit reversed across all returns.
  double get totalProfitReversed =>
      returns.fold(0, (sum, r) => sum + r.refundProfit);

  /// Total refunds in a date range.
  double totalRefundsInRange(DateTime start, DateTime end) {
    return returns
        .where((r) =>
            r.date.isAfter(start) && r.date.isBefore(end.add(const Duration(days: 1))))
        .fold(0, (sum, r) => sum + r.refundAmount);
  }

  /// Total profit reversed in a date range.
  double totalProfitReversedInRange(DateTime start, DateTime end) {
    return returns
        .where((r) =>
            r.date.isAfter(start) && r.date.isBefore(end.add(const Duration(days: 1))))
        .fold(0, (sum, r) => sum + r.refundProfit);
  }

  /// Number of return transactions in a date range.
  int returnCountInRange(DateTime start, DateTime end) {
    return returns
        .where((r) =>
            r.date.isAfter(start) && r.date.isBefore(end.add(const Duration(days: 1))))
        .length;
  }

  /// Check how many units of a product have already been returned from a sale.
  int alreadyReturnedQty(String saleId, String productId) {
    final saleReturns = returnsForSale(saleId);
    int total = 0;
    for (final ret in saleReturns) {
      for (final item in ret.items) {
        if (item.productId == productId) {
          total += item.returnQty;
        }
      }
    }
    return total;
  }

  String _fmtCurrency(double value) {
    final rounded = value.round().abs();
    final sign = value < 0 ? '-' : '';
    String symbol = 'Rs';
    try {
      final box = Hive.box('settings');
      final data = box.get('shop');
      if (data != null && data['currencySymbol'] != null) {
        symbol = data['currencySymbol'];
      }
    } catch (_) {}
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$symbol $sign$buffer';
  }
}
