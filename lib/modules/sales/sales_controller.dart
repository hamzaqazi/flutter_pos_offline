import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../data/models/sale_model.dart';
import '../../data/services/hive_service.dart';
import '../cart/cart_controller.dart';
import '../products/products_controller.dart';
import '../customers/customers_controller.dart';

class SalesController extends GetxController {
  final sales = <SaleModel>[].obs;

  // Search & filter state
  final searchQuery = ''.obs;
  final dateFilter = 'All'.obs; // 'All', 'Today', 'This Week', 'This Month', 'Custom'
  DateTime? customStartDate;
  DateTime? customEndDate;

  @override
  void onInit() {
    loadSales();
    super.onInit();
  }

  void loadSales() {
    final data = HiveService.salesBox.values.toList();

    final productsController = Get.find<ProductsController>();

    sales.assignAll(
      data.map((e) {
        final rawItems = (e['items'] as List?) ?? [];

        final items = rawItems.map((item) {
          String category = item['category'] ?? '';
          if (category.isEmpty && (item['productId'] ?? '').isNotEmpty) {
            final product = productsController.products.firstWhereOrNull(
              (p) => p.id == item['productId'],
            );
            if (product != null) category = product.category;
          }

          return CartItemModel(
            product: ProductModel(
              id: item['productId'] ?? '',
              name: item['name'] ?? '',
              brand: item['brand'] ?? '',
              sku: item['sku'] ?? '',
              barcode: item['barcode'] ?? '',
              price: (item['price'] ?? 0).toDouble(),
              purchasePrice: (item['purchasePrice'] ?? 0).toDouble(),
              discount: (item['discount'] ?? 0).toDouble(),
              category: category,
              stock: 0,
            ),
            quantity: item['qty'] ?? 1,
          );
        }).toList();

        return SaleModel(
          id: e['id'] ?? '',
          invoiceNumber: e['invoiceNumber'] ?? '',
          items: items,
          subtotal: (e['subtotal'] ?? e['total'] ?? 0).toDouble(),
          checkoutDiscount: (e['checkoutDiscount'] ?? 0).toDouble(),
          taxAmount: (e['taxAmount'] ?? 0).toDouble(),
          total: (e['total'] ?? 0).toDouble(),
          cash: (e['cash'] ?? 0).toDouble(),
          change: (e['change'] ?? 0).toDouble(),
          discount: (e['discount'] ?? 0).toDouble(),
          profit: (e['profit'] ?? 0).toDouble(),
          customerId: e['customerId'] ?? '',
          cashierId: e['cashierId'] ?? '',
          date: DateTime.tryParse(e['date'] ?? '') ?? DateTime.now(),
        );
      }).toList(),
  }

  /// Get the next invoice number (auto-incrementing, persisted in Hive).
  /// Format: "INV-0001", "INV-0002", etc.
  String _getNextInvoiceNumber() {
    final box = Hive.box('settings');
    int lastNum = box.get('lastInvoiceNumber', defaultValue: 0) as int;
    lastNum++;
    box.put('lastInvoiceNumber', lastNum);
    return 'INV-${lastNum.toString().padLeft(4, '0')}';
  }

  /// Peek at the next invoice number without incrementing.
  /// Used for preview before sale is completed.
  String peekNextInvoiceNumber() {
    final box = Hive.box('settings');
    int lastNum = box.get('lastInvoiceNumber', defaultValue: 0) as int;
    final nextNum = lastNum + 1;
    return 'INV-${nextNum.toString().padLeft(4, '0')}';
  }

  void completeSale({
    required double cash,
    required double change,
    double checkoutDiscount = 0,
    double taxAmount = 0,
    String customerId = '',
    String cashierId = '',
    String invoiceNumber = '',
  }) {
    final cart = Get.find<CartController>();
    final products = Get.find<ProductsController>();

    if (cart.cartItems.isEmpty) return;

    final saleId = DateTime.now().microsecondsSinceEpoch.toString();

    final subtotal = cart.subtotalAmount;
    final checkoutDiscountAmount = subtotal * checkoutDiscount / 100;
    final grandTotal = cart.totalAmount - checkoutDiscountAmount;

    final productSavings = cart.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.savings,
    );

    final totalDiscount = productSavings + checkoutDiscountAmount;
    final totalProfit = cart.totalProfit - checkoutDiscountAmount;

    // Generate invoice number if not provided
    final invNum = invoiceNumber.isNotEmpty
        ? invoiceNumber
        : _getNextInvoiceNumber();

    final sale = SaleModel(
      id: saleId,
      invoiceNumber: invNum,
      items: List.from(cart.cartItems),
      subtotal: subtotal,
      checkoutDiscount: checkoutDiscount,
      taxAmount: taxAmount,
      total: grandTotal,
      cash: cash,
      change: change,
      discount: totalDiscount,
      profit: totalProfit,
      customerId: customerId,
      cashierId: cashierId,
      date: DateTime.now(),
    );

    // reduce stock
    for (final item in cart.cartItems) {
      final newStock = item.product.stock - item.quantity;
      products.updateStock(item.product.id, newStock);
    }

    // SAVE FULL INVOICE (IMPORTANT)
    HiveService.salesBox.put(saleId, {
      'id': sale.id,
      'invoiceNumber': sale.invoiceNumber,
      'items': sale.items
          .map(
            (e) => {
              'productId': e.product.id,
              'name': e.product.name,
              'brand': e.product.brand,
              'sku': e.product.sku,
              'barcode': e.product.barcode,
              'price': e.product.price,
              'purchasePrice': e.product.purchasePrice,
              'discount': e.product.discount,
              'discountedPrice': e.product.discountedPrice,
              'qty': e.quantity,
              'category': e.product.category,
            },
          )
          .toList(),
      'subtotal': sale.subtotal,
      'checkoutDiscount': sale.checkoutDiscount,
      'taxAmount': sale.taxAmount,
      'total': sale.total,
      'cash': sale.cash,
      'change': sale.change,
      'discount': sale.discount,
      'profit': sale.profit,
      'customerId': sale.customerId,
      'cashierId': sale.cashierId,
      'date': sale.date.toIso8601String(),
    });

    sales.add(sale);
    cart.clearCart();

    Get.snackbar("Success", "Sale completed — $invNum");
  }

  /// Filtered sales based on search query and date filter.
  List<SaleModel> get filteredSales {
    var result = sales.reversed.toList();

    // Date filter
    final now = DateTime.now();
    switch (dateFilter.value) {
      case 'Today':
        result = result.where((s) =>
          s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
        ).toList();
        break;
      case 'This Week':
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
        result = result.where((s) => s.date.isAfter(start) || s.date.isAtSameMomentAs(start)).toList();
        break;
      case 'This Month':
        result = result.where((s) =>
          s.date.year == now.year && s.date.month == now.month
        ).toList();
        break;
      case 'Custom':
        if (customStartDate != null) {
          final start = DateTime(customStartDate!.year, customStartDate!.month, customStartDate!.day);
          result = result.where((s) => s.date.isAfter(start) || s.date.isAtSameMomentAs(start)).toList();
        }
        if (customEndDate != null) {
          final end = DateTime(customEndDate!.year, customEndDate!.month, customEndDate!.day, 23, 59, 59);
          result = result.where((s) => s.date.isBefore(end) || s.date.isAtSameMomentAs(end)).toList();
        }
        break;
    }

    // Search filter (invoice number, customer name, item name)
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      final customersController = Get.tryFind<CustomersController>();
      result = result.where((s) {
        if (s.invoiceNumber.toLowerCase().contains(query)) return true;
        if (s.hasCustomer && customersController != null) {
          final customer = customersController.findById(s.customerId);
          if (customer != null && customer.name.toLowerCase().contains(query)) return true;
        }
        // Search by item name
        for (final item in s.items) {
          if (item.product.name.toLowerCase().contains(query)) return true;
        }
        return false;
      }).toList();
    }

    return result;
  }

  void clearFilters() {
    searchQuery.value = '';
    dateFilter.value = 'All';
    customStartDate = null;
    customEndDate = null;
  }
}
