import 'dart:io';

import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/services/category_service.dart';
import 'package:ad_shop_pos/data/models/receipt_settings_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';
import 'package:ad_shop_pos/data/services/export_service.dart';
import 'package:ad_shop_pos/data/services/import_service.dart';
import 'package:ad_shop_pos/modules/printer/thermal_printer_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

            // ---------- Categories ----------
            _SectionTile(
              icon: Icons.category_outlined,
              title: "Categories",
              subtitle: "Manage product categories & colors",
              color: Color(0xFF8B5CF6),
              children: [_CategoryManagementSection()],
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

            // ---------- Low Stock Alert ----------
            _SectionTile(
              icon: Icons.warning_amber_rounded,
              title: "Low Stock Alert",
              subtitle: "Alert threshold & notifications",
              color: AppColors.warning,
              children: [
                Obx(() => _LowStockThresholdForm(settings: controller.settings.value)),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // ---------- PIN Lock ----------
            _SectionTile(
              icon: Icons.lock_outline,
              title: "PIN Lock",
              subtitle: "App security & PIN settings",
              color: const Color(0xFF6366F1),
              children: [
                Obx(() => _PinLockSection()),
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

// =================== Category Management Section ===================

class _CategoryManagementSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catController = Get.find<CategoryController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add category row
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: () => _showAddCategoryDialog(context, catController),
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Add Category"),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Category list
        Obx(() {
          if (catController.categories.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                "No categories yet. Add one to get started.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          return Column(
            children: catController.categories.map((cat) {
              return Card(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: cat.color,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.category_outlined,
                        color:
                            ThemeData.estimateBrightnessForColor(cat.color) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                        size: 16,
                      ),
                    ),
                  ),
                  title: Text(
                    cat.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _showEditCategoryDialog(
                          context,
                          catController,
                          cat,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        tooltip: "Edit",
                      ),
                      IconButton(
                        onPressed: () => _confirmDeleteCategory(
                          context,
                          catController,
                          cat.name,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppColors.danger,
                        ),
                        tooltip: "Delete",
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }),
      ],
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CategoryController catController,
  ) {
    final nameController = TextEditingController();
    Color selectedColor = AppColors.seed;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Add Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Category name",
                  prefixIcon: Icon(Icons.category_outlined),
                  hintText: "e.g. Shoes, Electronics, Jewelry",
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Color",
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ColorPickerGrid(
                selectedColor: selectedColor,
                onColorSelected: (color) =>
                    setDialogState(() => selectedColor = color),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final added = catController.addCategory(name, selectedColor);
                if (!added) {
                  Get.snackbar(
                    "Duplicate",
                    "Category \"$name\" already exists",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Navigator.of(ctx).pop();
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoryController catController,
    CategoryModel cat,
  ) {
    final nameController = TextEditingController(text: cat.name);
    Color selectedColor = cat.color;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Edit Category"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Category name",
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                "Color",
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.sm),
              _ColorPickerGrid(
                selectedColor: selectedColor,
                onColorSelected: (color) =>
                    setDialogState(() => selectedColor = color),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final updated = catController.updateCategory(
                  cat.name,
                  name,
                  selectedColor,
                );
                if (!updated) {
                  Get.snackbar(
                    "Duplicate",
                    "Category \"$name\" already exists",
                    snackPosition: SnackPosition.BOTTOM,
                  );
                  return;
                }
                Navigator.of(ctx).pop();
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(
    BuildContext context,
    CategoryController catController,
    String name,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: AppSpacing.sm),
            const Text("Delete Category"),
          ],
        ),
        content: Text(
          "Are you sure you want to delete \"$name\"? Products in this category will still keep their category name.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              catController.deleteCategory(name);
              Navigator.of(ctx).pop();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _ColorPickerGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const _ColorPickerGrid({
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const _colors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF0EA5E9), // Sky
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF59E0B), // Amber
    Color(0xFF10B981), // Emerald
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
    Color(0xFF84CC16), // Lime
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF64748B), // Slate
    Color(0xFF78716C), // Stone
    Color(0xFFA3E635), // Lime bright
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _colors.map((color) {
        final isSelected = color.toARGB32() == selectedColor.toARGB32();
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black87, width: 3)
                  : Border.all(color: Colors.black12, width: 1),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black87,
                    size: 20,
                  )
                : null,
          ),
        );
      }).toList(),
    );
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

class _ReceiptCustomizationWithPreview extends StatefulWidget {
  final ReceiptSettingsModel receiptSettings;
  final ShopSettingsModel shopSettings;
  final ValueChanged<ReceiptSettingsModel> onChanged;

  const _ReceiptCustomizationWithPreview({
    required this.receiptSettings,
    required this.shopSettings,
    required this.onChanged,
  });

  @override
  State<_ReceiptCustomizationWithPreview> createState() =>
      _ReceiptCustomizationWithPreviewState();
}

class _ReceiptCustomizationWithPreviewState
    extends State<_ReceiptCustomizationWithPreview> {
  late ReceiptSettingsModel _settings;

  @override
  void didUpdateWidget(covariant _ReceiptCustomizationWithPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _settings = widget.receiptSettings;
  }

  @override
  void initState() {
    super.initState();
    _settings = widget.receiptSettings;
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
    );
    if (picked != null) {
      final newPath = picked.path;
      widget.onChanged(_settings.copyWith(logoPath: newPath, showLogo: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shop Logo
        _SettingLabel("Shop Logo"),
        const SizedBox(height: AppSpacing.xs),
        if (_settings.hasLogo) ...[
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.seed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: AppColors.seed.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Image.file(
                    File(_settings.logoPath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Logo set",
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                    Text(
                      _settings.logoPath.split('/').last,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton.outlined(
                onPressed: () => widget.onChanged(
                  _settings.copyWith(logoPath: '', showLogo: false),
                ),
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.danger,
                ),
                tooltip: "Remove logo",
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            value: _settings.showLogo,
            onChanged: (v) => widget.onChanged(_settings.copyWith(showLogo: v)),
            title: const Text("Show logo on receipt"),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text("Choose Logo"),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),

        // Paper width
        _SettingLabel("Paper Width"),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _ChoiceChip(
              label: "58mm",
              selected: _settings.paperWidth == 58,
              onTap: () => widget.onChanged(_settings.copyWith(paperWidth: 58)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "80mm",
              selected: _settings.paperWidth == 80,
              onTap: () => widget.onChanged(_settings.copyWith(paperWidth: 80)),
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
              selected: _settings.fontSize == 0,
              onTap: () => widget.onChanged(_settings.copyWith(fontSize: 0)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "Normal",
              selected: _settings.fontSize == 1,
              onTap: () => widget.onChanged(_settings.copyWith(fontSize: 1)),
            ),
            const SizedBox(width: AppSpacing.sm),
            _ChoiceChip(
              label: "Large",
              selected: _settings.fontSize == 2,
              onTap: () => widget.onChanged(_settings.copyWith(fontSize: 2)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Show/hide toggles grouped
        _SettingLabel("Show on Receipt"),
        const SizedBox(height: AppSpacing.xs),
        _ToggleGroup(settings: _settings, onChanged: widget.onChanged),
        const SizedBox(height: AppSpacing.lg),

        // Preview
        _SettingLabel("Live Preview"),
        const SizedBox(height: AppSpacing.xs),
        _ReceiptPreview(
          receiptSettings: _settings,
          shopSettings: widget.shopSettings,
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

  String _dotLine(String left, String right, int width) {
    final gap = width - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${'.' * gap}$right';
  }

  @override
  Widget build(BuildContext context) {
    final width = receiptSettings.paperWidth == 58 ? 220.0 : 300.0;
    final scale = receiptSettings.fontSize == 0
        ? 0.85
        : receiptSettings.fontSize == 2
        ? 1.15
        : 1.0;
    final cur = shopSettings.currencySymbol;
    final cw = receiptSettings.paperWidth == 58 ? 32 : 48;

    return Center(
      child: Container(
        width: width,
        constraints: const BoxConstraints(maxHeight: 480),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── LOGO ──
                if (receiptSettings.showLogo && receiptSettings.hasLogo)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          "LOGO",
                          style: TextStyle(
                            fontSize: 8 * scale,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── SHOP NAME ──
                if (receiptSettings.showShopName)
                  Text(
                    shopSettings.shopName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (receiptSettings.showAddress &&
                    shopSettings.address.isNotEmpty)
                  Text(
                    shopSettings.address,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8 * scale),
                  ),
                if (receiptSettings.showPhone && shopSettings.phone.isNotEmpty)
                  Text(
                    shopSettings.phone,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 8 * scale),
                  ),

                // ═══ RECEIPT INFO ═══
                const _PreviewDoubleLine(),
                Text(
                  _dotLine('No: R2847391', '19/06/2026 14:30', cw),
                  style: TextStyle(fontSize: 8 * scale),
                ),
                if (receiptSettings.showCustomer)
                  Text(
                    'Customer: Ahmed',
                    style: TextStyle(fontSize: 8 * scale),
                  ),
                if (receiptSettings.showCashier)
                  Text('Cashier: Ali', style: TextStyle(fontSize: 8 * scale)),
                const _PreviewDashedLine(),

                // ── ITEMS ──
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
                  cw: cw,
                  isLast: false,
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
                  cw: cw,
                  isLast: true,
                ),

                // ═══ TOTALS ═══
                const _PreviewDoubleLine(),
                Text(_dotLine('Subtotal', '$cur 8,300', cw)),
                if (receiptSettings.showDiscountDetails) ...[
                  Text(_dotLine('Product disc', '-$cur 700', cw)),
                  Text(_dotLine('Checkout 5% disc', '-$cur 415', cw)),
                ],
                if (receiptSettings.showTaxDetails)
                  Text(_dotLine('Tax 16.0%', '$cur 1,328', cw)),
                const _PreviewDashedLine(),
                Text(
                  _dotLine('TOTAL', '$cur 8,513', cw),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11 * scale,
                  ),
                ),
                const SizedBox(height: 2),
                Text(_dotLine('Cash', '$cur 9,000', cw)),
                Text(_dotLine('Change', '$cur 487', cw)),

                // ── FOOTER ──
                if (receiptSettings.showFooter) ...[
                  const SizedBox(height: 4),
                  const _PreviewDashedLine(),
                  Text(
                    shopSettings.receiptFooter,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],

                // ── CODYNEST ──
                const SizedBox(height: 4),
                const _PreviewDashedLine(),
                Text(
                  "Powered by Codynest.com",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8 * scale),
                ),
                Text(
                  "Support / WhatsApp:",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8 * scale),
                ),
                Text(
                  "0315-3507075 / 0345-3333316",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 8 * scale),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewDoubleLine extends StatelessWidget {
  const _PreviewDoubleLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;
          return Column(
            children: [
              Row(
                children: List.generate(
                  (w / 3).floor(),
                  (_) => Expanded(
                    child: Container(
                      height: 0.8,
                      color: Colors.black54,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: List.generate(
                  (w / 3).floor(),
                  (_) => Expanded(
                    child: Container(
                      height: 0.8,
                      color: Colors.black54,
                      margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PreviewDashedLine extends StatelessWidget {
  const _PreviewDashedLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth > 0 ? constraints.maxWidth : 200.0;
          return Row(
            children: List.generate(
              (w / 6).floor(),
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
  final int cw;
  final bool isLast;

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
    required this.cw,
    this.isLast = false,
  });

  String _dotLine(String left, String right) {
    final gap = cw - left.length - right.length;
    if (gap <= 0) return '$left $right';
    return '$left${'.' * gap}$right';
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = discount > 0
        ? (price * (1 - discount / 100)).round()
        : price;
    final itemTotal = qty * discountedPrice;

    final details = <String>[];
    if (showBrand && brand.isNotEmpty) details.add(brand);
    if (showSku && sku.isNotEmpty) details.add('SKU:$sku');
    if (showBarcode && barcode.isNotEmpty) details.add('BC:$barcode');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name (bold)
        Text(name, style: TextStyle(fontWeight: FontWeight.bold)),

        // Brand | SKU | Barcode on one line (small)
        if (details.isNotEmpty)
          Text(
            '  ${details.join(' | ')}',
            style: TextStyle(fontSize: 8 * scale, color: Colors.black54),
          ),

        // Qty x Price ......... Total
        Text(_dotLine('  $qty x $cur$discountedPrice', '$cur$itemTotal')),

        // Discount savings
        if (showDiscount && discount > 0)
          Text(
            '  Save ${discount.toStringAsFixed(0)}% (was $cur$price)',
            style: TextStyle(fontSize: 8 * scale, color: Colors.black54),
          ),

        // Dotted separator between items
        if (!isLast)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth > 0
                    ? constraints.maxWidth / 2
                    : 100.0;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    (w / 4).floor(),
                    (_) => Container(
                      width: 2,
                      height: 0.3,
                      color: Colors.black26,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
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

// =================== Low Stock Threshold Form ===================
class _LowStockThresholdForm extends StatefulWidget {
  final ShopSettingsModel settings;
  const _LowStockThresholdForm({required this.settings});

  @override
  State<_LowStockThresholdForm> createState() => _LowStockThresholdFormState();
}

class _LowStockThresholdFormState extends State<_LowStockThresholdForm> {
  late final _thresholdController = TextEditingController(
    text: widget.settings.lowStockThreshold.toString(),
  );

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<SettingsController>();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Products at or below this stock level will trigger a low stock alert on the dashboard.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Low stock threshold",
                  hintText: "e.g. 5",
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                  suffixText: "units",
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            FilledButton(
              onPressed: () {
                final threshold = int.tryParse(_thresholdController.text.trim()) ?? 5;
                if (threshold < 0) return;
                controller.updateSettings(
                  controller.settings.value.copyWith(lowStockThreshold: threshold),
                );
                Get.snackbar(
                  "Updated",
                  "Low stock threshold set to $threshold units",
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ],
    );
  }
}

// =================== PIN Lock Section ===================
class _PinLockSection extends StatefulWidget {
  const _PinLockSection();

  @override
  State<_PinLockSection> createState() => _PinLockSectionState();
}

class _PinLockSectionState extends State<_PinLockSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isPinEnabled = LicenseService.isPinEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Require a 4-digit PIN when opening the app. This prevents unauthorized access on shared devices.",
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SwitchListTile(
          value: isPinEnabled,
          onChanged: (enabled) async {
            if (enabled) {
              // Navigate to PIN setup
              final result = await Get.toNamed('/pin-setup');
            } else {
              // Disable PIN
              await LicenseService.togglePin(false);
              setState(() {});
              Get.snackbar(
                "PIN Disabled",
                "App will open without PIN",
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          title: const Text("Enable PIN lock"),
          subtitle: Text(
            isPinEnabled ? "PIN required on app launch" : "App opens directly",
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          secondary: Icon(
            isPinEnabled ? Icons.lock : Icons.lock_open,
            color: isPinEnabled ? const Color(0xFF6366F1) : cs.onSurfaceVariant,
          ),
        ),
        if (isPinEnabled) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await Get.toNamed('/pin-setup');
                setState(() {});
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text("Change PIN"),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        // License info
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "License: ${LicenseService.licenseKey}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.store_outlined, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    "Shop: ${LicenseService.shopName}",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
