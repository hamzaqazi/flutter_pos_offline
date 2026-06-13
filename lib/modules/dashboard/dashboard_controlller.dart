import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final ProductsController productsController = Get.find();
  final SalesController salesController = Get.find();

  RxInt totalProducts = 0.obs;
  RxInt totalSales = 0.obs;
  RxDouble totalRevenue = 0.0.obs;
  RxInt lowStockCount = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(productsController.products, (_) => _recalcProducts());
    ever(salesController.sales, (_) => _recalcSales());

    _recalcProducts();
    _recalcSales();
  }

  void _recalcProducts() {
    totalProducts.value = productsController.products.length;
    lowStockCount.value =
        productsController.products.where((p) => p.stock <= 5).length;
  }

  void _recalcSales() {
    totalSales.value = salesController.sales.length;
    totalRevenue.value = salesController.sales.fold<double>(
      0,
      (sum, sale) => sum + sale.total,
    );
  }
}
