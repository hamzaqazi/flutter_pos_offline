import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// A license's expiry reaches the app in whatever shape the field happens to
/// hold. The admin panel writes a real `Timestamp`; a date typed into the
/// Firebase console arrives as a string. Both must read the same way — a value
/// the app cannot parse used to abort a whole verification on a cast error and
/// leave the app showing the expiry it was activated with.
void main() {
  group('LicenseService.parseExpiry', () {
    test('reads the Timestamp the admin panel writes', () {
      final date = DateTime(2026, 12, 31);

      expect(LicenseService.parseExpiry(Timestamp.fromDate(date)), date);
    });

    test('reads an ISO string typed into the console', () {
      final date = DateTime(2026, 12, 31);

      expect(LicenseService.parseExpiry(date.toIso8601String()), date);
    });

    test('reads a plain DateTime', () {
      final date = DateTime(2026, 12, 31);

      expect(LicenseService.parseExpiry(date), date);
    });

    test('treats a missing field as no expiry', () {
      expect(LicenseService.parseExpiry(null), isNull);
    });

    test('treats an unreadable value as no expiry', () {
      expect(LicenseService.parseExpiry(12345), isNull);
      expect(LicenseService.parseExpiry('not a date'), isNull);
      expect(LicenseService.parseExpiry(<String, dynamic>{}), isNull);
    });
  });
}
