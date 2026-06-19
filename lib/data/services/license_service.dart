import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'dart:io';

/// Service for license key validation via Firebase Firestore.
///
/// Firestore collection: `licenses`
/// Document ID = license key (e.g. "AHMED-2026")
/// Fields: shopName, active, maxDevices, expiresAt, registeredDevices[]
class LicenseService {
  static final _box = Hive.box('settings');

  /// Check if this device is already activated.
  static bool get isActivated {
    return _box.get('license_activated', defaultValue: false) as bool;
  }

  /// Get the activated shop name.
  static String get shopName {
    return _box.get('license_shopName', defaultValue: '') as String;
  }

  /// Get the activated license key.
  static String get licenseKey {
    return _box.get('license_key', defaultValue: '') as String;
  }

  /// Get the license expiry date (null if not set or never expires).
  static DateTime? get expiresAt {
    final str = _box.get('license_expiresAt') as String?;
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  /// Check if license is expired.
  static bool get isExpired {
    final exp = expiresAt;
    if (exp == null) return false;
    return exp.isBefore(DateTime.now());
  }

  /// Days until license expires (null if no expiry).
  static int? get daysUntilExpiry {
    final exp = expiresAt;
    if (exp == null) return null;
    return exp.difference(DateTime.now()).inDays;
  }

  /// Get the deactivation reason (shown on activation screen).
  static String get deactivationReason {
    return _box.get('license_deactivationReason', defaultValue: '') as String;
  }

  /// Check if there's a deactivation reason to show.
  static bool get hasDeactivationReason {
    return (_box.get('license_deactivationReason', defaultValue: '') as String)
        .isNotEmpty;
  }

  /// Clear the deactivation reason (after it's been shown).
  static void clearDeactivationReason() {
    _box.delete('license_deactivationReason');
  }

  /// Check if PIN lock is enabled.
  static bool get isPinEnabled {
    return _box.get('license_pinEnabled', defaultValue: false) as bool;
  }

  /// Get the stored PIN.
  static String get storedPin {
    return _box.get('license_pin', defaultValue: '') as String;
  }

  /// Get this device's unique ID.
  static Future<String> get deviceId async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      return 'android_${android.id}';
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      return 'ios_${ios.identifierForVendor ?? "unknown"}';
    }
    return 'unknown';
  }

  /// Validate a license key against Firestore.
  /// Returns a LicenseResult with success/failure and details.
  static Future<LicenseResult> validateLicense(String key) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('licenses')
          .doc(key.trim().toUpperCase())
          .get();

      if (!doc.exists) {
        return LicenseResult(
          success: false,
          message: 'Invalid license key. Please check and try again.',
        );
      }

      final data = doc.data()!;

      // Check if active
      if (data['active'] != true) {
        return LicenseResult(
          success: false,
          message: 'This license key has been deactivated. Contact support.',
        );
      }

      // Check expiry
      if (data['expiresAt'] != null) {
        final expiresAt = (data['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(DateTime.now())) {
          return LicenseResult(
            success: false,
            message:
                'License expired on ${_formatDate(expiresAt)}. Contact support to renew.',
          );
        }
      }

      final shopName = data['shopName'] as String? ?? 'My Shop';
      final maxDevices = data['maxDevices'] as int? ?? 3;
      final registeredDevices = List<String>.from(
        data['registeredDevices'] ?? [],
      );

      // Check device limit
      final currentDeviceId = await deviceId;

      if (!registeredDevices.contains(currentDeviceId)) {
        if (registeredDevices.length >= maxDevices) {
          return LicenseResult(
            success: false,
            message:
                'Device limit reached ($maxDevices devices max). Contact support to add more devices.',
          );
        }
      }

      // All good — register this device if not already
      if (!registeredDevices.contains(currentDeviceId)) {
        registeredDevices.add(currentDeviceId);
        await FirebaseFirestore.instance
            .collection('licenses')
            .doc(key.trim().toUpperCase())
            .update({'registeredDevices': registeredDevices});
      }

      // Save activation locally
      await _saveActivation(
        key: key.trim().toUpperCase(),
        shopName: shopName,
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
      );

      return LicenseResult(
        success: true,
        message: 'Activated successfully!',
        shopName: shopName,
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e, s) {
      debugPrint('🔥 LICENSE ERROR: $e');
      debugPrint('STACK TRACE: $s');

      // Show user-friendly message instead of raw exception
      String userMessage = 'Connection error. Please check your internet and try again.';
      if (e.toString().contains('permission-denied') || e.toString().contains('PERMISSION_DENIED')) {
        userMessage = 'Access denied. Please contact support.';
      } else if (e.toString().contains('not-found')) {
        userMessage = 'Invalid license key. Please check and try again.';
      }

      return LicenseResult(success: false, message: userMessage);
    }
  }

  /// Background check — verify license is still active (called on app start).
  static Future<bool> verifyActiveLicense() async {
    if (!isActivated) return false;

    try {
      final key = licenseKey;
      if (key.isEmpty) return false;

      final doc = await FirebaseFirestore.instance
          .collection('licenses')
          .doc(key)
          .get();

      if (!doc.exists) {
        await deactivate(reason: 'License key not found. Contact support.');
        return false;
      }
      if (doc.data()?['active'] != true) {
        await deactivate(
          reason:
              'Your license has been deactivated by the administrator. Contact support to reactivate.',
        );
        return false;
      }

      // Check expiry
      if (doc.data()?['expiresAt'] != null) {
        final expiresAt = (doc.data()!['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(DateTime.now())) {
          await deactivate(
            reason:
                'Your license expired on ${_formatDate(expiresAt)}. Contact support to renew your license.',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      // No internet — trust the saved activation
      return isActivated;
    }
  }

  /// Save activation details locally.
  static Future<void> _saveActivation({
    required String key,
    required String shopName,
    DateTime? expiresAt,
  }) async {
    await _box.put('license_activated', true);
    await _box.put('license_key', key);
    await _box.put('license_shopName', shopName);
    if (expiresAt != null) {
      await _box.put('license_expiresAt', expiresAt.toIso8601String());
    }
  }

  /// Set PIN lock (optional feature).
  static Future<void> setPin(String pin) async {
    await _box.put('license_pin', pin);
    await _box.put('license_pinEnabled', pin.isNotEmpty);
  }

  /// Toggle PIN lock on/off.
  static Future<void> togglePin(bool enabled) async {
    await _box.put('license_pinEnabled', enabled);
  }

  /// Verify a PIN.
  static bool verifyPin(String pin) {
    return pin == storedPin;
  }

  /// Deactivate this device (local wipe).
  /// [reason] is saved so the activation screen can show why.
  static Future<void> deactivate({String reason = ''}) async {
    // Save reason BEFORE wiping other fields
    if (reason.isNotEmpty) {
      await _box.put('license_deactivationReason', reason);
    }

    // Try to unregister this device from Firestore
    await _unregisterDevice();

    await _box.delete('license_activated');
    await _box.delete('license_key');
    await _box.delete('license_shopName');
    await _box.delete('license_expiresAt');
    await _box.delete('license_pin');
    await _box.delete('license_pinEnabled');
  }

  /// Remove this device from Firestore registeredDevices list.
  static Future<void> _unregisterDevice() async {
    try {
      final key = _box.get('license_key') as String? ?? '';
      if (key.isEmpty) return;

      final doc = await FirebaseFirestore.instance
          .collection('licenses')
          .doc(key)
          .get();

      if (!doc.exists) return;

      final currentDeviceId = await deviceId;
      final registeredDevices = List<String>.from(
        doc.data()?['registeredDevices'] ?? [],
      );

      if (registeredDevices.contains(currentDeviceId)) {
        registeredDevices.remove(currentDeviceId);
        await FirebaseFirestore.instance
            .collection('licenses')
            .doc(key)
            .update({'registeredDevices': registeredDevices});
      }
    } catch (e) {
      // Silently fail — don't block deactivation if network is down
      debugPrint('⚠️ Failed to unregister device: $e');
    }
  }

  static String _formatDate(DateTime date) {
    // Format as 10 jan 2026
    return '${date.day} ${_monthName(date.month)} ${date.year}';

    // return '${date.day}/${date.month}/${date.year}';
  }

  static String _monthName(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }
}

class LicenseResult {
  final bool success;
  final String message;
  final String? shopName;
  final DateTime? expiresAt;

  LicenseResult({
    required this.success,
    required this.message,
    this.shopName,
    this.expiresAt,
  });
}
