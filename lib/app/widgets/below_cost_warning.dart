import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:ad_shop_pos/app/widgets/app_banner.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:flutter/material.dart';

/// Warns when a product's discount takes its sell price under what it cost.
///
/// Advisory only: selling at a loss is sometimes deliberate (clearing stock,
/// matching a rival), so nothing here blocks a save. It renders nothing while
/// the item still sells at or above cost, or when the cost price is unknown.
///
/// Takes raw field values rather than a [ProductModel] so the product forms
/// can show the warning while the numbers are still being typed.
class BelowCostWarning extends StatelessWidget {
  const BelowCostWarning({
    super.key,
    required this.price,
    required this.purchasePrice,
    required this.discountPercent,
  });

  final double price;
  final double purchasePrice;
  final double discountPercent;

  @override
  Widget build(BuildContext context) {
    // Input the form would refuse to save has nothing worth saying here — a
    // discount of 150% would otherwise be announced as a negative price.
    final outOfRange =
        price < 0 ||
        purchasePrice < 0 ||
        discountPercent < 0 ||
        discountPercent > 100;
    if (outOfRange) return const SizedBox.shrink();

    final loss = ProductModel.lossFor(
      price: price,
      purchasePrice: purchasePrice,
      discountPercent: discountPercent,
    );
    if (loss <= 0) return const SizedBox.shrink();

    final sellPrice = ProductModel.discountedPriceFor(price, discountPercent);
    final afterDiscount = discountPercent > 0
        ? " after ${_percent(discountPercent)} off"
        : "";

    return AppBanner.warning(
      icon: Icons.trending_down,
      title: "Selling below cost",
      subtitle:
          "${Formatters.currency(sellPrice)} each$afterDiscount, but it "
          "costs ${Formatters.currency(purchasePrice)} — you lose "
          "${Formatters.currency(loss)} on every unit sold.",
    );
  }

  /// "40%", "33.5%", "33.55%" — trailing zeros trimmed, so the percentage
  /// beside the price is the exact one the price was worked out from. Rounding
  /// 33.55 to "34%" would make the sentence contradict itself.
  static String _percent(double value) {
    final trimmed = value
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'\.?0+$'), '');
    return "$trimmed%";
  }
}
