import 'package:ad_shop_pos/app/theme/app_theme.dart';
import 'package:ad_shop_pos/app/widgets/app_stat_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps the card at a narrow but realistic tile width — a dashboard tile on
/// a 360 dp phone, less the page and card padding. This is the width where a
/// card carrying a trend chip *and* a tooltip button used to overflow.
Future<void> _pumpCard(
  WidgetTester tester, {
  String? trend,
  bool? trendUp,
  String? tooltip,
}) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 140,
          height: 120,
          child: AppStatCard(
            label: 'Net Profit',
            value: 'Rs 1,000',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.violet,
            trend: trend,
            trendUp: trendUp,
            tooltip: tooltip,
          ),
        ),
      ),
    ),
  ),
);

const _expenses = 'Exp: Rs 12,500';
const _explanation = 'Net Profit = Profit minus Expenses';

void main() {
  group('AppStatCard icon row', () {
    testWidgets('keeps a long chip and the button inside a narrow card', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        trend: _expenses,
        trendUp: false,
        tooltip: _explanation,
      );

      // An overflow is reported as a layout error, so any overflow at all —
      // however wide the chip's text happens to be — reaches this assertion.
      expect(tester.takeException(), isNull);
      expect(find.text(_expenses), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byTooltip(_explanation), findsOneWidget);
    });

    testWidgets('keeps the button when there is no trend', (tester) async {
      await _pumpCard(tester, tooltip: _explanation);

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byTooltip(_explanation), findsOneWidget);
      expect(find.byIcon(Icons.trending_flat_rounded), findsNothing);
    });

    testWidgets('keeps the chip when there is no tooltip', (tester) async {
      await _pumpCard(tester, trend: _expenses, trendUp: false);

      expect(tester.takeException(), isNull);
      expect(find.text(_expenses), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsNothing);
    });

    testWidgets('adds nothing to the row when given neither', (tester) async {
      await _pumpCard(tester);

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.info_outline), findsNothing);
      expect(find.byIcon(Icons.trending_down_rounded), findsNothing);
    });
  });
}
