// lib/app/modules/home/bindings/home_binding.dart

import 'package:get/get.dart';
import '../home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Injection du vrai HomeController
    Get.lazyPut<HomeController>(() => HomeController());
  }
}
