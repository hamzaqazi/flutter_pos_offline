import 'package:ad_shop_pos/app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

/// The displayed amount has to equal the charged amount.
///
/// These cover the bug where a payable total of 1,744.20 was shown as "1,744":
/// the "Exact" chip then filled in 1,744, and the checkout rejected it as
/// insufficient because it was genuinely 20 paisa short.
///
/// `Formatters.currency` reads the currency symbol from Hive inside a
/// try/catch, so with no Hive box initialised it falls back to "Rs" — which is
/// what these expectations assume.
void main() {
  group('currency', () {
    test('whole amounts stay whole', () {
      expect(Formatters.currency(0), 'Rs 0');
      expect(Formatters.currency(1053), 'Rs 1,053');
      expect(Formatters.currency(1744), 'Rs 1,744');
      expect(Formatters.currency(3000), 'Rs 3,000');
    });

    test('fractional amounts keep their decimals', () {
      // The regression: this used to render as "Rs 1,744".
      expect(Formatters.currency(1744.2), 'Rs 1,744.20');
      expect(Formatters.currency(1744.5), 'Rs 1,744.50');
      expect(Formatters.currency(0.05), 'Rs 0.05');
    });

    test('thousands grouping applies only to the integer part', () {
      expect(Formatters.currency(1234567.25), 'Rs 1,234,567.25');
    });

    test('negative amounts keep the sign in front of the digits', () {
      expect(Formatters.currency(-250), 'Rs -250');
      expect(Formatters.currency(-250.5), 'Rs -250.50');
    });

    test('long floats are rounded to two decimals', () {
      expect(Formatters.currency(1744.204), 'Rs 1,744.20');
      expect(Formatters.currency(1744.206), 'Rs 1,744.21');
    });
  });
}
