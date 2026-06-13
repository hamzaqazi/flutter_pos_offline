import 'package:get/get.dart';

import '../../data/models/shop_settings_model.dart';
import '../../data/services/settings_service.dart';

class SettingsController extends GetxController {
  final settings = ShopSettingsModel().obs;

  @override
  void onInit() {
    loadSettings();
    super.onInit();
  }

  void loadSettings() {
    settings.value = SettingsService.getSettings();
  }

  void updateSettings(ShopSettingsModel newSettings) {
    SettingsService.saveSettings(newSettings);
    settings.value = newSettings;
  }

  String get shopName => settings.value.shopName;
  String get address => settings.value.address;
  String get phone => settings.value.phone;
  String get receiptFooter => settings.value.receiptFooter;
  String get currencySymbol => settings.value.currencySymbol;
}
