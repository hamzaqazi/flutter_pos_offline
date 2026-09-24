import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';

/// Money math for the cart and checkout — one implementation, shared by the
/// checkout dialog, the invoice preview and the saved sale record.
///
/// Keeping this in a single place is what guarantees the total the cashier
/// sees is the total that gets stored. Previously the checkout dialog and
/// `SalesController.completeSale` each did their own arithmetic, and the two
/// disagreed as soon as a checkout discount met tax-exclusive pricing: the
/// dialog taxed the *discounted* subtotal while `completeSale` subtracted the
/// discount from a total that had been taxed on the *full* subtotal, so the
/// recorded total was too high by (discount × tax rate).
class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.checkoutDiscountPct,
    required this.checkoutDiscountAmount,
    required this.taxAmount,
    required this.total,
    required this.savings,
    required this.profit,
  });

  /// Sum of line totals, using each product's own discounted price.
  final double subtotal;

  /// The checkout-level discount percentage actually applied, clamped to
  /// 0–100. Callers that need to *reject* an out-of-range value must validate
  /// the raw input themselves — this clamp is a data-safety backstop, not the
  /// validation.
  final double checkoutDiscountPct;

  /// Money taken off by the checkout-level discount.
  final double checkoutDiscountAmount;

  /// Tax charged on the discounted subtotal (the portion already included in
  /// the price, when pricing is tax-inclusive).
  final double taxAmount;

  /// What the customer pays.
  final double total;

  /// Product-level savings plus the checkout discount.
  final double savings;

  /// Profit after the checkout discount, before tax.
  final double profit;

  /// Translates a completed sale's stored figures into the per-unit amounts a
  /// return should use.
  ///
  /// A refund must return what the customer actually paid for those units —
  /// not the line's list price. Returning the list price over-refunds whenever
  /// a checkout discount was applied, so the sale's `total`/`subtotal` ratio is
  /// used as the "what they really paid" multiplier (it captures the checkout
  /// discount and any tax in a single number).
  ///
  /// The profit figure is the unit's pre-tax margin less its share of the
  /// checkout discount, which makes a full return of every line net the sale's
  /// recorded profit back to zero.
  ///
  /// Returns `(refundPerUnit, profitPerUnit)`.
  static ({double refundPerUnit, double profitPerUnit}) returnAllocation({
    required double discountedPrice,
    required double purchasePrice,
    required double saleSubtotal,
    required double saleTotal,
    required double saleCheckoutDiscountPct,
    required int saleTotalUnits,
  }) {
    final paidRatio = saleSubtotal <= 0 ? 1.0 : saleTotal / saleSubtotal;
    final refundPerUnit = discountedPrice * paidRatio;

    final checkoutDiscountAmount =
        saleSubtotal * saleCheckoutDiscountPct / 100;
    final discountPerUnit = saleTotalUnits > 0
        ? checkoutDiscountAmount / saleTotalUnits
        : 0.0;
    final profitPerUnit =
        (discountedPrice - purchasePrice) - discountPerUnit;

    return (refundPerUnit: refundPerUnit, profitPerUnit: profitPerUnit);
  }

  /// Computes every figure the checkout flow needs.
  ///
  /// [checkoutDiscountPct] is clamped to 0–100 so a bad value can never
  /// produce a negative sale record; the UI is responsible for refusing such
  /// input in the first place.
  factory OrderTotals.calculate({
    required Iterable<CartItemModel> items,
    required ShopSettingsModel settings,
    double checkoutDiscountPct = 0,
  }) {
    final pct = checkoutDiscountPct.clamp(0.0, 100.0).toDouble();

    var subtotal = 0.0;
    var productSavings = 0.0;
    var grossProfit = 0.0;
    for (final item in items) {
      subtotal += item.total;
      productSavings += item.savings;
      grossProfit += item.profit;
    }

    final discountAmount = subtotal * pct / 100;
    final discountedSubtotal = subtotal - discountAmount;

    final rate = settings.taxRate;
    final double tax;
    final double total;
    if (settings.taxInclusive) {
      // Prices already include tax, so the tax is the portion inside the
      // discounted subtotal and the customer pays the subtotal itself.
      tax = rate <= 0
          ? 0
          : discountedSubtotal - (discountedSubtotal / (1 + rate / 100));
      total = discountedSubtotal;
    } else {
      // Tax is added on top of the discounted subtotal.
      tax = rate <= 0 ? 0 : discountedSubtotal * rate / 100;
      total = discountedSubtotal + tax;
    }

    return OrderTotals(
      subtotal: subtotal,
      checkoutDiscountPct: pct,
      checkoutDiscountAmount: discountAmount,
      taxAmount: tax,
      total: total,
      savings: productSavings + discountAmount,
      profit: grossProfit - discountAmount,
    );
  }
}
