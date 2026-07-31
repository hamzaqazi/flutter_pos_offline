import 'package:ad_shop_pos/app/shell/app_shell.dart';
import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/modules/activation/activation_screen.dart';
import 'package:ad_shop_pos/modules/activation/pin_lock_screen.dart';
import 'package:ad_shop_pos/modules/activation/pin_setup_screen.dart';
import 'package:ad_shop_pos/modules/customers/customers_page.dart';
import 'package:ad_shop_pos/modules/expenses/expenses_page.dart';
import 'package:ad_shop_pos/modules/invoice/invoice_page.dart';
import 'package:ad_shop_pos/modules/products/low_stock_page.dart';
import 'package:ad_shop_pos/modules/reports/reports_page.dart';
import 'package:ad_shop_pos/modules/returns/returns_page.dart';
import 'package:ad_shop_pos/modules/scanner/barcode_scanner_page.dart';
import 'package:ad_shop_pos/modules/settings/backup_history_page.dart';
import 'package:ad_shop_pos/modules/settings/drive_backup_page.dart';
import 'package:ad_shop_pos/modules/settings/license_page.dart';
import 'package:ad_shop_pos/modules/staff/staff_page.dart';
import 'package:get/get.dart';

import 'app_routes.dart';

class AppPages {
  static final pages = [
    // Main shell — contains all 5 tab pages (Dashboard, Products, POS, Sales, Settings)
    GetPage(name: Routes.dashboard, page: () => const AppShell()),
    // Non-tab pages (pushed on top of the shell) — fadeIn transition for smooth navigation
    GetPage(
      name: Routes.reports,
      page: () => const ReportsPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.expenses,
      page: () => const ExpensesPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.returns,
      page: () => const ReturnsPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.customers,
      page: () => const CustomersPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.staff,
      page: () => const StaffPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.scanner,
      page: () => const BarcodeScannerPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.lowStock,
      page: () => const LowStockPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.activation,
      page: () => const ActivationScreen(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.pinSetup,
      page: () => const PinSetupScreen(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.pinLock,
      page: () => const PinLockScreen(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.backupHistory,
      page: () => const BackupHistoryPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.driveBackup,
      page: () => const DriveBackupPage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
    GetPage(
      name: Routes.license,
      page: () => const LicensePage(),
      transition: Transition.fadeIn,
      transitionDuration: AppDuration.page,
    ),
  ];
}
