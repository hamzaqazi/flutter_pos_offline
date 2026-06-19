import 'package:ad_shop_pos/app/routes/app_routes.dart';
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
    if (!LicenseService.isActivated) {
      // Not activated → show activation screen
      setState(() {
        _initialRoute = Routes.activation;
        _checking = false;
      });
      return;
    }

    // Already activated — verify with Firestore (background check)
    final stillValid = await LicenseService.verifyActiveLicense();

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
                Icon(Icons.storefront, size: 64, color: AppColors.seed),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Verifying license...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
