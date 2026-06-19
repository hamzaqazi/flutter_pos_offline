import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
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
            message: 'License expired on ${_formatDate(expiresAt)}. Contact support to renew.',
          );
        }
      }

      final shopName = data['shopName'] as String? ?? 'My Shop';
      final maxDevices = data['maxDevices'] as int? ?? 3;
      final registeredDevices = List<String>.from(data['registeredDevices'] ?? []);

      // Check device limit
      final currentDeviceId = await deviceId;

      if (!registeredDevices.contains(currentDeviceId)) {
        if (registeredDevices.length >= maxDevices) {
          return LicenseResult(
            success: false,
            message: 'Device limit reached ($maxDevices/${maxDevices}). Contact support to add more devices.',
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
    } catch (e) {
      // If no internet, check if we have a saved activation
      if (isActivated) {
        return LicenseResult(
          success: true,
          message: 'Offline — using saved activation',
          shopName: shopName,
        );
      }
      return LicenseResult(
        success: false,
        message: 'Connection error. Please check your internet and try again.',
      );
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

      if (!doc.exists) return false;
      if (doc.data()?['active'] != true) {
        // License revoked remotely — deactivate
        await deactivate();
        return false;
      }

      // Check expiry
      if (doc.data()?['expiresAt'] != null) {
        final expiresAt = (doc.data()!['expiresAt'] as Timestamp).toDate();
        if (expiresAt.isBefore(DateTime.now())) {
          await deactivate();
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
  static Future<void> deactivate() async {
    await _box.delete('license_activated');
    await _box.delete('license_key');
    await _box.delete('license_shopName');
    await _box.delete('license_expiresAt');
    await _box.delete('license_pin');
    await _box.delete('license_pinEnabled');
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
