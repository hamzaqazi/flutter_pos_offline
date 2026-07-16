import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final ProductsController productsController = Get.find();
  final SalesController salesController = Get.find();
  final ReturnsController returnsController = Get.find();
  final ExpensesController expensesController = Get.find();

  // All-time stats
  RxInt totalProducts = 0.obs;
  RxInt totalSales = 0.obs;
  RxDouble totalRevenue = 0.0.obs;
  RxDouble totalGrossProfit = 0.0.obs;  // Revenue - COGS
  RxDouble totalProfit = 0.0.obs;        // Gross profit - returns
  RxDouble totalNetProfit = 0.0.obs;     // Gross profit - returns - expenses
  RxInt lowStockCount = 0.obs;
  RxDouble totalRefunds = 0.0.obs;
  RxInt totalReturnCount = 0.obs;
  RxDouble totalExpenses = 0.0.obs;

  // Today's stats
  RxInt todaySales = 0.obs;
  RxDouble todayRevenue = 0.0.obs;
  RxDouble todayGrossProfit = 0.0.obs;
  RxDouble todayProfit = 0.0.obs;       // After returns
  RxDouble todayExpenses = 0.0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(productsController.products, (_) => _recalcProducts());
    ever(salesController.sales, (_) => _recalcSales());
    ever(returnsController.returns, (_) => _recalcSales());
    ever(expensesController.expenses, (_) => _recalcSales());

    _recalcProducts();
    _recalcSales();
  }

  void _recalcProducts() {
    totalProducts.value = productsController.products.length;
    final threshold = SettingsService.getSettings().lowStockThreshold;
    lowStockCount.value =
        productsController.products.where((p) => p.stock <= threshold).length;
  }

  void _recalcSales() {
    // All-time stats
    totalSales.value = salesController.sales.length;
    totalRevenue.value = salesController.sales.fold<double>(
      0,
      (sum, sale) => sum + sale.total,
    );
    totalGrossProfit.value = salesController.sales.fold<double>(
      0,
      (sum, sale) => sum + sale.profit,
    );
    totalRefunds.value = returnsController.totalRefunds;
    totalReturnCount.value = returnsController.returns.length;
    totalExpenses.value = expensesController.expenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    // Profit after returns
    totalProfit.value = totalGrossProfit.value - returnsController.totalProfitReversed;
    // Net profit after returns + expenses
    totalNetProfit.value = totalProfit.value - totalExpenses.value;

    // Today's stats
    final now = DateTime.now();
    final todaySalesList = salesController.sales.where((s) =>
      s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
    ).toList();
    todaySales.value = todaySalesList.length;
    todayRevenue.value = todaySalesList.fold<double>(0, (sum, s) => sum + s.total);
    todayGrossProfit.value = todaySalesList.fold<double>(0, (sum, s) => sum + s.profit);

    // Today's returns
    final todayReturnsProfitReversed = returnsController.returns
        .where((r) =>
            r.date.year == now.year &&
            r.date.month == now.month &&
            r.date.day == now.day)
        .fold<double>(0, (sum, r) => sum + r.refundProfit);
    todayProfit.value = todayGrossProfit.value - todayReturnsProfitReversed;

    // Today's expenses
    todayExpenses.value = expensesController.expenses
        .where((e) =>
            e.date.year == now.year &&
            e.date.month == now.month &&
            e.date.day == now.day)
        .fold<double>(0, (sum, e) => sum + e.amount);
  }
}
