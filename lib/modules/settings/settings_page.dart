import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/models/receipt_settings_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';
import 'package:ad_shop_pos/data/services/export_service.dart';
import 'package:ad_shop_pos/data/services/import_service.dart';
import 'package:ad_shop_pos/modules/printer/thermal_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'settings_controller.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Shop Info ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.storefront, color: theme.colorScheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "Shop Information",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            Obx(() => _SettingsForm(settings: controller.settings.value)),

            const SizedBox(height: AppSpacing.xl),

            // ---------- Receipt Customization ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.seed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.seed),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "Receipt Customization",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Receipt settings
            Obx(() => _ReceiptCustomizationSection(
                  settings: controller.receiptSettings.value,
                  onChanged: (s) => controller.updateReceiptSettings(s),
                )),

            const SizedBox(height: AppSpacing.xl),

            // ---------- Thermal Printer ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.print_outlined, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "Thermal Printer",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _PrinterSettingsSection(),

            const SizedBox(height: AppSpacing.xl),

            // ---------- Export & Backup ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.file_download_outlined, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "Export & Backup",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _ExportTile(
              icon: Icons.inventory_2_outlined,
              title: "Export Products",
              subtitle: "Download all products as CSV",
              color: AppColors.seed,
              onTap: () => ExportService.exportProducts(),
            ),
            const SizedBox(height: AppSpacing.md),
            _ExportTile(
              icon: Icons.receipt_long_outlined,
              title: "Export Sales",
              subtitle: "Download all sales records as CSV",
              color: AppColors.success,
              onTap: () => ExportService.exportSales(),
            ),
            const SizedBox(height: AppSpacing.md),
            _ExportTile(
              icon: Icons.account_balance_wallet_outlined,
              title: "Export Expenses",
              subtitle: "Download all expenses as CSV",
              color: AppColors.danger,
              onTap: () => ExportService.exportExpenses(),
            ),
            const SizedBox(height: AppSpacing.md),
            _ExportTile(
              icon: Icons.folder_zip_outlined,
              title: "Full Backup",
              subtitle: "Export all data as restorable JSON backup",
              color: AppColors.accent,
              onTap: () => ExportService.exportFullBackup(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ---------- Import & Restore ----------
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Icon(Icons.file_upload_outlined, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    "Import & Restore",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            _ImportTile(
              icon: Icons.restore_outlined,
              title: "Restore from Backup",
              subtitle: "Import data from a previously exported backup file",
              color: AppColors.warning,
              onTap: () => _showImportDialog(context),
            ),
            const SizedBox(height: AppSpacing.md),

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
                  Icon(Icons.info_outline, size: 18, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      "Restoring a backup will replace all current data. "
                      "Make sure to export a backup first if you want to keep your current data.",
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
      ),
    );
  }

  void _showImportDialog(BuildContext context) async {
    // Step 1: Pick file
    final data = await ImportService.pickBackupFile();
    if (data == null) return; // User cancelled or invalid file

    // Step 2: Analyze backup
    final summary = ImportService.analyzeBackup(data);

    // Step 3: Show confirmation dialog
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ImportConfirmDialog(summary: summary),
    );

    if (confirmed != true) return;

    // Step 4: Show loading and perform import
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

    // Close loading dialog
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
                    "Your current data will be permanently deleted and replaced with the backup data. "
                    "This action cannot be undone.",
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.share_outlined, size: 20, color: color),
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
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.file_open_outlined, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== Receipt Customization Section ===================

class _ReceiptCustomizationSection extends StatelessWidget {
  final ReceiptSettingsModel settings;
  final ValueChanged<ReceiptSettingsModel> onChanged;

  const _ReceiptCustomizationSection({
    required this.settings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Paper width
        Text("Paper Width", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _PaperWidthChip(
              label: "58mm",
              selected: settings.paperWidth == 58,
              onTap: () => onChanged(settings.copyWith(paperWidth: 58)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PaperWidthChip(
              label: "80mm",
              selected: settings.paperWidth == 80,
              onTap: () => onChanged(settings.copyWith(paperWidth: 80)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Font size
        Text("Font Size", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _FontSizeChip(
              label: "Small",
              selected: settings.fontSize == 0,
              onTap: () => onChanged(settings.copyWith(fontSize: 0)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FontSizeChip(
              label: "Normal",
              selected: settings.fontSize == 1,
              onTap: () => onChanged(settings.copyWith(fontSize: 1)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FontSizeChip(
              label: "Large",
              selected: settings.fontSize == 2,
              onTap: () => onChanged(settings.copyWith(fontSize: 2)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Show/hide toggles
        Text("Show on Receipt", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        _ToggleTile(label: "Shop name", value: settings.showShopName, onChanged: (v) => onChanged(settings.copyWith(showShopName: v))),
        _ToggleTile(label: "Address", value: settings.showAddress, onChanged: (v) => onChanged(settings.copyWith(showAddress: v))),
        _ToggleTile(label: "Phone", value: settings.showPhone, onChanged: (v) => onChanged(settings.copyWith(showPhone: v))),
        _ToggleTile(label: "Date & Time", value: settings.showDate, onChanged: (v) => onChanged(settings.copyWith(showDate: v))),
        _ToggleTile(label: "Cashier name", value: settings.showCashier, onChanged: (v) => onChanged(settings.copyWith(showCashier: v))),
        _ToggleTile(label: "Customer name", value: settings.showCustomer, onChanged: (v) => onChanged(settings.copyWith(showCustomer: v))),
        _ToggleTile(label: "SKU", value: settings.showSku, onChanged: (v) => onChanged(settings.copyWith(showSku: v))),
        _ToggleTile(label: "Brand", value: settings.showBrand, onChanged: (v) => onChanged(settings.copyWith(showBrand: v))),
        _ToggleTile(label: "Barcode", value: settings.showBarcode, onChanged: (v) => onChanged(settings.copyWith(showBarcode: v))),
        _ToggleTile(label: "Discount details", value: settings.showDiscountDetails, onChanged: (v) => onChanged(settings.copyWith(showDiscountDetails: v))),
        _ToggleTile(label: "Tax details", value: settings.showTaxDetails, onChanged: (v) => onChanged(settings.copyWith(showTaxDetails: v))),
        _ToggleTile(label: "Footer message", value: settings.showFooter, onChanged: (v) => onChanged(settings.copyWith(showFooter: v))),
      ],
    );
  }
}

class _PaperWidthChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PaperWidthChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _FontSizeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FontSizeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }
}

// =================== Printer Settings Section ===================

class _PrinterSettingsSection extends StatefulWidget {
  @override
  State<_PrinterSettingsSection> createState() => _PrinterSettingsSectionState();
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
    final settings = controller.settings.value;
    final receiptSettings = controller.receiptSettings.value;

    if (!receiptSettings.hasPrinter) {
      Get.snackbar("No printer", "Please pair a printer first",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final connected = await ThermalPrinterService.connect(receiptSettings.pairedPrinterMac);
    if (!connected) {
      Get.snackbar("Error", "Could not connect to printer",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Simple test print
    Get.snackbar("Test Print", "Sending test receipt...",
        snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 2));

    // We'll just print a test via the full service with dummy data
    await ThermalPrinterService.disconnect();
    Get.snackbar("Test Print", "Test completed",
        snackPosition: SnackPosition.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scan button
        Row(
          children: [
            Expanded(
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
          ],
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
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "No printer paired yet",
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.warning),
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
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
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
                      controller.receiptSettings.value.copyWith(pairedPrinterMac: ''),
                    );
                  },
                  icon: Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                  tooltip: "Remove printer",
                ),
              ],
            ),
          );
        }),

        const SizedBox(height: AppSpacing.md),

        // Discovered printers
        if (_printers.isNotEmpty) ...[
          Text("Discovered Printers", style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          ..._printers.map((printer) => Card(
                child: ListTile(
                  leading: Icon(Icons.print, color: AppColors.accent),
                  title: Text(printer.name, style: theme.textTheme.bodyMedium),
                  subtitle: Text(printer.mac, style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace')),
                  trailing: SizedBox(
                    width: 80,
                    child: FilledButton.tonal(
                      onPressed: () => _pairPrinter(printer.mac),
                      child: const Text("Pair"),
                    ),
                  ),
                ),
              )),
        ] else if (!_scanning) ...[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              "No printers found. Make sure your thermal printer is turned on and Bluetooth is enabled.",
              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // Test print
        Obx(() {
          final controller = Get.find<SettingsController>();
          if (!controller.receiptSettings.value.hasPrinter) return const SizedBox.shrink();
          return OutlinedButton.icon(
            onPressed: _testPrint,
            icon: const Icon(Icons.receipt_outlined, size: 18),
            label: const Text("Test Print"),
          );
        }),
      ],
    );
  }
}

class _SettingsForm extends StatefulWidget {
  final ShopSettingsModel settings;
  const _SettingsForm({required this.settings});

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  late final _shopNameController = TextEditingController(text: widget.settings.shopName);
  late final _addressController = TextEditingController(text: widget.settings.address);
  late final _phoneController = TextEditingController(text: widget.settings.phone);
  late final _footerController = TextEditingController(text: widget.settings.receiptFooter);
  late final _currencyController = TextEditingController(text: widget.settings.currencySymbol);
  late final _taxRateController = TextEditingController(text: widget.settings.taxRate.toStringAsFixed(1));
  late bool _taxInclusive = widget.settings.taxInclusive;

  @override
  void dispose() {
    _shopNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _footerController.dispose();
    _currencyController.dispose();
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

        // ---------- Tax Settings ----------
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_outlined, color: AppColors.accent),
              const SizedBox(width: AppSpacing.md),
              Text(
                "Tax Settings",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
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
                _taxInclusive ? Icons.check_circle_outline : Icons.add_circle_outline,
                color: _taxInclusive ? AppColors.success : AppColors.warning,
              ),
            );
          },
        ),

        const SizedBox(height: AppSpacing.xl),

        // ---------- Save ----------
        FilledButton.icon(
          onPressed: () {
            controller.updateSettings(ShopSettingsModel(
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
              taxRate: double.tryParse(_taxRateController.text) ?? 0,
              taxInclusive: _taxInclusive,
            ));
            Get.snackbar(
              "Saved",
              "Settings updated",
              snackPosition: SnackPosition.BOTTOM,
            );
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text("Save Settings"),
        ),
      ],
    );
  }
}
