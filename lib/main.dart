import 'dart:async';

import 'package:ad_shop_pos/app/routes/app_routes.dart';
import 'package:ad_shop_pos/app/utils/backup_io_bridge.dart';
import 'package:ad_shop_pos/data/services/auto_backup_service.dart';
import 'package:ad_shop_pos/data/services/google_drive_service.dart';
import 'package:ad_shop_pos/data/services/license_service.dart';
import 'package:ad_shop_pos/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/bindings/initial_binding.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  await Hive.openBox('products');
  await Hive.openBox('sales');
  await Hive.openBox('settings');
  await Hive.openBox('expenses');
  await Hive.openBox('returns');
  await Hive.openBox('customers');
  await Hive.openBox('staff');
  await Hive.openBox('categories');
  await Hive.openBox('held_carts');
  // Web backups stored in Hive (IndexedDB on web) instead of filesystem
  await Hive.openBox(AutoBackupService.webBackupBoxName);

  // Initialize Workmanager for auto-backup scheduling (native only).
  // On web, this is a no-op — web uses in-app check on launch instead.
  if (!kIsWeb) {
    await initWorkmanager();
  }

  // Schedule auto-backup if enabled
  if (AutoBackupService.isEnabled) {
    await AutoBackupService.scheduleAutoBackup();
  }

  // Restore Google Drive session silently so the account stays signed in.
  unawaited(GoogleDriveService.ensureInitialized());

  runApp(const PosApp());
}

class PosApp extends StatefulWidget {
  const PosApp({super.key});

  @override
  State<PosApp> createState() => _PosAppState();
}

class _PosAppState extends State<PosApp> {
  bool _checking = true;
  String _initialRoute = Routes.activation;

  @override
  void initState() {
    super.initState();
    _determineStartRoute();
  }

  Future<void> _determineStartRoute() async {
    // ── First install: go to activation screen ──
    // User must choose: Free Trial (with phone verification) or License Key.
    // No auto-start trial — user must explicitly choose and verify phone.
    if (LicenseService.isFirstInstall) {
      // Check Firestore to see if trial card should be shown
      final eligible = await LicenseService.checkDeviceTrialEligibility();
      if (eligible == false) {
        // Device already used a trial (data was cleared) — block repeat trial
        await LicenseService.markTrialAlreadyUsed();
        debugPrint('⚠️ Device already used trial — repeat trial blocked');
      }
      // Always go to activation screen — user makes the choice
      setState(() {
        _initialRoute = Routes.activation;
        _checking = false;
      });
      return;
    }

    // ── Check if trial just expired ──
    if (LicenseService.trialJustExpired) {
      LicenseService.expireTrial();
      debugPrint('⚠️ Trial expired — downgraded to free tier');
    }

    // ── Trial active (no license key needed) → go to app ──
    if (LicenseService.isTrialActive && !LicenseService.isActivated) {
      setState(() {
        _initialRoute = LicenseService.isPinEnabled
            ? Routes.pinLock
            : Routes.dashboard;
        _checking = false;
      });
      // Auto-backup check
      if (AutoBackupService.isEnabled) {
        AutoBackupService.checkAndRunIfNeeded();
      }
      return;
    }

    // ── Not activated (no trial, no license) → activation screen ──
    if (!LicenseService.isActivated) {
      setState(() {
        _initialRoute = Routes.activation;
        _checking = false;
      });
      return;
    }

    // ── Activated — verify with Firestore (with 8-second timeout) ──
    bool stillValid;
    try {
      stillValid = await LicenseService.verifyActiveLicense().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          // Timeout — trust the saved activation (offline mode)
          return LicenseService.isActivated;
        },
      );
    } catch (e) {
      // Any error — trust saved activation
      stillValid = LicenseService.isActivated;
    }

    if (!stillValid) {
      // License revoked or expired — back to activation
      setState(() {
        _initialRoute = Routes.activation;
        _checking = false;
      });
      return;
    }

    // License valid — check PIN
    setState(() {
      _initialRoute = LicenseService.isPinEnabled
          ? Routes.pinLock
          : Routes.dashboard;
      _checking = false;
    });

    // Check if auto-backup is due (runs in background, doesn't block UI)
    if (AutoBackupService.isEnabled) {
      AutoBackupService.checkAndRunIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show splash/loading while checking license
    if (_checking) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // App logo
                Image.asset(
                  'lib/assets/images/cn_pos_logo_rm.png',
                  height: 120,
                ),

                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  LicenseService.isFirstInstall
                      ? 'Setting up your trial...'
                      : 'Verifying license...',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GetMaterialApp(
      title: 'Shop POS',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: _initialRoute,
      getPages: AppPages.pages,
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
        );
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
