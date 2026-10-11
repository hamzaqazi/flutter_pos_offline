import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/data/models/sale_model.dart';
import 'package:ad_shop_pos/modules/reports/reports_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// The reported case: a 1,800 line with 2% tax-exclusive adds 36, and Rs 90 off
/// the bill leaves 1,746 payable — of which 36 is tax.
SaleModel _sale({
  String id = 'sale-1',
  double subtotal = 1800,
  double taxAmount = 36,
  double total = 1746,
}) => SaleModel(
  id: id,
  items: const [],
  subtotal: subtotal,
  taxAmount: taxAmount,
  total: total,
  cash: 0,
  change: 0,
  date: DateTime(2026, 1, 1),
);

ReturnModel _return(String saleId, double refundAmount) => ReturnModel(
  id: 'ret-$saleId-$refundAmount',
  saleId: saleId,
  items: const [],
  refundAmount: refundAmount,
  refundProfit: 0,
  date: DateTime(2026, 1, 2),
);

void main() {
  group('SaleModel.taxShareOf', () {
    test('a full refund gives back exactly the tax charged', () {
      expect(_sale().taxShareOf(1746), closeTo(36, 0.001));
    });

    test('a partial refund gives back its proportion of the tax', () {
      // Half the money back, half the tax back.
      expect(_sale().taxShareOf(873), closeTo(18, 0.001));
      expect(_sale().taxShareOf(291), closeTo(6, 0.001));
    });

    test('a sale with no tax gives nothing back', () {
      expect(_sale(taxAmount: 0, total: 1710).taxShareOf(1710), 0);
    });

    test('a zero total cannot divide by zero', () {
      expect(_sale(subtotal: 0, taxAmount: 0, total: 0).taxShareOf(100), 0);
    });
  });

  group('taxRefundedBy', () {
    test('is 0 with no returns', () {
      expect(ReportsController.taxRefundedBy(const [], [_sale()]), 0);
    });

    test('adds up the tax on every refund of the period', () {
      final refunded = ReportsController.taxRefundedBy(
        [_return('sale-1', 873), _return('sale-1', 873)],
        [_sale()],
      );
      expect(refunded, closeTo(36, 0.001));
    });

    test('refunding everything leaves no tax collected', () {
      // What the reports tab shows is tax charged less this figure.
      final sale = _sale();
      final refunded = ReportsController.taxRefundedBy(
        [_return('sale-1', 1746)],
        [sale],
      );
      expect(sale.taxAmount - refunded, closeTo(0, 0.001));
    });

    test('a return whose sale is missing reverses nothing', () {
      // Rather than guess a rate, an orphaned return is left alone.
      expect(
        ReportsController.taxRefundedBy([_return('gone', 500)], [_sale()]),
        0,
      );
    });

    test('only the matching sale is used', () {
      final refunded = ReportsController.taxRefundedBy(
        [_return('sale-2', 1000)],
        [
          _sale(),
          _sale(id: 'sale-2', subtotal: 500, taxAmount: 100, total: 1000),
        ],
      );
      expect(refunded, closeTo(100, 0.001));
    });
  });
}
