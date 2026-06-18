import 'package:ad_shop_pos/data/services/settings_service.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final ProductsController productsController = Get.find();
  final SalesController salesController = Get.find();
  final ReturnsController returnsController = Get.find();

  // All-time stats
  RxInt totalProducts = 0.obs;
  RxInt totalSales = 0.obs;
  RxDouble totalRevenue = 0.0.obs;
  RxDouble totalProfit = 0.0.obs;
  RxInt lowStockCount = 0.obs;
  RxDouble totalRefunds = 0.0.obs;
  RxInt totalReturnCount = 0.obs;

  // Today's stats
  RxInt todaySales = 0.obs;
  RxDouble todayRevenue = 0.0.obs;
  RxDouble todayProfit = 0.0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(productsController.products, (_) => _recalcProducts());
    ever(salesController.sales, (_) => _recalcSales());
    ever(returnsController.returns, (_) => _recalcSales());

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
    totalProfit.value = salesController.sales.fold<double>(
      0,
      (sum, sale) => sum + sale.profit,
    );
    totalProfit.value -= returnsController.totalProfitReversed;
    totalRefunds.value = returnsController.totalRefunds;
    totalReturnCount.value = returnsController.returns.length;

    // Today's stats
    final now = DateTime.now();
    final todaySalesList = salesController.sales.where((s) =>
      s.date.year == now.year && s.date.month == now.month && s.date.day == now.day
    ).toList();
    todaySales.value = todaySalesList.length;
    todayRevenue.value = todaySalesList.fold<double>(0, (sum, s) => sum + s.total);
    todayProfit.value = todaySalesList.fold<double>(0, (sum, s) => sum + s.profit);
  }
}
