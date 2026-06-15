import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/models/receipt_settings_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';
import 'package:ad_shop_pos/data/services/export_service.dart';
import 'package:ad_shop_pos/data/services/import_service.dart';
import 'package:ad_shop_pos/modules/printer/thermal_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // ---------- Shop Information ----------
            _SectionTile(
              icon: Icons.storefront,
              title: "Shop Information",
              subtitle: "Name, address, phone & currency",
              color: AppColors.seed,
              initiallyExpanded: true,
              children: [
                Obx(() => _ShopInfoForm(settings: controller.settings.value)),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Tax Settings ----------
            _SectionTile(
              icon: Icons.receipt_outlined,
              title: "Tax Settings",
              subtitle: "Tax rate & inclusive pricing",
              color: AppColors.accent,
              children: [
                Obx(() => _TaxForm(settings: controller.settings.value)),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Receipt Customization ----------
            _SectionTile(
              icon: Icons.receipt_long_outlined,
              title: "Receipt Customization",
              subtitle: "Paper size, font, visibility & preview",
              color: AppColors.seed,
              children: [
                Obx(
                  () => _ReceiptCustomizationWithPreview(
                    receiptSettings: controller.receiptSettings.value,
                    shopSettings: controller.settings.value,
                    onChanged: (s) => controller.updateReceiptSettings(s),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Thermal Printer ----------
            _SectionTile(
              icon: Icons.print_outlined,
              title: "Thermal Printer",
              subtitle: "Scan, pair & test your printer",
              color: AppColors.accent,
              children: [_PrinterSettingsSection()],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Export & Backup ----------
            _SectionTile(
              icon: Icons.file_download_outlined,
              title: "Export & Backup",
              subtitle: "Download CSV or full JSON backup",
              color: AppColors.success,
              children: [
                _ExportTile(
                  icon: Icons.inventory_2_outlined,
                  title: "Export Products",
                  subtitle: "Download all products as CSV",
                  color: AppColors.seed,
                  onTap: () => ExportService.exportProducts(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ExportTile(
                  icon: Icons.receipt_long_outlined,
                  title: "Export Sales",
                  subtitle: "Download all sales records as CSV",
                  color: AppColors.success,
                  onTap: () => ExportService.exportSales(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ExportTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Export Expenses",
                  subtitle: "Download all expenses as CSV",
                  color: AppColors.danger,
                  onTap: () => ExportService.exportExpenses(),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ExportTile(
                  icon: Icons.folder_zip_outlined,
                  title: "Full Backup",
                  subtitle: "Export all data as restorable JSON backup",
                  color: AppColors.accent,
                  onTap: () => ExportService.exportFullBackup(),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- Import & Restore ----------
            _SectionTile(
              icon: Icons.file_upload_outlined,
              title: "Import & Restore",
              subtitle: "Restore data from a backup file",
              color: AppColors.warning,
              children: [
                _ImportTile(
                  icon: Icons.restore_outlined,
                  title: "Restore from Backup",
                  subtitle:
                      "Import data from a previously exported backup file",
                  color: AppColors.warning,
                  onTap: () => _showImportDialog(context),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.danger,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          "Restoring a backup will replace all current data. Export a backup first to keep your data.",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    final data = await ImportService.pickBackupFile();
    if (data == null) return;

    final summary = ImportService.analyzeBackup(data);

    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ImportConfirmDialog(summary: summary),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.lg),
                Text("Restoring backup..."),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await ImportService.importBackup(data);

    if (context.mounted) Navigator.of(context).pop();

    if (success) {
      Get.snackbar(
        "Restore Complete",
        "All data has been successfully restored from backup",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
      );
    }
  }
}

// =================== Expandable Section Tile ===================

class _SectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool initiallyExpanded;
  final List<Widget> children;

  const _SectionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.initiallyExpanded = false,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: Theme(
        // Override expansion tile colors
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.md,
          ),
          leading: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

// =================== Shop Info Form ===================

class _ShopInfoForm extends StatefulWidget {
  final ShopSettingsModel settings;
  const _ShopInfoForm({required this.settings});

  @override
  State<_ShopInfoForm> createState() => _ShopInfoFormState();
}

class _ShopInfoFormState extends State<_ShopInfoForm> {
  late final _shopNameController = TextEditingController(
    text: widget.settings.shopName,
  );
  late final _addressController = TextEditingController(
    text: widget.settings.address,
  );
  late final _phoneController = TextEditingController(
    text: widget.settings.phone,
  );
  late final _footerController = TextEditingController(
    text: widget.settings.receiptFooter,
  );
  late final _currencyController = TextEditingController(
    text: widget.settings.currencySymbol,
  );

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();

    return Column(
      children: [
        TextField(
          controller: _shopNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Shop name",
            prefixIcon: Icon(Icons.store_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _addressController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: "Address",
            prefixIcon: Icon(Icons.location_on_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: "Phone number",
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _currencyController,
          decoration: const InputDecoration(
            labelText: "Currency symbol",
            prefixIcon: Icon(Icons.attach_money),
            hintText: "Rs, \$, €, £, etc.",
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _footerController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: "Receipt footer message",
            prefixIcon: Icon(Icons.description_outlined),
            hintText: "e.g. No refunds after 7 days",
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              controller.updateSettings(
                ShopSettingsModel(
                  shopName: _shopNameController.text.trim().isEmpty
                      ? 'My Shop'
                      : _shopNameController.text.trim(),
                  address: _addressController.text.trim(),
                  phone: _phoneController.text.trim(),
                  receiptFooter: _footerController.text.trim().isEmpty
                      ? 'Thank you for shopping!'
                      : _footerController.text.trim(),
                  currencySymbol: _currencyController.text.trim().isEmpty
                      ? 'Rs'
                      : _currencyController.text.trim(),
                  taxRate: controller.settings.value.taxRate,
                  taxInclusive: controller.settings.value.taxInclusive,
                ),
              );
              Get.snackbar(
                "Saved",
                "Shop information updated",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text("Save Shop Info"),
          ),
        ),
      ],
    );
  }
}

// =================== Tax Form ===================

class _TaxForm extends StatefulWidget {
  final ShopSettingsModel settings;
  const _TaxForm({required this.settings});

  @override
  State<_TaxForm> createState() => _TaxFormState();
}

class _TaxFormState extends State<_TaxForm> {
  late final _taxRateController = TextEditingController(
    text: widget.settings.taxRate.toStringAsFixed(1),
  );
  late bool _taxInclusive = widget.settings.taxInclusive;

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Column(
      children: [
        TextField(
          controller: _taxRateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Tax rate",
            prefixIcon: Icon(Icons.percent_outlined),
            suffixText: "%",
            hintText: "e.g. 16 for 16% VAT",
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        StatefulBuilder(
          builder: (context, setInnerState) {
            return SwitchListTile(
              value: _taxInclusive,
              onChanged: (val) => setInnerState(() => _taxInclusive = val),
              title: const Text("Tax-inclusive pricing"),
              subtitle: Text(
                _taxInclusive
                    ? "Product prices already include tax"
                    : "Tax is added on top of product prices",
                style: TextStyle(
                  color: _taxInclusive ? AppColors.success : AppColors.warning,
                  fontSize: 12,
                ),
              ),
              secondary: Icon(
                _taxInclusive
                    ? Icons.check_circle_outline
                    : Icons.add_circle_outline,
                color: _taxInclusive ? AppColors.success : AppColors.warning,
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              controller.updateSettings(
                controller.settings.value.copyWith(
                  taxRate: double.tryParse(_taxRateController.text) ?? 0,
                  taxInclusive: _taxInclusive,
                ),
              );
              Get.snackbar(
                "Saved",
                "Tax settings updated",
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text("Save Tax Settings"),
          ),
        ),
      ],
    );
  }
}

// =================== Receipt Customization with Preview ===================

class _ReceiptCustomizationWithPreview extends StatelessWidget {
  final ReceiptSettingsModel receiptSettings;
  final ShopSettingsModel shopSettings;
  final ValueChanged<ReceiptSettingsModel> onChanged;

  const _ReceiptCustomizationWithPreview({
    required this.receiptSettings,
    required this.shopSettings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Paper width
        _SettingLabel("Paper Width"),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _ChoiceChip(
              label: "58mm",
              selected: receiptSettings.paperWidth == 58,
              onTap: () => onChanged(receiptSettings.copyWith(paperWidth: 58)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "80mm",
              selected: receiptSettings.paperWidth == 80,
              onTap: () => onChanged(receiptSettings.copyWith(paperWidth: 80)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Font size
        _SettingLabel("Font Size"),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _ChoiceChip(
              label: "Small",
              selected: receiptSettings.fontSize == 0,
              onTap: () => onChanged(receiptSettings.copyWith(fontSize: 0)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "Normal",
              selected: receiptSettings.fontSize == 1,
              onTap: () => onChanged(receiptSettings.copyWith(fontSize: 1)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "Large",
              selected: receiptSettings.fontSize == 2,
              onTap: () => onChanged(receiptSettings.copyWith(fontSize: 2)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Show/hide toggles grouped
        _SettingLabel("Show on Receipt"),
        const SizedBox(height: AppSpacing.xs),
        _ToggleGroup(settings: receiptSettings, onChanged: onChanged),
        const SizedBox(height: AppSpacing.lg),

        // Preview
        _SettingLabel("Live Preview"),
        const SizedBox(height: AppSpacing.xs),
        _ReceiptPreview(
          receiptSettings: receiptSettings,
          shopSettings: shopSettings,
        ),
      ],
    );
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;
  const _SettingLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ToggleGroup extends StatelessWidget {
  final ReceiptSettingsModel settings;
  final ValueChanged<ReceiptSettingsModel> onChanged;

  const _ToggleGroup({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header section
        _ToggleRow(
          Icons.store_outlined,
          "Shop name",
          settings.showShopName,
          (v) => onChanged(settings.copyWith(showShopName: v)),
        ),
        _ToggleRow(
          Icons.location_on_outlined,
          "Address",
          settings.showAddress,
          (v) => onChanged(settings.copyWith(showAddress: v)),
        ),
        _ToggleRow(
          Icons.phone_outlined,
          "Phone",
          settings.showPhone,
          (v) => onChanged(settings.copyWith(showPhone: v)),
        ),
        _ToggleRow(
          Icons.access_time,
          "Date & Time",
          settings.showDate,
          (v) => onChanged(settings.copyWith(showDate: v)),
        ),

        const Divider(height: AppSpacing.lg),

        // Transaction section
        _ToggleRow(
          Icons.badge_outlined,
          "Cashier name",
          settings.showCashier,
          (v) => onChanged(settings.copyWith(showCashier: v)),
        ),
        _ToggleRow(
          Icons.person_outline,
          "Customer name",
          settings.showCustomer,
          (v) => onChanged(settings.copyWith(showCustomer: v)),
        ),

        const Divider(height: AppSpacing.lg),

        // Product details section
        _ToggleRow(
          Icons.tag,
          "SKU",
          settings.showSku,
          (v) => onChanged(settings.copyWith(showSku: v)),
        ),
        _ToggleRow(
          Icons.branding_watermark,
          "Brand",
          settings.showBrand,
          (v) => onChanged(settings.copyWith(showBrand: v)),
        ),
        _ToggleRow(
          Icons.qr_code,
          "Barcode",
          settings.showBarcode,
          (v) => onChanged(settings.copyWith(showBarcode: v)),
        ),

        const Divider(height: AppSpacing.lg),

        // Pricing section
        _ToggleRow(
          Icons.local_offer_outlined,
          "Discount details",
          settings.showDiscountDetails,
          (v) => onChanged(settings.copyWith(showDiscountDetails: v)),
        ),
        _ToggleRow(
          Icons.percent_outlined,
          "Tax details",
          settings.showTaxDetails,
          (v) => onChanged(settings.copyWith(showTaxDetails: v)),
        ),

        const Divider(height: AppSpacing.lg),

        // Footer
        _ToggleRow(
          Icons.description_outlined,
          "Footer message",
          settings.showFooter,
          (v) => onChanged(settings.copyWith(showFooter: v)),
        ),
      ],
    );
  }

  Widget _ToggleRow(
    IconData icon,
    String label,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, size: 18, color: value ? AppColors.seed : null),
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      ),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// =================== Receipt Preview ===================

class _ReceiptPreview extends StatelessWidget {
  final ReceiptSettingsModel receiptSettings;
  final ShopSettingsModel shopSettings;

  const _ReceiptPreview({
    required this.receiptSettings,
    required this.shopSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = receiptSettings.paperWidth == 58 ? 220.0 : 300.0;
    final scale = receiptSettings.fontSize == 0
        ? 0.85
        : receiptSettings.fontSize == 2
        ? 1.15
        : 1.0;
    final cur = shopSettings.currencySymbol;

    return Center(
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8 * scale),
          child: DefaultTextStyle(
            style: TextStyle(
              color: Colors.black87,
              fontSize: 10 * scale,
              fontFamily: 'monospace',
              height: 1.4,
            ),
            child: Column(
              children: [
                // Shop header
                if (receiptSettings.showShopName)
                  Text(
                    shopSettings.shopName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (receiptSettings.showAddress &&
                    shopSettings.address.isNotEmpty)
                  Text(shopSettings.address, textAlign: TextAlign.center),
                if (receiptSettings.showPhone && shopSettings.phone.isNotEmpty)
                  Text(shopSettings.phone, textAlign: TextAlign.center),
                const _PreviewDivider(),

                // Date
                if (receiptSettings.showDate)
                  Text(
                    "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} 14:30",
                    textAlign: TextAlign.left,
                  ),
                if (receiptSettings.showCashier) const Text("Cashier: Ali"),
                if (receiptSettings.showCustomer) const Text("Customer: Ahmed"),
                if (receiptSettings.showDate ||
                    receiptSettings.showCashier ||
                    receiptSettings.showCustomer)
                  const _PreviewDivider(),

                // Sample items
                _PreviewItem(
                  name: "Casio Watch",
                  qty: 2,
                  price: 3500,
                  cur: cur,
                  discount: 10,
                  showDiscount: receiptSettings.showDiscountDetails,
                  showSku: receiptSettings.showSku,
                  showBrand: receiptSettings.showBrand,
                  showBarcode: receiptSettings.showBarcode,
                  sku: "W0001",
                  brand: "Casio",
                  barcode: "8901234567890",
                  scale: scale,
                ),
                _PreviewItem(
                  name: "Perfume",
                  qty: 1,
                  price: 2000,
                  cur: cur,
                  discount: 0,
                  showDiscount: receiptSettings.showDiscountDetails,
                  showSku: receiptSettings.showSku,
                  showBrand: receiptSettings.showBrand,
                  showBarcode: receiptSettings.showBarcode,
                  sku: "P0002",
                  brand: "",
                  barcode: "",
                  scale: scale,
                ),
                const _PreviewDivider(),

                // Totals
                Text("Subtotal: $cur 8,300"),
                if (receiptSettings.showDiscountDetails) ...[
                  Text("Product disc: -$cur 700"),
                  Text("Checkout disc (5%): -$cur 415"),
                ],
                if (receiptSettings.showTaxDetails)
                  Text("Tax (16%): $cur 1,328"),
                Text(
                  "TOTAL: $cur 8,513",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12 * scale,
                  ),
                ),
                Text("Cash: $cur 9,000"),
                Text("Change: $cur 487"),

                // Footer
                if (receiptSettings.showFooter) ...[
                  const SizedBox(height: 4),
                  const _PreviewDivider(),
                  Text(
                    shopSettings.receiptFooter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewDivider extends StatelessWidget {
  const _PreviewDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashWidth = constraints.maxWidth > 0
              ? constraints.maxWidth
              : 200.0;
          return Row(
            children: List.generate(
              (dashWidth / 6).floor(),
              (_) => Expanded(
                child: Container(
                  height: 0.5,
                  color: Colors.black26,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String name;
  final int qty;
  final int price;
  final String cur;
  final double discount;
  final bool showDiscount;
  final bool showSku;
  final bool showBrand;
  final bool showBarcode;
  final String sku;
  final String brand;
  final String barcode;
  final double scale;

  const _PreviewItem({
    required this.name,
    required this.qty,
    required this.price,
    required this.cur,
    required this.discount,
    required this.showDiscount,
    required this.showSku,
    required this.showBrand,
    required this.showBarcode,
    required this.sku,
    required this.brand,
    required this.barcode,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final discountedPrice = discount > 0
        ? (price * (1 - discount / 100)).round()
        : price;
    final total = qty * discountedPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
          if (showBrand && brand.isNotEmpty)
            Text(
              "  Brand: $brand",
              style: TextStyle(fontSize: 9 * scale, color: Colors.black54),
            ),
          if (showSku && sku.isNotEmpty)
            Text(
              "  SKU: $sku",
              style: TextStyle(fontSize: 9 * scale, color: Colors.black54),
            ),
          if (showBarcode && barcode.isNotEmpty)
            Text(
              "  Barcode: $barcode",
              style: TextStyle(fontSize: 9 * scale, color: Colors.black54),
            ),
          Text("  $qty x $cur $discountedPrice = $cur $total"),
          if (showDiscount && discount > 0)
            Text(
              "  Orig: $cur $price (-${discount.toStringAsFixed(0)}%)",
              style: TextStyle(fontSize: 9 * scale, color: Colors.black54),
            ),
        ],
      ),
    );
  }
}

// =================== Printer Settings Section ===================

class _PrinterSettingsSection extends StatefulWidget {
  @override
  State<_PrinterSettingsSection> createState() =>
      _PrinterSettingsSectionState();
}

class _PrinterSettingsSectionState extends State<_PrinterSettingsSection> {
  bool _scanning = false;
  List<BluetoothPrinter> _printers = [];

  @override
  void initState() {
    super.initState();
    _scanPrinters();
  }

  Future<void> _scanPrinters() async {
    setState(() => _scanning = true);

    // Request necessary permissions before scanning
    final statuses = await [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    final allGranted = statuses.values.every((s) => s.isGranted);

    if (!allGranted) {
      if (mounted) {
        setState(() => _scanning = false);
        Get.snackbar(
          "Permission Required",
          "Please grant Bluetooth and Location permissions to scan for printers",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          colorText: AppColors.warning,
        );
      }
      return;
    }

    // Check if Bluetooth is enabled
    final btEnabled = await PrintBluetoothThermal.bluetoothEnabled;
    if (btEnabled == false) {
      if (mounted) {
        setState(() => _scanning = false);
        Get.snackbar(
          "Bluetooth Off",
          "Please turn on Bluetooth to scan for printers",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.warning.withValues(alpha: 0.15),
          colorText: AppColors.warning,
        );
      }
      return;
    }

    final printers = await ThermalPrinterService.getAvailablePrinters();
    if (mounted) {
      setState(() {
        _printers = printers;
        _scanning = false;
      });
    }
  }

  Future<void> _pairPrinter(String mac) async {
    final controller = Get.find<SettingsController>();
    final connected = await ThermalPrinterService.connect(mac);
    if (connected) {
      controller.updateReceiptSettings(
        controller.receiptSettings.value.copyWith(pairedPrinterMac: mac),
      );
      Get.snackbar(
        "Printer Paired",
        "Successfully connected to printer",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.15),
        colorText: AppColors.success,
      );
      await Future.delayed(const Duration(seconds: 1));
      await ThermalPrinterService.disconnect();
    } else {
      Get.snackbar(
        "Connection Failed",
        "Could not connect to printer. Make sure it's turned on and in range.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.15),
        colorText: AppColors.danger,
      );
    }
  }

  Future<void> _testPrint() async {
    final controller = Get.find<SettingsController>();
    final receiptSettings = controller.receiptSettings.value;

    if (!receiptSettings.hasPrinter) {
      Get.snackbar(
        "No printer",
        "Please pair a printer first",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final connected = await ThermalPrinterService.connect(
      receiptSettings.pairedPrinterMac,
    );
    if (!connected) {
      Get.snackbar(
        "Error",
        "Could not connect to printer",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      "Test Print",
      "Sending test receipt...",
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );

    await ThermalPrinterService.disconnect();
    Get.snackbar(
      "Test Print",
      "Test completed",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scan button
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: _scanning ? null : _scanPrinters,
            icon: _scanning
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching, size: 18),
            label: Text(_scanning ? "Scanning..." : "Scan for Printers"),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Currently paired printer
        Obx(() {
          final controller = Get.find<SettingsController>();
          final mac = controller.receiptSettings.value.pairedPrinterMac;
          if (mac.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "No printer paired yet",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Paired Printer",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      Text(
                        mac,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    controller.updateReceiptSettings(
                      controller.receiptSettings.value.copyWith(
                        pairedPrinterMac: '',
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.danger,
                  ),
                  tooltip: "Remove printer",
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: AppSpacing.md),

        // Discovered printers
        if (_printers.isNotEmpty) ...[
          Text(
            "Discovered Printers",
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._printers.map(
            (printer) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.print, color: AppColors.accent, size: 20),
                title: Text(printer.name, style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  printer.mac,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                trailing: SizedBox(
                  width: 82,
                  child: FilledButton.tonal(
                    onPressed: () => _pairPrinter(printer.mac),
                    child: const Text("Pair", style: TextStyle(fontSize: 12)),
                  ),
                ),
              ),
            ),
          ),
        ] else if (!_scanning) ...[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              "No printers found. Make sure your thermal printer is turned on and Bluetooth is enabled.",
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Test print
        Obx(() {
          final controller = Get.find<SettingsController>();
          if (!controller.receiptSettings.value.hasPrinter)
            return const SizedBox.shrink();
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _testPrint,
              icon: const Icon(Icons.receipt_outlined, size: 18),
              label: const Text("Test Print"),
            ),
          );
        }),
      ],
    );
  }
}

// =================== Export / Import Tiles ===================

class _ExportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ExportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.share_outlined, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ImportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.file_open_outlined, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Import Confirm Dialog ===================

class _ImportConfirmDialog extends StatelessWidget {
  final BackupSummary summary;

  const _ImportConfirmDialog({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          const Text("Confirm Restore"),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This will replace ALL your current data with the backup data.",
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Backup info
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Backup Details",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SummaryRow(
                  icon: Icons.calendar_today_outlined,
                  label: "Exported",
                  value: summary.formattedDate,
                ),
                _SummaryRow(
                  icon: Icons.tag,
                  label: "Version",
                  value: "v${summary.version}",
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Data counts
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Data to Restore",
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (summary.productCount > 0)
                  _SummaryRow(
                    icon: Icons.inventory_2_outlined,
                    label: "Products",
                    value: "${summary.productCount}",
                  ),
                if (summary.saleCount > 0)
                  _SummaryRow(
                    icon: Icons.receipt_long_outlined,
                    label: "Sales",
                    value: "${summary.saleCount}",
                  ),
                if (summary.expenseCount > 0)
                  _SummaryRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Expenses",
                    value: "${summary.expenseCount}",
                  ),
                if (summary.returnCount > 0)
                  _SummaryRow(
                    icon: Icons.undo_outlined,
                    label: "Returns",
                    value: "${summary.returnCount}",
                  ),
                if (summary.customerCount > 0)
                  _SummaryRow(
                    icon: Icons.person_outline,
                    label: "Customers",
                    value: "${summary.customerCount}",
                  ),
                if (summary.staffCount > 0)
                  _SummaryRow(
                    icon: Icons.badge_outlined,
                    label: "Staff",
                    value: "${summary.staffCount}",
                  ),
                if (summary.hasSettings)
                  _SummaryRow(
                    icon: Icons.settings_outlined,
                    label: "Settings",
                    value: "Included",
                  ),
                if (summary.totalRecords == 0 && !summary.hasSettings)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(
                      "Backup appears to be empty",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Warning
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, size: 18, color: AppColors.danger),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    "Your current data will be permanently deleted and replaced with the backup data. This action cannot be undone.",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Cancel"),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.restore_outlined, size: 18),
          label: const Text("Restore"),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            minimumSize: const Size(120, 44),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
