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

  // Determine initial route based on license activation
  String initialRoute;
  if (!LicenseService.isActivated) {
    initialRoute = Routes.activation;
  } else if (LicenseService.isPinEnabled) {
    initialRoute = Routes.pinLock;
  } else {
    initialRoute = Routes.dashboard;
  }

  runApp(PosApp(initialRoute: initialRoute));
}

class PosApp extends StatelessWidget {
  final String initialRoute;
  const PosApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Shop POS',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: initialRoute,
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
