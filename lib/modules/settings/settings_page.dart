import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';
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
          ],
        ),
      ),
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
