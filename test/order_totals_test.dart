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
    test('a product discount reduces the taxable value', () {
      // A product's own discount changes its price, so tax follows it down:
      // 1,000 less 10% = 900, taxed at 17% = 153.
      final totals = OrderTotals.calculate(
        items: [item(discount: 10)],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
      );

      expect(totals.subtotal, closeTo(900, 0.001));
      expect(totals.taxAmount, closeTo(153, 0.001));
      expect(totals.total, closeTo(1053, 0.001));
    });

    test('a checkout discount does not change the tax', () {
      // A checkout discount is a reduction of the amount due, not of the
      // goods' value — the tax stays as charged on the line prices.
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountAmount: 100,
      );

      expect(totals.taxAmount, closeTo(170, 0.001));
      expect(totals.total, closeTo(1070, 0.001));
    });

    test('tax rate of 0 adds nothing', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 0, taxInclusive: false),
        checkoutDiscountAmount: 0,
      );

      expect(totals.taxAmount, 0);
      expect(totals.total, closeTo(1000, 0.001));
    });
  });

  group('tax-inclusive pricing', () {
    test('the amount comes off the inclusive bill', () {
      // Price already includes tax, so the bill is 1,000 and Rs 100 off
      // leaves 900 payable. The tax portion is unchanged by the discount.
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: true),
        checkoutDiscountAmount: 100,
      );

      expect(totals.total, closeTo(900, 0.001));
      expect(totals.taxAmount, closeTo(1000 - (1000 / 1.17), 0.001));
    });
  });

  group('checkout discount is a fixed amount', () {
    test('comes off the bill and leaves the tax alone', () {
      // 1,000 of goods, 17% tax-exclusive (170), Rs 100 off the bill.
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountAmount: 100,
      );

      expect(totals.subtotal, closeTo(1000, 0.001));
      expect(totals.taxAmount, closeTo(170, 0.001));
      expect(totals.checkoutDiscountAmount, closeTo(100, 0.001));
      expect(totals.total, closeTo(1070, 0.001));
    });

    test('the reported case: 1,800 line, 2% tax, Rs 90 off', () {
      // Sell 3,000 with a 40% product discount = 1,800; 2% tax = 36.
      // The bill is 1,836, and Rs 90 off makes it 1,746.
      final totals = OrderTotals.calculate(
        items: [item(price: 3000, purchasePrice: 1800, discount: 40)],
        settings: ShopSettingsModel(taxRate: 2, taxInclusive: false),
        checkoutDiscountAmount: 90,
      );

      expect(totals.subtotal, closeTo(1800, 0.001));
      expect(totals.taxAmount, closeTo(36, 0.001));
      expect(totals.total, closeTo(1746, 0.001));
    });

    test('the saved record still reconciles with itself', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountAmount: 100,
      );

      final reconciled =
          totals.subtotal - totals.checkoutDiscountAmount + totals.taxAmount;
      expect(reconciled, closeTo(totals.total, 0.001));
    });

    test('a discount larger than the bill cannot go negative', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountAmount: 5000,
      );

      expect(totals.total, 0);
      expect(totals.total, greaterThanOrEqualTo(0));
    });

    test('a negative discount is treated as no discount', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
        checkoutDiscountAmount: -20,
      );

      expect(totals.checkoutDiscountAmount, 0);
      expect(totals.total, closeTo(1170, 0.001));
    });

    test('no discount leaves the bill untouched', () {
      final totals = OrderTotals.calculate(
        items: [item()],
        settings: ShopSettingsModel(taxRate: 17, taxInclusive: false),
      );

      expect(totals.checkoutDiscountAmount, 0);
      expect(totals.total, closeTo(1170, 0.001));
    });
  });

  group('savings and profit', () {
    test('product discount and checkout discount both count as savings', () {
      // 10% off a 1000 product (= 900), plus Rs 90 off at checkout.
      final totals = OrderTotals.calculate(
        items: [item(discount: 10)],
        settings: ShopSettingsModel(taxRate: 0, taxInclusive: false),
        checkoutDiscountAmount: 90,
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
        checkoutDiscountAmount: 0,
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

  group('returnAllocation', () {
    // The reported case: sell price 3,000 with a 40% product discount gives an
    // 1,800 line, 2% tax-exclusive adds 36, and Rs 90 off leaves 1,746
    // payable. The return dialog used to offer 1,800 — the list price — which
    // over-refunded by 54.
    test('refunds what the customer paid, not the list price', () {
      final allocation = OrderTotals.returnAllocation(
        discountedPrice: 1800,
        purchasePrice: 1800,
        saleSubtotal: 1800,
        saleTotal: 1746,
        saleCheckoutDiscountAmount: 90,
        saleTotalUnits: 1,
      );

      expect(allocation.refundPerUnit, closeTo(1746, 0.001));
      expect(allocation.refundPerUnit, isNot(closeTo(1800, 0.001)));
    });

    test('reversing profit on a full return nets the sale to zero', () {
      // The sale recorded profit = 0 margin − 90 checkout discount = −90.
      const saleProfit = -90.0;
      final allocation = OrderTotals.returnAllocation(
        discountedPrice: 1800,
        purchasePrice: 1800,
        saleSubtotal: 1800,
        saleTotal: 1746,
        saleCheckoutDiscountAmount: 90,
        saleTotalUnits: 1,
      );

      // Reports subtract the reversed profit from the recorded profit.
      expect(saleProfit - allocation.profitPerUnit, closeTo(0, 0.001));
    });

    test('a sale with no checkout discount refunds the paid price', () {
      // 1,800 line with 2% tax-exclusive and no discount: the customer paid
      // 1,836, so that is what comes back.
      final allocation = OrderTotals.returnAllocation(
        discountedPrice: 1800,
        purchasePrice: 1000,
        saleSubtotal: 1800,
        saleTotal: 1836,
        saleCheckoutDiscountAmount: 0,
        saleTotalUnits: 1,
      );

      expect(allocation.refundPerUnit, closeTo(1836, 0.001));
      expect(allocation.profitPerUnit, closeTo(800, 0.001)); // 1800 − 1000
    });

    test('checkout discount is spread across every unit in the sale', () {
      // Two products, 4 units total, Rs 100 off at checkout.
      final allocation = OrderTotals.returnAllocation(
        discountedPrice: 500,
        purchasePrice: 300,
        saleSubtotal: 2000,
        saleTotal: 1900,
        saleCheckoutDiscountAmount: 100,
        saleTotalUnits: 4,
      );

      // 100 spread over 4 units = 25 per unit off the margin.
      expect(allocation.profitPerUnit, closeTo(200 - 25, 0.001));
      // Refund is the paid share: 500 × (1900 / 2000).
      expect(allocation.refundPerUnit, closeTo(475, 0.001));
    });

    test('a zero subtotal cannot divide by zero', () {
      final allocation = OrderTotals.returnAllocation(
        discountedPrice: 250,
        purchasePrice: 100,
        saleSubtotal: 0,
        saleTotal: 0,
        saleCheckoutDiscountAmount: 0,
        saleTotalUnits: 0,
      );

      expect(allocation.refundPerUnit, 250);
      expect(allocation.profitPerUnit, 150);
    });
  });
}
