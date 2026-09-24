import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/models/shop_settings_model.dart';
import 'package:ad_shop_pos/data/services/order_totals.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression tests for the checkout money maths.
///
/// These exist because the checkout dialog and `completeSale` used to compute
/// totals independently, and disagreed the moment a checkout discount met
/// tax-exclusive pricing — the dialog taxed the discounted subtotal while the
/// saved record taxed the full one, recording more than the customer paid.
/// Both paths now share [OrderTotals], and these tests pin the numbers down.
void main() {
  CartItemModel item({
    double price = 1000,
    double purchasePrice = 600,
    double discount = 0,
    int qty = 1,
  }) {
    return CartItemModel(
      product: ProductModel(
        id: 'p1',
        name: 'Test product',
        category: 'General',
        price: price,
        purchasePrice: purchasePrice,
        discount: discount,
        stock: 100,
      ),
      quantity: qty,
    );
  }

  group('tax-exclusive pricing', () {
    test('discount is applied before tax, not after', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountPct: 10,
      );

      expect(totals.subtotal, closeTo(1000, 0.001));
      expect(totals.checkoutDiscountAmount, closeTo(100, 0.001));
      // Tax is charged on the discounted 900, not the full 1000.
      expect(totals.taxAmount, closeTo(153, 0.001));
      expect(totals.total, closeTo(1053, 0.001));
    });

    test('the recorded total equals the amount shown at checkout', () {
      // The original bug stored 1070 here (1000 + 170 tax − 100 discount)
      // while the cashier charged 1053.
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountPct: 10,
      );

      expect(totals.total, isNot(closeTo(1070, 0.001)));
      // The saved record must add up on its own terms.
      final reconciled =
          totals.subtotal - totals.checkoutDiscountAmount + totals.taxAmount;
      expect(reconciled, closeTo(totals.total, 0.001));
    });

    test('tax rate of 0 adds nothing', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 0, taxInclusive: false),
        checkoutDiscountPct: 0,
      );

      expect(totals.taxAmount, 0);
      expect(totals.total, closeTo(1000, 0.001));
    });
  });

  group('tax-inclusive pricing', () {
    test('customer pays the discounted subtotal', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: true),
        checkoutDiscountPct: 10,
      );

      expect(totals.total, closeTo(900, 0.001));
      // Tax is the portion already inside the 900.
      expect(totals.taxAmount, closeTo(900 - (900 / 1.17), 0.001));
    });
  });

  group('discount guardrails', () {
    test('a discount above 100% cannot produce a negative total', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountPct: 150,
      );

      expect(totals.checkoutDiscountPct, 100);
      expect(totals.total, greaterThanOrEqualTo(0));
    });

    test('a negative discount is treated as no discount', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountPct: -20,
      );

      expect(totals.checkoutDiscountPct, 0);
      expect(totals.checkoutDiscountAmount, 0);
      expect(totals.total, closeTo(1170, 0.001));
    });
  });

  group('savings and profit', () {
    test('product discount and checkout discount both count as savings', () {
      // 10% off a 1000 product, plus a further 10% at checkout.
      final totals = OrderTotals.calculate(
        items: [item(discount: 10)],
        settings: ShopSettingsModel(taxRate: 0, taxInclusive: false),
        checkoutDiscountPct: 10,
      );

      expect(totals.subtotal, closeTo(900, 0.001)); // 1000 less 10%
      expect(totals.checkoutDiscountAmount, closeTo(90, 0.001));
      expect(totals.savings, closeTo(100 + 90, 0.001));
      // Profit: 900 − 600 cost = 300, less the 90 checkout discount.
      expect(totals.profit, closeTo(210, 0.001));
    });

    test('multiple items and quantities accumulate', () {
      final totals = OrderTotals.calculate(
        items: [item(qty: 3), item(price: 250, purchasePrice: 100, qty: 2)],
        settings: ShopSettingsModel(taxRate: 0, taxInclusive: false),
        checkoutDiscountPct: 0,
      );

      expect(totals.subtotal, closeTo(3500, 0.001)); // 3000 + 500
      expect(totals.profit, closeTo(1500, 0.001)); // 1200 + 300
    });

    test('an empty cart totals zero', () {
      final totals = OrderTotals.calculate(
        items: const [],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
      );

      expect(totals.subtotal, 0);
      expect(totals.taxAmount, 0);
      expect(totals.total, 0);
      expect(totals.profit, 0);
    });
  });
}
