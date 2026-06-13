import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/reports/reports_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => ProductsController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    Get.lazyPut(() => SalesController(), fenix: true);
    Get.lazyPut(() => ReportsController(), fenix: true);
  }
}
