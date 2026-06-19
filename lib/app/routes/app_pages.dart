import 'package:ad_shop_pos/modules/activation/activation_screen.dart';
import 'package:ad_shop_pos/modules/activation/pin_lock_screen.dart';
import 'package:ad_shop_pos/modules/activation/pin_setup_screen.dart';
import 'package:ad_shop_pos/modules/cart/cart_page.dart';
import 'package:ad_shop_pos/modules/customers/customers_page.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_page.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_page.dart';
import 'package:ad_shop_pos/modules/products/low_stock_page.dart';
import 'package:ad_shop_pos/modules/products/products_page.dart';
import 'package:ad_shop_pos/modules/reports/reports_page.dart';
import 'package:ad_shop_pos/modules/returns/returns_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_history_page.dart';
import 'package:ad_shop_pos/modules/sales/sales_page.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/modules/settings/settings_page.dart';
import 'package:ad_shop_pos/modules/staff/staff_page.dart';
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
    GetPage(name: Routes.expenses, page: () => const ExpensesPage()),
    GetPage(name: Routes.returns, page: () => const ReturnsPage()),
    GetPage(name: Routes.customers, page: () => const CustomersPage()),
    GetPage(name: Routes.staff, page: () => const StaffPage()),
    GetPage(name: Routes.scanner, page: () => const BarcodeScannerPage()),
    GetPage(name: Routes.lowStock, page: () => const LowStockPage()),
    GetPage(name: Routes.activation, page: () => const ActivationScreen()),
    GetPage(name: Routes.pinSetup, page: () => const PinSetupScreen()),
    GetPage(name: Routes.pinLock, page: () => const PinLockScreen()),
  ];
}
