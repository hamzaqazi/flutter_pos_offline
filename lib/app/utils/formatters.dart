import 'package:hive/hive.dart';

/// Lightweight formatting helpers (no extra packages required).
class Formatters {
  /// Formats a number with thousands separators, e.g. 12345 -> "12,345".
  static String _thousands(String digits) {
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Formats an amount as "Rs 12,345" (no decimals).
  /// Uses the currency symbol from shop settings if available.
  static String currency(num value) {
    final rounded = value.round().abs();
    final sign = value < 0 ? '-' : '';
    String symbol = 'Rs';
    try {
      final box = Hive.box('settings');
      final data = box.get('shop');
      if (data != null && data['currencySymbol'] != null) {
        symbol = data['currencySymbol'];
      }
    } catch (_) {}
    return '$symbol $sign${_thousands(rounded.toString())}';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// Formats a date as "12 Jun 2026, 03:45 PM".
  static String dateTime(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = _months[date.month - 1];
    final y = date.year;
    int hour = date.hour % 12;
    if (hour == 0) hour = 12;
    final min = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$d $m $y, ${hour.toString().padLeft(2, '0')}:$min $period';
  }

  /// Short date "12 Jun 2026".
  static String dateShort(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = _months[date.month - 1];
    return '$d $m ${date.year}';
  }
}
