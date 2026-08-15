import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Service for license key validation via Firebase Firestore.
///
/// Firestore collections:
///   - `licenses` — license key docs (ID = license key, e.g. "CNPO-K7ZM-2XN4-PQ9R")
///   - `trial_devices` — trial device records (ID = device ID, prevents repeat trials)
///
/// License fields: shopName, active, plan, maxDevices, expiresAt, registeredDevices[],
///         customerPhone, activatedAt
/// Trial device fields: trialStartedAt, deviceModel, trialDurationDays
///
/// Plans: "free", "monthly", "yearly", "lifetime"
/// Trial: 14-day free trial on first install, all premium features unlocked.
class LicenseService {
  static final _box = Hive.box('settings');

  // =================== Trial Constants ===================

  /// Number of days the free trial lasts.
  static const int trialDurationDays = 14;

  /// Maximum products allowed on the free plan.
  static const int freeMaxProducts = 14;

  /// Number of days to trust premium status when offline.
  static const int offlineGraceDays = 3;

  // =================== Activation Status ===================

  /// Check if this device is already activated (has a paid license key).
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

  /// Days until license expires (null if no expiry / lifetime).
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

  // =================== Plan & Premium ===================

  /// Get the current plan type.
  /// Returns: "trial", "free", "monthly", "yearly", "lifetime"
  /// Paid plan always supersedes trial — if user has an active license,
  /// we show the paid plan regardless of whether trial is also running.
  static String get plan {
    if (isActivated) {
      return _box.get('license_plan', defaultValue: 'free') as String;
    }
    if (isTrialActive) return 'trial';
    return 'free';
  }

  /// Get the stored plan (without trial override). Used for display purposes.
  static String get storedPlan {
    return _box.get('license_plan', defaultValue: 'free') as String;
  }

  /// Check if the user has premium access (paid plan OR active trial).
  /// Paid plan always supersedes trial — if user has an active license,
  /// we consider them premium via the paid plan, not the trial.
  static bool get isPremium {
    // Paid license overrides everything
    if (isActivated) {
      // Lifetime never expires
      final p = storedPlan;
      if (p == 'lifetime') return true;

      // Monthly / yearly — check expiry
      if (p == 'monthly' || p == 'yearly') {
        if (isExpired) return false;

        // Offline grace: trust premium for N days without verification
        final lastVerifiedStr = _box.get('license_lastVerified') as String?;
        if (lastVerifiedStr != null) {
          final lastVerified = DateTime.tryParse(lastVerifiedStr);
          if (lastVerified != null) {
            final daysSinceVerification = DateTime.now()
                .difference(lastVerified)
                .inDays;
            if (daysSinceVerification < offlineGraceDays) {
              return true;
            }
          }
        }
        return p != 'free';
      }
      return false;
    }

    // No paid license — check trial
    if (isTrialActive) return true;

    // Neither paid nor trial
    return false;
  }

  /// Check if user is on the free tier (no premium, no trial).
  static bool get isFreeTier {
    return !isPremium && !isTrialActive;
  }

  /// Maximum number of products allowed for current plan.
  static int get maxProducts {
    if (isPremium) return 999999; // Unlimited
    return freeMaxProducts;
  }

  // =================== Trial ===================

  /// Check if this is the first time the app is launched (no trial or activation).
  static bool get isFirstInstall {
    return !_box.containsKey('trial_startDate') && !isActivated;
  }

  /// Get the trial start date.
  static DateTime? get trialStartDate {
    final str = _box.get('trial_startDate') as String?;
    if (str == null || str.isEmpty) return null;
    return DateTime.tryParse(str);
  }

  /// Check if the trial is currently active.
  static bool get isTrialActive {
    final start = trialStartDate;
    if (start == null) return false;
    if (_box.get('trial_expired', defaultValue: false) as bool) return false;
    final daysElapsed = DateTime.now().difference(start).inDays;
    return daysElapsed < trialDurationDays;
  }

  /// Days remaining in the trial (0 if expired or no trial).
  static int get trialDaysRemaining {
    final start = trialStartDate;
    if (start == null) return 0;
    final daysElapsed = DateTime.now().difference(start).inDays;
    final remaining = trialDurationDays - daysElapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Start the 14-day free trial.
  /// Also registers the device in Firestore to prevent repeat trials
  /// after clearing app data. [customerPhone] is required for trial
  /// verification — stored in Firestore for WhatsApp follow-up reminders.
  static Future<void> startTrial({String customerPhone = ''}) async {
    await _box.put('trial_startDate', DateTime.now().toIso8601String());
    await _box.put('trial_expired', false);
    if (customerPhone.isNotEmpty) {
      await _box.put('trial_customerPhone', customerPhone);
    }
    // Register device in Firestore to block repeat trials on this device
    await registerTrialDevice(customerPhone: customerPhone);
  }

  /// Mark the trial as expired (called when trial days run out).
  static void expireTrial() {
    _box.put('trial_expired', true);
  }

  /// Check if trial has just expired (was active but now expired).
  /// Used to show "trial expired" message once.
  static bool get trialJustExpired {
    final start = trialStartDate;
    if (start == null) return false;
    final wasNotExpired =
        !(_box.get('trial_expired', defaultValue: false) as bool);
    final daysElapsed = DateTime.now().difference(start).inDays;
    final isNowExpired = daysElapsed >= trialDurationDays;
    return wasNotExpired && isNowExpired;
  }

  // =================== Trial Device Tracking (Firestore) ===================

  /// Check if this device has ever had a trial (even if expired).
  /// Used to determine whether to show the "Start Free Trial" card.
  static bool get hasUsedTrial {
    return _box.containsKey('trial_startDate');
  }

  /// Check if this device can start a NEW trial (never used one, not activated).
  static bool get canStartNewTrial {
    return !hasUsedTrial && !isActivated;
  }

  /// Check Firestore if this device has already used a free trial.
  /// Returns:
  ///   - `true`  → device is eligible (no record found)
  ///   - `false` → device already used a trial (blocked)
  ///   - `null`  → offline / Firestore unreachable (provisional allow)
  static Future<bool?> checkDeviceTrialEligibility() async {
    try {
      final currentDeviceId = await deviceId;
      final doc = await FirebaseFirestore.instance
          .collection('trial_devices')
          .doc(currentDeviceId)
          .get();

      if (doc.exists) {
        debugPrint('⚠️ Device already used trial — repeat blocked');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('⚠️ Trial eligibility check failed (offline?): $e');
      return null; // Can't verify — allow provisional trial
    }
  }

  /// Register this device in Firestore as having used a trial.
  /// Prevents repeat trials on the same device after clearing app data.
  /// [customerPhone] is stored for WhatsApp follow-up reminders.
  static Future<void> registerTrialDevice({String customerPhone = ''}) async {
    try {
      final currentDeviceId = await deviceId;
      String deviceModel = 'unknown';

      if (kIsWeb) {
        final deviceInfo = DeviceInfoPlugin();
        final web = await deviceInfo.webBrowserInfo;
        deviceModel = '${web.browserName.name} ${web.platform ?? ""}'.trim();
        if (deviceModel.isEmpty || deviceModel == 'unknown') {
          deviceModel = 'Web Browser';
        }
      } else {
        final deviceInfo = DeviceInfoPlugin();
        try {
          if (defaultTargetPlatform == TargetPlatform.android) {
            final android = await deviceInfo.androidInfo;
            deviceModel = '${android.brand} ${android.model}';
          } else if (defaultTargetPlatform == TargetPlatform.iOS) {
            final ios = await deviceInfo.iosInfo;
            deviceModel = ios.utsname.machine;
          } else if (defaultTargetPlatform == TargetPlatform.macOS) {
            final mac = await deviceInfo.macOsInfo;
            deviceModel = mac.computerName;
          } else if (defaultTargetPlatform == TargetPlatform.windows) {
            final win = await deviceInfo.windowsInfo;
            deviceModel = win.computerName;
          } else if (defaultTargetPlatform == TargetPlatform.linux) {
            final linux = await deviceInfo.linuxInfo;
            deviceModel = linux.prettyName ?? 'Linux';
          }
        } catch (e) {
          debugPrint('⚠️ Failed to get device model: $e');
        }
      }

      final docData = <String, dynamic>{
        'trialStartedAt': FieldValue.serverTimestamp(),
        'lastUsedAt': FieldValue.serverTimestamp(),
        'deviceModel': deviceModel,
        'trialDurationDays': trialDurationDays,
      };
      if (customerPhone.isNotEmpty) {
        docData['customerPhone'] = customerPhone;
      }

      await FirebaseFirestore.instance
          .collection('trial_devices')
          .doc(currentDeviceId)
          .set(docData);
      debugPrint('✅ Trial device registered in Firestore: $currentDeviceId');

      // Clear pending flag if it was set
      await _box.delete('trial_registrationPending');
    } catch (e) {
      debugPrint('⚠️ Failed to register trial device in Firestore: $e');
      // Mark for retry on next online connection
      await _box.put('trial_registrationPending', true);
    }
  }

  /// Update the "last used" timestamp for this device's trial record.
  /// Called on app start so the admin panel can see when a trial device
  /// was last active.
  static Future<void> _touchTrialDeviceLastUsed() async {
    try {
      final currentDeviceId = await deviceId;
      await FirebaseFirestore.instance
          .collection('trial_devices')
          .doc(currentDeviceId)
          .update({'lastUsedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('⚠️ Failed to update trial device last-used timestamp: $e');
    }
  }

  /// Check if trial registration is pending (failed due to offline).
  static bool get trialRegistrationPending {
    return _box.get('trial_registrationPending', defaultValue: false) as bool;
  }

  /// Retry pending trial device registration (called when app goes online).
  static Future<void> retryTrialRegistration() async {
    if (!trialRegistrationPending) return;
    final phone = _box.get('trial_customerPhone', defaultValue: '') as String;
    await registerTrialDevice(customerPhone: phone);
  }

  /// Get the phone number stored during trial registration.
  static String get trialCustomerPhone {
    return _box.get('trial_customerPhone', defaultValue: '') as String;
  }

  /// Mark that this device has already used a trial (from Firestore record).
  /// Called when Firestore shows device already had trial but local data
  /// was cleared. Sets an old expired trial locally so:
  ///   - `isFirstInstall` returns false (no new auto-trial)
  ///   - `hasUsedTrial` returns true (hides trial card on activation screen)
  static Future<void> markTrialAlreadyUsed() async {
    await _box.put('trial_startDate', DateTime(2020, 1, 1).toIso8601String());
    await _box.put('trial_expired', true);
  }

  // =================== PIN Lock ===================

  /// Check if PIN lock is enabled.
  static bool get isPinEnabled {
    return _box.get('license_pinEnabled', defaultValue: false) as bool;
  }

  /// Get the stored PIN.
  static String get storedPin {
    return _box.get('license_pin', defaultValue: '') as String;
  }

  /// Set PIN lock.
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

  // =================== Device Info ===================

  /// Get this device's unique ID.
  static Future<String> get deviceId async {
    // ── Web: generate a browser fingerprint ──
    if (kIsWeb) {
      // Check if we already have a stored web device ID
      final storedId = _box.get('web_deviceId') as String?;
      if (storedId != null && storedId.isNotEmpty) {
        return 'web_$storedId';
      }
      // Generate a unique ID for this browser instance
      // (stored in Hive so it persists across sessions)
      final newId = DateTime.now().microsecondsSinceEpoch.toString();
      await _box.put('web_deviceId', newId);
      return 'web_$newId';
    }

    // ── Native platforms ──
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = await deviceInfo.androidInfo;
        return 'android_${android.id}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final ios = await deviceInfo.iosInfo;
        return 'ios_${ios.identifierForVendor ?? "unknown"}';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final mac = await deviceInfo.macOsInfo;
        return 'macos_${mac.systemGUID ?? "unknown"}';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final win = await deviceInfo.windowsInfo;
        return 'windows_${win.computerName}';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linux = await deviceInfo.linuxInfo;
        return 'linux_${linux.machineId ?? "unknown"}';
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get device ID: $e');
    }
    return 'unknown';
  }

  // =================== License Validation ===================

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
      final plan = data['plan'] as String? ?? 'lifetime';
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

      // Record when this device was activated / last used
      await _touchLicenseDeviceLastUsed(
        key.trim().toUpperCase(),
        currentDeviceId,
      );

      // Save activation locally
      await _saveActivation(
        key: key.trim().toUpperCase(),
        shopName: shopName,
        plan: plan,
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
      );

      return LicenseResult(
        success: true,
        message: 'Activated successfully!',
        shopName: shopName,
        plan: plan,
        expiresAt: data['expiresAt'] != null
            ? (data['expiresAt'] as Timestamp).toDate()
            : null,
      );
    } catch (e, s) {
      debugPrint('🔥 LICENSE ERROR: $e');
      debugPrint('STACK TRACE: $s');

      String userMessage =
          'Connection error. Please check your internet and try again.';
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        userMessage = 'Access denied. Please contact support.';
      } else if (e.toString().contains('not-found')) {
        userMessage = 'Invalid license key. Please check and try again.';
      }

      return LicenseResult(success: false, message: userMessage);
    }
  }

  /// Background check — verify license is still active (called on app start).
  static Future<bool> verifyActiveLicense() async {
    // Check trial status first
    if (isTrialActive && !isActivated) {
      // Check if trial just expired
      if (trialJustExpired) {
        expireTrial();
        return false;
      }

      // Verify provisional trial: if Firestore registration is pending
      // (started while offline), check eligibility now.
      if (trialRegistrationPending) {
        final eligible = await checkDeviceTrialEligibility();
        if (eligible == false) {
          // Device already used a trial — revoke this provisional one
          await markTrialAlreadyUsed();
          debugPrint(
            '⚠️ Provisional trial revoked — device already used trial',
          );
          return false;
        }
        // Eligible or still offline — try to complete registration
        await retryTrialRegistration();
      }

      await _touchTrialDeviceLastUsed();
      return isTrialActive;
    }

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

      // Check if this device is still registered
      final registeredDevices = List<String>.from(
        doc.data()?['registeredDevices'] ?? [],
      );
      final currentDeviceId = await deviceId;
      if (!registeredDevices.contains(currentDeviceId)) {
        // Device was removed from Firestore — deactivate
        await deactivate(
          reason:
              'This device is no longer registered. The license may have been moved to another device. Contact support if this is unexpected.',
        );
        return false;
      }

      // Update plan from Firestore (in case it was changed server-side)
      final serverPlan = doc.data()?['plan'] as String? ?? storedPlan;
      if (serverPlan != storedPlan) {
        await _box.put('license_plan', serverPlan);
      }

      // Save last verified timestamp for offline grace
      await _box.put('license_lastVerified', DateTime.now().toIso8601String());

      // Update "last used" timestamp for this device on the license record
      await _touchLicenseDeviceLastUsed(key, currentDeviceId);

      return true;
    } catch (e) {
      // No internet — trust the saved activation (with offline grace)
      return isActivated;
    }
  }

  // =================== Save / Deactivate ===================

  /// Save activation details locally.
  /// Also expires the free trial (paid plan supersedes trial) and removes
  /// the device from the trial_devices Firestore collection (they're now
  /// a paying customer, tracked under the license's registeredDevices).
  static Future<void> _saveActivation({
    required String key,
    required String shopName,
    String plan = 'lifetime',
    DateTime? expiresAt,
  }) async {
    await _box.put('license_activated', true);
    await _box.put('license_key', key);
    await _box.put('license_shopName', shopName);
    await _box.put('license_plan', plan);
    await _box.put('license_lastVerified', DateTime.now().toIso8601String());
    if (expiresAt != null) {
      await _box.put('license_expiresAt', expiresAt.toIso8601String());
    } else {
      await _box.delete('license_expiresAt');
    }

    // ── Paid plan supersedes trial ──
    // Expire the local trial so isTrialActive returns false
    // (trial_startDate is kept so hasUsedTrial still works)
    await _box.put('trial_expired', true);

    // Remove this device from trial_devices Firestore
    // (it's now tracked under the license's registeredDevices)
    await _removeTrialDeviceRecord();
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
    await _box.delete('license_plan');
    await _box.delete('license_lastVerified');
    await _box.delete('license_pin');
    await _box.delete('license_pinEnabled');
    // Keep trial_startDate so we know trial was used — don't delete it
  }

  /// Remove this device from Firestore trial_devices collection.
  /// Called when a license is activated — the device is now tracked
  /// under the license's registeredDevices, not under trial_devices.
  static Future<void> _removeTrialDeviceRecord() async {
    try {
      final currentDeviceId = await deviceId;
      await FirebaseFirestore.instance
          .collection('trial_devices')
          .doc(currentDeviceId)
          .delete();
      debugPrint(
        '✅ Removed device from trial_devices (upgraded to paid license)',
      );
    } catch (e) {
      debugPrint('⚠️ Failed to remove trial device record: $e');
    }
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
        await FirebaseFirestore.instance.collection('licenses').doc(key).update(
          {
            'registeredDevices': registeredDevices,
            'deviceLastUsed.$currentDeviceId': FieldValue.delete(),
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ Failed to unregister device: $e');
    }
  }

  /// Update the "last used" timestamp for [deviceId] on the license record,
  /// stored as a `deviceLastUsed.<deviceId>` map entry so the admin panel
  /// can show per-device activity alongside `registeredDevices`.
  static Future<void> _touchLicenseDeviceLastUsed(
    String key,
    String targetDeviceId,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('licenses')
          .doc(key)
          .update({
            'deviceLastUsed.$targetDeviceId': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('⚠️ Failed to update device last-used timestamp: $e');
    }
  }

  // =================== Plan Helpers ===================

  /// Human-readable plan name.
  static String get planDisplayName {
    switch (plan) {
      case 'trial':
        return 'Free Trial';
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'lifetime':
        return 'Lifetime';
      case 'free':
      default:
        return 'Free';
    }
  }

  /// Plan display name with emoji.
  static String get planDisplayWithEmoji {
    switch (plan) {
      case 'trial':
        return '🎁  Free Trial';
      case 'monthly':
        return '📅  Monthly';
      case 'yearly':
        return '🗓️  Yearly';
      case 'lifetime':
        return '♾️  Lifetime';
      case 'free':
      default:
        return '🎁  Free';
    }
  }

  /// Check if the plan is a paid plan (not free/trial).
  static bool get isPaidPlan {
    final p = storedPlan;
    return p == 'monthly' || p == 'yearly' || p == 'lifetime';
  }

  // =================== Formatting ===================

  static String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
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

/// Result of a license validation attempt.
class LicenseResult {
  final bool success;
  final String message;
  final String? shopName;
  final String? plan;
  final DateTime? expiresAt;

  LicenseResult({
    required this.success,
    required this.message,
    this.shopName,
    this.plan,
    this.expiresAt,
  });
}
