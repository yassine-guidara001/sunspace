import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_getx_app/app/core/service/http_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/routes/app_pages.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required for DateFormat(..., 'fr_FR') used in reservation tables.
  await initializeDateFormatting('fr_FR');

  // Initialiser GetStorage
  await GetStorage.init();

  // Initialisation des services
  await initServices();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const TextTheme _appTextTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  );

  @override
  Widget build(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final initialRoute =
        storageService.isLoggedIn() ? Routes.HOME : Routes.LOGIN;

    return GetMaterialApp(
      title: 'SUNSPACE - Coworking & Learning Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: _appTextTheme,
      ),
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}

/// Initialisation centralisée des services et controllers
Future<void> initServices() async {
  print('Démarrage des services...');

  // 1️⃣ Stockage local
  await Get.putAsync<StorageService>(() => StorageService().init());

  // 2️⃣ HTTP
  Get.put<HttpService>(HttpService(), permanent: true);

  // 2️⃣bis Auth
  Get.put<AuthService>(AuthService(), permanent: true);

  // 3️⃣ Controllers (après services)
  Get.put<HomeController>(HomeController(), permanent: true);
  Get.put<AuthController>(AuthController(), permanent: true);

  print('Tous les services sont démarrés...');
}
