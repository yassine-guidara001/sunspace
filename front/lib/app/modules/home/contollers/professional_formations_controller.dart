import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';

class ProfessionalFormationsController extends GetxController {
  static const int _professionalFormationsMenuIndex = 20;

  final CoursesApi _coursesApi;
  final AuthService _authService;

  Worker? _menuWorker;

  ProfessionalFormationsController({
    CoursesApi? coursesApi,
    AuthService? authService,
  })  : _coursesApi = coursesApi ?? CoursesApi(),
        _authService = authService ?? Get.find<AuthService>();

  final RxList<Course> courses = <Course>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;

  List<Course> get filteredCourses {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return courses;

    return courses.where((course) {
      final content = <String>[
        course.title,
        course.description,
        course.level,
        course.status,
      ].join(' ').toLowerCase();
      return content.contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _watchProfessionalMenu();
  }

  @override
  void onClose() {
    _menuWorker?.dispose();
    super.onClose();
  }

  void setSearch(String value) {
    searchQuery.value = value;
  }

  Future<void> loadInstructorCourses({bool withLoader = true}) async {
    if (withLoader) {
      isLoading.value = true;
    }

    errorMessage.value = '';

    try {
      if (_authService.currentUserId == null) {
        await _authService.syncCurrentUserProfile(force: true);
      }

      final instructorId = _authService.currentUserId;
      if (instructorId == null || instructorId <= 0) {
        throw Exception('Utilisateur non connecté');
      }

      final loadedCourses =
          await _coursesApi.getInstructorCourses(instructorId);
      courses.assignAll(loadedCourses);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (withLoader) {
        isLoading.value = false;
      }
    }
  }

  void _watchProfessionalMenu() {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }

    final home = Get.find<HomeController>();

    _menuWorker = ever<int>(home.selectedMenu, (menu) {
      if (menu == _professionalFormationsMenuIndex) {
        loadInstructorCourses();
      }
    });

    if (home.selectedMenu.value == _professionalFormationsMenuIndex) {
      loadInstructorCourses();
    }
  }
}
