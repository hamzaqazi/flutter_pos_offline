import 'package:get/get.dart';

import '../../data/models/shop_settings_model.dart';
import '../../data/models/receipt_settings_model.dart';
import '../../data/services/settings_service.dart';

class SettingsController extends GetxController {
  final settings = ShopSettingsModel().obs;
  final receiptSettings = ReceiptSettingsModel().obs;

  @override
  void onInit() {
    loadSettings();
    super.onInit();
  }

  void loadSettings() {
    settings.value = SettingsService.getSettings();
    receiptSettings.value = SettingsService.getReceiptSettings();
  }

  void updateSettings(ShopSettingsModel newSettings) {
    SettingsService.saveSettings(newSettings);
    settings.value = newSettings;
  }

  void updateReceiptSettings(ReceiptSettingsModel newSettings) {
    SettingsService.saveReceiptSettings(newSettings);
    receiptSettings.value = newSettings;
  }

  String get shopName => settings.value.shopName;
  String get address => settings.value.address;
  String get phone => settings.value.phone;
  String get receiptFooter => settings.value.receiptFooter;
  String get currencySymbol => settings.value.currencySymbol;
  double get taxRate => settings.value.taxRate;
  bool get taxInclusive => settings.value.taxInclusive;
}
