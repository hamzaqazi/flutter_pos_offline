import 'package:ad_shop_pos/modules/sales/sales_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> _pump(WidgetTester tester, RxString query) => tester.pumpWidget(
  MaterialApp(home: Scaffold(body: SalesSearchField(query: query))),
);

/// The text the box is currently showing.
String _shown(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  group('SalesSearchField', () {
    testWidgets('starts from the shared filter value', (tester) async {
      await _pump(tester, 'INV-1001'.obs);

      expect(_shown(tester), 'INV-1001');
    });

    testWidgets('writes what is typed into the shared filter', (tester) async {
      final query = ''.obs;
      await _pump(tester, query);

      await tester.enterText(find.byType(TextField), 'INV-1001');

      expect(query.value, 'INV-1001');
      expect(_shown(tester), 'INV-1001');
    });

    testWidgets('empties the box when the filter is cleared elsewhere', (
      tester,
    ) async {
      final query = 'INV-1001'.obs;
      await _pump(tester, query);

      // What the screen's "clear filters" button does to the shared value.
      query.value = '';
      await tester.pump();

      expect(_shown(tester), isEmpty);
    });

    testWidgets('the clear button empties the box and the filter', (
      tester,
    ) async {
      final query = 'INV-1001'.obs;
      await _pump(tester, query);

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      expect(query.value, isEmpty);
      expect(_shown(tester), isEmpty);
    });

    testWidgets('follows a filter handed to it later', (tester) async {
      // The screen re-finds its controller on every build, so the field can be
      // handed a different filter — it must follow the new one.
      final first = 'INV-1'.obs;
      await _pump(tester, first);

      final second = 'INV-2'.obs;
      await _pump(tester, second);
      await tester.pump();

      expect(_shown(tester), 'INV-2');

      // The filter it no longer belongs to must not drive the box.
      first.value = 'INV-3';
      await tester.pump();

      expect(_shown(tester), 'INV-2');
    });

    testWidgets('stops listening once it leaves the tree', (tester) async {
      // The field disposes its own text controller on the way out, so a late
      // filter change must find nothing listening — this is the "used after
      // being disposed" crash, in miniature.
      final query = ''.obs;
      await _pump(tester, query);

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      query.value = 'INV-9';
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
