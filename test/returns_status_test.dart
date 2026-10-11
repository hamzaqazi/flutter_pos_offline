import 'package:ad_shop_pos/data/models/cart_item_model.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:ad_shop_pos/data/models/return_model.dart';
import 'package:ad_shop_pos/data/models/sale_model.dart';
import 'package:ad_shop_pos/modules/returns/returns_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a controller with a hand-set returns list.
///
/// `onInit` (and therefore Hive) is only reached through GetX's lifecycle, so
/// a bare constructor is safe to use in a test.
ReturnsController _controller(List<ReturnModel> existing) {
  final controller = ReturnsController();
  controller.returns.addAll(existing);
  return controller;
}

ProductModel _product(String id) => ProductModel(
  id: id,
  name: 'Item $id',
  category: 'General',
  price: 100,
  stock: 0,
);

SaleModel _sale(List<CartItemModel> items) => SaleModel(
  id: 'sale-1',
  items: items,
  subtotal: 0,
  total: 0,
  cash: 0,
  change: 0,
  date: DateTime(2026, 1, 1),
);

ReturnModel _return(String saleId, List<ReturnItemModel> items) {
  final key = items.map((i) => '${i.productId}x${i.returnQty}').join('_');
  return ReturnModel(
    id: 'ret-$saleId-$key',
    saleId: saleId,
    items: items,
    refundAmount: 0,
    refundProfit: 0,
    date: DateTime(2026, 1, 2),
  );
}

ReturnItemModel _returned(String productId, int qty) => ReturnItemModel(
  productId: productId,
  name: 'Item $productId',
  price: 100,
  originalQty: qty,
  returnQty: qty,
  refundPerUnit: 100,
);

void main() {
  final twoOfAAndOneOfB = _sale([
    CartItemModel(product: _product('A'), quantity: 2),
    CartItemModel(product: _product('B'), quantity: 1),
  ]);

  group('hasReturns', () {
    test('is false with no returns and true once one exists', () {
      expect(_controller(const []).hasReturns('sale-1'), isFalse);
      final controller = _controller([
        _return('sale-1', [_returned('A', 1)]),
      ]);
      expect(controller.hasReturns('sale-1'), isTrue);
    });

    test('ignores returns belonging to another sale', () {
      final controller = _controller([
        _return('sale-2', [_returned('A', 1)]),
      ]);
      expect(controller.hasReturns('sale-1'), isFalse);
    });
  });

  group('isFullyReturned', () {
    test('is false for a sale with nothing returned', () {
      expect(_controller(const []).isFullyReturned(twoOfAAndOneOfB), isFalse);
    });

    test('is false while one line still has units outstanding', () {
      final controller = _controller([
        _return('sale-1', [_returned('A', 2)]),
      ]);
      // Both A's are back, but B is not.
      expect(controller.isFullyReturned(twoOfAAndOneOfB), isFalse);
    });

    test('does not count one unit of each as a complete return', () {
      // One unit of A is still with the customer.
      final controller = _controller([
        _return('sale-1', [_returned('A', 1)]),
        _return('sale-1', [_returned('B', 1)]),
      ]);
      expect(controller.isFullyReturned(twoOfAAndOneOfB), isFalse);
    });

    test('is true once every unit of every product is back', () {
      final controller = _controller([
        _return('sale-1', [_returned('A', 1)]),
        _return('sale-1', [_returned('A', 1), _returned('B', 1)]),
      ]);
      expect(controller.isFullyReturned(twoOfAAndOneOfB), isTrue);
    });

    test('is true for a single-line sale returned in full', () {
      final sale = _sale([CartItemModel(product: _product('A'), quantity: 1)]);
      final controller = _controller([
        _return('sale-1', [_returned('A', 1)]),
      ]);
      expect(controller.isFullyReturned(sale), isTrue);
    });

    test('is false for a sale recorded without items', () {
      // Older records can come back from Hive with an empty item list; there
      // is nothing to compare against, so no badge is shown.
      expect(_controller(const []).isFullyReturned(_sale(const [])), isFalse);
    });

    test('partial and full states are mutually exclusive', () {
      final partial = _controller([_return('sale-1', [_returned('A', 1)])]);
      expect(partial.hasReturns('sale-1'), isTrue);
      expect(partial.isFullyReturned(twoOfAAndOneOfB), isFalse);

      final full = _controller([
        _return('sale-1', [_returned('A', 2), _returned('B', 1)]),
      ]);
      expect(full.hasReturns('sale-1'), isTrue);
      expect(full.isFullyReturned(twoOfAAndOneOfB), isTrue);
    });
  });
}
