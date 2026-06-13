import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InvoicePage extends StatelessWidget {
  final double total;
  final double cash;
  final double change;

  const InvoicePage({
    super.key,
    required this.total,
    required this.cash,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Invoice")),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Text(
              "SHOP RECEIPT",
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            _row(theme, "Total", Formatters.currency(total)),
            const SizedBox(height: AppSpacing.sm),
            _row(theme, "Cash", Formatters.currency(cash)),
            const SizedBox(height: AppSpacing.sm),
            _row(theme, "Change", Formatters.currency(change)),
            const Spacer(),
            FilledButton(
              onPressed: () => Get.offAllNamed('/'),
              child: const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
