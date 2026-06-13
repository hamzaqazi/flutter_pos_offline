import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:get/get.dart';

class DashboardController extends GetxController {
  final ProductsController productsController = Get.find();

  RxInt totalProducts = 0.obs;
  RxInt totalSales = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ever(productsController.products, (_) {
      totalProducts.value = productsController.products.length;
    });

    totalProducts.value = productsController.products.length;
  }
}
