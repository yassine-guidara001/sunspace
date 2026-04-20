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
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
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

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().setCurrentRoute(initialRoute);
    }

    return GetMaterialApp(
      title: 'SUNSPACE - Coworking & Learning Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: _appTextTheme,
      ),
      routingCallback: (routing) {
        final route = routing?.current;
        if (route == null) return;
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().setCurrentRoute(route);
        }
      },
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        return Obx(() {
          final currentRoute = Get.isRegistered<HomeController>()
              ? Get.find<HomeController>().currentRoute.value
              : initialRoute;
          final isAuthRoute = currentRoute == Routes.LOGIN ||
              currentRoute == Routes.REGISTER ||
              currentRoute == Routes.FORGOT_PASSWORD ||
              currentRoute == Routes.RESET_PASSWORD;
          final showMobileBottomNav = !isAuthRoute && width < 720;
          final bottomNavHeight = showMobileBottomNav ? 60.0 : 0.0;

          return ClipRect(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: bottomNavHeight),
                  child: SizedBox(
                    width: width,
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                if (showMobileBottomNav)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: const _GlobalMobileBottomNav(),
                  ),
              ],
            ),
          );
        });
      },
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    );
  }
}

class _GlobalMobileBottomNav extends StatelessWidget {
  const _GlobalMobileBottomNav();

  int _selectedIndexForRoute(String route) {
    if (route == Routes.HOME) return 0;
    if (route == Routes.PLAN) return 1;
    if (route == Routes.MY_RESERVATIONS) return 2;
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    final rawBottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final compact = MediaQuery.of(context).size.height < 700;
    final bottomInset =
        rawBottomInset > 6 ? 6.0 : (rawBottomInset < 2 ? 2.0 : rawBottomInset);

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        padding: EdgeInsets.fromLTRB(
          8,
          compact ? 4 : 6,
          8,
          compact ? 4 : bottomInset,
        ),
        child: Obx(() {
          final selected =
              _selectedIndexForRoute(controller.currentRoute.value);

          return Row(
            children: [
              Expanded(
                child: _GlobalMobileNavItem(
                  icon: Icons.grid_view,
                  label: 'Tableau',
                  compact: compact,
                  selected: selected == 0,
                  onTap: () => controller.changeMenu(0, Routes.HOME),
                ),
              ),
              Expanded(
                child: _GlobalMobileNavItem(
                  icon: Icons.location_on_outlined,
                  label: 'Réserver',
                  compact: compact,
                  selected: selected == 1,
                  onTap: () => controller.changeMenu(1, Routes.PLAN),
                ),
              ),
              Expanded(
                child: _GlobalMobileNavItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Mes',
                  compact: compact,
                  selected: selected == 2,
                  onTap: () => controller.changeMenu(2, Routes.MY_RESERVATIONS),
                ),
              ),
              Expanded(
                child: _GlobalMobileNavItem(
                  icon: Icons.menu,
                  label: 'Menu',
                  compact: compact,
                  selected: false,
                  onTap: () => CustomSidebar.openDrawerMenu(context),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _GlobalMobileNavItem extends StatelessWidget {
  const _GlobalMobileNavItem({
    required this.icon,
    required this.label,
    required this.compact,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool compact;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor =
        selected ? const Color(0xFF0B6BFF) : const Color(0xFF64748B);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: compact ? 44 : 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: compact ? 17 : 19, color: activeColor),
              SizedBox(height: compact ? 2 : 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: activeColor,
                ),
              ),
            ],
          ),
        ),
      ),
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
