/// Settings for receipt customization and thermal printer.
class ReceiptSettingsModel {
  // --- Receipt layout ---
  final String logoPath; // path to shop logo image
  final bool showLogo;
  final bool showShopName;
  final bool showAddress;
  final bool showPhone;
  final bool showDate;
  final bool showCashier;
  final bool showCustomer;
  final bool showSku;
  final bool showBrand;
  final bool showBarcode;
  final bool showDiscountDetails;
  final bool showTaxDetails;
  final bool showFooter;
  final int paperWidth; // 58 = 58mm, 80 = 80mm
  final int fontSize; // base font size for thermal print (0=small, 1=normal, 2=large)

  // --- Thermal printer ---
  final String pairedPrinterMac; // MAC address of paired Bluetooth printer

  ReceiptSettingsModel({
    this.logoPath = '',
    this.showLogo = false,
    this.showShopName = true,
    this.showAddress = true,
    this.showPhone = true,
    this.showDate = true,
    this.showCashier = true,
    this.showCustomer = true,
    this.showSku = true,
    this.showBrand = true,
    this.showBarcode = false,
    this.showDiscountDetails = true,
    this.showTaxDetails = true,
    this.showFooter = true,
    this.paperWidth = 80,
    this.fontSize = 1,
    this.pairedPrinterMac = '',
  });

  bool get hasLogo => logoPath.isNotEmpty;
  bool get hasPrinter => pairedPrinterMac.isNotEmpty;

  /// Get chars per line based on paper width and font size.
  int get charsPerLine {
    // Standard: 58mm ≈ 32 chars, 80mm ≈ 48 chars (at normal size)
    final base = paperWidth == 58 ? 32 : 48;
    if (fontSize == 0) return (base * 1.3).floor(); // small
    if (fontSize == 2) return (base * 0.7).floor(); // large
    return base; // normal
  }

  ReceiptSettingsModel copyWith({
    String? logoPath,
    bool? showLogo,
    bool? showShopName,
    bool? showAddress,
    bool? showPhone,
    bool? showDate,
    bool? showCashier,
    bool? showCustomer,
    bool? showSku,
    bool? showBrand,
    bool? showBarcode,
    bool? showDiscountDetails,
    bool? showTaxDetails,
    bool? showFooter,
    int? paperWidth,
    int? fontSize,
    String? pairedPrinterMac,
  }) {
    return ReceiptSettingsModel(
      logoPath: logoPath ?? this.logoPath,
      showLogo: showLogo ?? this.showLogo,
      showShopName: showShopName ?? this.showShopName,
      showAddress: showAddress ?? this.showAddress,
      showPhone: showPhone ?? this.showPhone,
      showDate: showDate ?? this.showDate,
      showCashier: showCashier ?? this.showCashier,
      showCustomer: showCustomer ?? this.showCustomer,
      showSku: showSku ?? this.showSku,
      showBrand: showBrand ?? this.showBrand,
      showBarcode: showBarcode ?? this.showBarcode,
      showDiscountDetails: showDiscountDetails ?? this.showDiscountDetails,
      showTaxDetails: showTaxDetails ?? this.showTaxDetails,
      showFooter: showFooter ?? this.showFooter,
      paperWidth: paperWidth ?? this.paperWidth,
      fontSize: fontSize ?? this.fontSize,
      pairedPrinterMac: pairedPrinterMac ?? this.pairedPrinterMac,
    );
  }

  Map<String, dynamic> toMap() => {
        'logoPath': logoPath,
        'showLogo': showLogo,
        'showShopName': showShopName,
        'showAddress': showAddress,
        'showPhone': showPhone,
        'showDate': showDate,
        'showCashier': showCashier,
        'showCustomer': showCustomer,
        'showSku': showSku,
        'showBrand': showBrand,
        'showBarcode': showBarcode,
        'showDiscountDetails': showDiscountDetails,
        'showTaxDetails': showTaxDetails,
        'showFooter': showFooter,
        'paperWidth': paperWidth,
        'fontSize': fontSize,
        'pairedPrinterMac': pairedPrinterMac,
      };

  factory ReceiptSettingsModel.fromMap(Map<dynamic, dynamic> map) {
    return ReceiptSettingsModel(
      logoPath: map['logoPath'] ?? '',
      showLogo: map['showLogo'] ?? false,
      showShopName: map['showShopName'] ?? true,
      showAddress: map['showAddress'] ?? true,
      showPhone: map['showPhone'] ?? true,
      showDate: map['showDate'] ?? true,
      showCashier: map['showCashier'] ?? true,
      showCustomer: map['showCustomer'] ?? true,
      showSku: map['showSku'] ?? true,
      showBrand: map['showBrand'] ?? true,
      showBarcode: map['showBarcode'] ?? false,
      showDiscountDetails: map['showDiscountDetails'] ?? true,
      showTaxDetails: map['showTaxDetails'] ?? true,
      showFooter: map['showFooter'] ?? true,
      paperWidth: map['paperWidth'] ?? 80,
      fontSize: map['fontSize'] ?? 1,
      pairedPrinterMac: map['pairedPrinterMac'] ?? '',
    );
  }
}
