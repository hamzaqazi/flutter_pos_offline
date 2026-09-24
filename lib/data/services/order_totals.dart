import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';

/// Money math for the cart and checkout — one implementation, shared by the
/// checkout dialog, the invoice preview and the saved sale record.
///
/// Keeping this in a single place is what guarantees the total the cashier
/// sees is the total that gets stored. The checkout dialog and
/// `SalesController.completeSale` previously did their own arithmetic and
/// disagreed as soon as a checkout discount met tax-exclusive pricing.
class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.checkoutDiscountAmount,
    required this.taxAmount,
    required this.total,
    required this.savings,
    required this.profit,
  });

  /// Sum of line totals, using each product's own discounted price.
  final double subtotal;

  /// Money taken off the bill by the checkout discount.
  ///
  /// This is an absolute amount, not a percentage — the cashier enters
  /// "100" for Rs 100 off. Callers that need to *reject* an out-of-range
  /// value must validate it themselves; the clamp here is a data-safety
  /// backstop.
  final double checkoutDiscountAmount;

  /// Tax on the goods, as the portion already included in the price when
  /// pricing is tax-inclusive.
  final double taxAmount;

  /// What the customer pays.
  final double total;

  /// Product-level savings plus the checkout discount.
  final double savings;

  /// Profit after the checkout discount, before tax.
  final double profit;

  /// Computes every figure the checkout flow needs.
  ///
  /// The checkout discount is a **bill-level reduction**: it comes off the
  /// amount due after tax, rather than shrinking the taxable value. A product's
  /// own discount is different — that changes the item's price, so tax is
  /// charged on the reduced price. This is why a Rs 90 checkout discount on an
  /// 1,800 subtotal at 2% tax leaves the tax at 36 and the bill at 1,746.
  ///
  /// [checkoutDiscountAmount] is clamped to the bill so a bad value can never
  /// produce a negative sale record; the UI refuses such input in the first
  /// place.
  factory OrderTotals.calculate({
    required Iterable<CartItemModel> items,
    required ShopSettingsModel settings,
    double checkoutDiscountAmount = 0,
  }) {
    var subtotal = 0.0;
    var productSavings = 0.0;
    var grossProfit = 0.0;
    for (final item in items) {
      subtotal += item.total;
      productSavings += item.savings;
      grossProfit += item.profit;
    }

    final rate = settings.taxRate;
    final double tax;
    if (settings.taxInclusive) {
      tax = rate <= 0 ? 0 : subtotal - (subtotal / (1 + rate / 100));
    } else {
      tax = rate <= 0 ? 0 : subtotal * rate / 100;
    }

    // Never discount more than the amount actually owed.
    final billBeforeDiscount = subtotal + (settings.taxInclusive ? 0 : tax);
    final discount = checkoutDiscountAmount
        .clamp(0.0, billBeforeDiscount)
        .toDouble();
    final total = billBeforeDiscount - discount;

    return OrderTotals(
      subtotal: subtotal,
      checkoutDiscountAmount: discount,
      taxAmount: tax,
      total: total,
      savings: productSavings + discount,
      profit: grossProfit - discount,
    );
  }

  /// Translates a completed sale's stored figures into the per-unit amounts a
  /// return should use.
  ///
  /// A refund must return what the customer actually paid for those units —
  /// not the line's list price. Returning the list price over-refunds whenever
  /// a checkout discount was applied, so the sale's `total`/`subtotal` ratio is
  /// used as the "what they really paid" multiplier.
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
    required double saleCheckoutDiscountAmount,
    required int saleTotalUnits,
  }) {
    final paidRatio = saleSubtotal <= 0 ? 1.0 : saleTotal / saleSubtotal;
    final refundPerUnit = discountedPrice * paidRatio;

    final discountPerUnit = saleTotalUnits > 0
        ? saleCheckoutDiscountAmount / saleTotalUnits
        : 0.0;
    final profitPerUnit = (discountedPrice - purchasePrice) - discountPerUnit;

    return (refundPerUnit: refundPerUnit, profitPerUnit: profitPerUnit);
  }
}
