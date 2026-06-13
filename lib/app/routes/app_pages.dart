import 'package:ad_shop_pos/modules/cart/cart_page.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_page.dart';
import 'package:ad_shop_pos/modules/products/products_page.dart';
import 'package:ad_shop_pos/modules/reports/reports_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_history_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_page.dart';
import 'package:get/get.dart';

import '../../modules/dashboard/dashboard_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(name: Routes.dashboard, page: () => DashboardPage()),
    GetPage(name: Routes.products, page: () => const ProductsPage()),
    GetPage(name: Routes.cart, page: () => CartPage()),
    GetPage(name: Routes.sales, page: () => const SalesHistoryPage()),
    GetPage(name: Routes.reports, page: () => const ReportsPage()),
    GetPage(name: Routes.settings, page: () => const SettingsPage()),
  ];
}
