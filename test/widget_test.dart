import 'package:ad_shop_pos/app/widgets/app_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the shared design-system components.
///
/// These deliberately stay clear of `PosApp`: booting the real app needs
/// Firebase and Hive initialised first (see `main.dart`), which is too heavy
/// for a unit-test run. Testing the components directly keeps the suite fast
/// and runnable with a plain `flutter test`.
void main() {
  testWidgets('AppEmptyState renders its content and fires its action', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products yet',
            subtitle: 'Tap "Add product" to get started',
            actionLabel: 'How to add a product',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No products yet'), findsOneWidget);
    expect(find.text('Tap "Add product" to get started'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);

    await tester.tap(find.text('How to add a product'));
    expect(tapped, isTrue);
  });

  testWidgets('AppEmptyState omits the button when no action is given', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching products',
          ),
        ),
      ),
    );

    expect(find.text('No matching products'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
  });
}
