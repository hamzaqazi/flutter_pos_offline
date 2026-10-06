import 'package:ad_shop_pos/app/widgets/below_cost_warning.dart';
import 'package:ad_shop_pos/data/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ProductModel _product({
  double price = 100,
  double purchasePrice = 100,
  double discount = 0,
}) => ProductModel(
  id: 'p1',
  name: 'Item',
  category: 'General',
  price: price,
  purchasePrice: purchasePrice,
  discount: discount,
  stock: 1,
);

Future<void> _pumpWarning(
  WidgetTester tester, {
  required double price,
  required double purchasePrice,
  required double discountPercent,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: BelowCostWarning(
        price: price,
        purchasePrice: purchasePrice,
        discountPercent: discountPercent,
      ),
    ),
  ),
);

void main() {
  group('ProductModel.lossFor', () {
    test('is 0 while the item sells above cost', () {
      expect(
        ProductModel.lossFor(
          price: 100,
          purchasePrice: 60,
          discountPercent: 20,
        ),
        0,
      );
    });

    test('reports the per-unit loss a discount causes', () {
      // 100 less 40% is 60; it cost 100, so each unit loses 40.
      expect(
        ProductModel.lossFor(
          price: 100,
          purchasePrice: 100,
          discountPercent: 40,
        ),
        40,
      );
    });

    test('is 0 at exactly break-even', () {
      expect(
        ProductModel.lossFor(
          price: 100,
          purchasePrice: 75,
          discountPercent: 25,
        ),
        0,
      );
    });

    test('reports a loss with no discount at all', () {
      expect(
        ProductModel.lossFor(
          price: 90,
          purchasePrice: 100,
          discountPercent: 0,
        ),
        10,
      );
    });

    test('treats an unknown purchase price as no loss', () {
      // Most shops leave the cost blank on some items; 0 must not read as
      // "everything is free to you".
      expect(
        ProductModel.lossFor(
          price: 100,
          purchasePrice: 0,
          discountPercent: 50,
        ),
        0,
      );
    });

    test('ignores float dust that would show equal prices as a loss', () {
      // 10.00 less 64% is 3.5999999999999996 in binary floating point, and the
      // cost is 3.60 — the two prices print identically, so there is no loss
      // to warn about.
      expect(
        ProductModel.lossFor(
          price: 10,
          purchasePrice: 3.6,
          discountPercent: 64,
        ),
        0,
      );
    });
  });

  group('ProductModel below-cost getters', () {
    test('profit, loss and the flag agree with each other', () {
      final losing = _product(purchasePrice: 100, discount: 40);
      expect(losing.discountedPrice, 60);
      expect(losing.profitPerUnit, -40);
      expect(losing.lossPerUnit, 40);
      expect(losing.sellsBelowCost, isTrue);

      final winning = _product(purchasePrice: 40, discount: 40);
      expect(winning.profitPerUnit, 20);
      expect(winning.lossPerUnit, 0);
      expect(winning.sellsBelowCost, isFalse);
    });

    test('discountedPrice is unchanged for existing prices', () {
      expect(_product(price: 3000, discount: 40).discountedPrice, 1800);
      expect(_product(price: 250, discount: 0).discountedPrice, 250);
      expect(_product(price: 250, discount: -5).discountedPrice, 250);
    });

    test('discountedPriceFor matches the getter', () {
      expect(ProductModel.discountedPriceFor(3000, 40), 1800);
      expect(ProductModel.discountedPriceFor(80, 0), 80);
    });
  });

  group('BelowCostWarning', () {
    testWidgets('explains the discount, the cost and the loss', (
      tester,
    ) async {
      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 100,
        discountPercent: 40,
      );

      expect(find.text('Selling below cost'), findsOneWidget);
      expect(
        find.text(
          'Rs 60 each after 40% off, but it costs Rs 100 — '
          'you lose Rs 40 on every unit sold.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('leaves the discount out when there is none', (tester) async {
      await _pumpWarning(
        tester,
        price: 90,
        purchasePrice: 100,
        discountPercent: 0,
      );

      expect(
        find.text(
          'Rs 90 each, but it costs Rs 100 — '
          'you lose Rs 10 on every unit sold.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps a fractional discount honest', (tester) async {
      // 100 less 33.5% is 66.5, so the percentage must not be rounded to a
      // whole number — "34% off" would contradict the price beside it.
      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 70,
        discountPercent: 33.5,
      );

      expect(
        find.text(
          'Rs 66.50 each after 33.5% off, but it costs Rs 70 — '
          'you lose Rs 3.50 on every unit sold.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('keeps a two-decimal discount exact', (tester) async {
      // Both decimals of 33.55 survive, and the loss quoted agrees with the
      // price quoted.
      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 70,
        discountPercent: 33.55,
      );

      expect(
        find.text(
          'Rs 66.45 each after 33.55% off, but it costs Rs 70 — '
          'you lose Rs 3.55 on every unit sold.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('stays quiet while a field is out of range', (tester) async {
      // Save would reject these, so the warning must not quote a nonsense
      // price such as "Rs -50 each after 150% off".
      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 100,
        discountPercent: 150,
      );
      expect(find.text('Selling below cost'), findsNothing);

      await _pumpWarning(
        tester,
        price: -100,
        purchasePrice: 100,
        discountPercent: 40,
      );
      expect(find.text('Selling below cost'), findsNothing);
    });

    testWidgets('shows nothing at or above cost', (tester) async {
      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 75,
        discountPercent: 25,
      );
      expect(find.text('Selling below cost'), findsNothing);

      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 60,
        discountPercent: 10,
      );
      expect(find.text('Selling below cost'), findsNothing);

      await _pumpWarning(
        tester,
        price: 100,
        purchasePrice: 0,
        discountPercent: 50,
      );
      expect(find.text('Selling below cost'), findsNothing);
    });
  });
}
