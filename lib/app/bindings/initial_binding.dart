import 'package:ad_shop_pos/app/theme/theme_controller.dart';
import 'package:ad_shop_pos/modules/cart/cart_controller.dart';
import 'package:ad_shop_pos/modules/customers/customers_controller.dart';
import 'package:ad_shop_pos/modules/dashboard/dashboard_controlller.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_controller.dart';
import 'package:ad_shop_pos/modules/products/products_controller.dart';
import 'package:ad_shop_pos/modules/reports/reports_controller.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:ad_shop_pos/modules/sales/sales_controller.dart';
import 'package:ad_shop_pos/modules/settings/settings_controller.dart';
import 'package:get/get.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(SettingsController(), permanent: true);
    Get.put(ExpensesController(), permanent: true);
    Get.put(ReturnsController(), permanent: true);
    Get.put(CustomersController(), permanent: true);
    Get.lazyPut(() => DashboardController(), fenix: true);
    Get.lazyPut(() => ProductsController(), fenix: true);
    Get.lazyPut(() => CartController(), fenix: true);
    Get.lazyPut(() => SalesController(), fenix: true);
    Get.lazyPut(() => ReportsController(), fenix: true);
  }
}
