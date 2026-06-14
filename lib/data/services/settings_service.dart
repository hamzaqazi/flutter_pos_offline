import 'package:hive/hive.dart';

import '../models/shop_settings_model.dart';
import '../models/receipt_settings_model.dart';

class SettingsService {
  static final _box = Hive.box('settings');

  static ShopSettingsModel getSettings() {
    final data = _box.get('shop');
    if (data == null) return ShopSettingsModel();
    return ShopSettingsModel.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static void saveSettings(ShopSettingsModel settings) {
    _box.put('shop', settings.toMap());
  }

  static ReceiptSettingsModel getReceiptSettings() {
    final data = _box.get('receipt');
    if (data == null) return ReceiptSettingsModel();
    return ReceiptSettingsModel.fromMap(Map<dynamic, dynamic>.from(data));
  }

  static void saveReceiptSettings(ReceiptSettingsModel settings) {
    _box.put('receipt', settings.toMap());
  }
}
