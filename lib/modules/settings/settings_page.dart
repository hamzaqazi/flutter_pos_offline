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
        const SizedBox(height: AppSpacing.xl),

        // ---------- Preview ----------
        Text("Receipt Preview", style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  _shopNameController.text.isEmpty
                      ? "My Shop"
                      : _shopNameController.text,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                ),
                if (_addressController.text.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _addressController.text,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_phoneController.text.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _phoneController.text,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Text(
                  "Items will appear here...",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _footerController.text.isEmpty
                      ? "Thank you for shopping!"
                      : _footerController.text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
            ));
            Get.snackbar(
              "Saved",
              "Shop settings updated",
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
