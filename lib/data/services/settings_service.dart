import 'package:hive/hive.dart';

import '../models/shop_settings_model.dart';

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
}
