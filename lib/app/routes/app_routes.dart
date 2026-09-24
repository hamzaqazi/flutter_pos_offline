abstract class Routes {
  static const dashboard = '/';
  static const products = '/products';
  static const cart = '/cart';
  static const sales = '/sales';
  static const reports = '/reports';
  static const settings = '/settings';
  static const expenses = '/expenses';
  static const returns = '/returns';
  static const customers = '/customers';
  static const staff = '/staff';

  static const activation = '/activation';
  static const pinSetup = '/pin-setup';
  static const pinLock = '/pin-lock';
  static const lowStock = '/low-stock';
  static const inventory = '/inventory';
  static const invoice = '/invoice';
  static const scanner = '/scanner';
  static const backupHistory = '/backup-history';
  static const driveBackup = '/drive-backup';
  static const license = '/license';

  // User manual — the hub, plus a single guide (deep-link with
  // `parameters: {'id': '<guide id>'}`).
  static const manual = '/manual';
  static const manualArticle = '/manual/article';
}
