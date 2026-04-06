import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';

class CourseController extends GetxController {
  static const int _studentMyCoursesMenuIndex = 10;
  static const int _studentCatalogMenuIndex = 12;

  final CoursesApi _api = CoursesApi();

  final RxList<Course> courses = <Course>[].obs;
  final RxList<Course> studentMyCourses = <Course>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isProcessingEnrollment = false.obs;
  final RxString searchQuery = ''.obs;

  final List<Course> _allCourses = <Course>[];
  Worker? _menuWorker;

  List<Course> get studentCatalogCourses {
    return filteredCourses;
  }

  bool isEnrolledIn(Course course) {
    return studentMyCourses.any((item) => item.id == course.id);
  }

  @override
  void onInit() {
    super.onInit();
    fetchCourses();
    refreshStudentMyCourses(silent: true);
    _watchStudentMenus();
  }

  @override
  void onClose() {
    _menuWorker?.dispose();
    super.onClose();
  }

  Future<void> refreshStudentCatalog() async {
    setSearch('');
    await Future.wait([
      fetchCourses(),
      refreshStudentMyCourses(silent: true),
    ]);
  }

  Future<void> fetchCourses() async {
    isLoading.value = true;
    try {
      final result = await _api.getCourses();
      _allCourses
        ..clear()
        ..addAll(result);
      _applySearch();
    } catch (e) {
      _handleError('Chargement cours', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshStudentMyCourses({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }

    try {
      final result = await _api.getStudentMyCourses();
      studentMyCourses.assignAll(result);
    } catch (e) {
      if (!silent) {
        _handleError('Chargement mes cours', e);
      }
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  Future<bool> enrollInCourseWithPayment(Course course) async {
    if (isEnrolledIn(course)) {
      return true;
    }

    isProcessingEnrollment.value = true;
    try {
      await _api.enrollCurrentStudentToCourse(course);
      await refreshStudentCatalog();
      Get.snackbar('Succès', 'Inscription confirmée pour ${course.title}');
      return true;
    } catch (e) {
      _handleError('Inscription cours', e);
      return false;
    } finally {
      isProcessingEnrollment.value = false;
    }
  }

  Future<void> addCourse(Course course) async {
    isLoading.value = true;
    try {
      await _api.createCourse(course);
      await fetchCourses();
      Get.snackbar('Succès', 'Cours ajouté avec succès');
    } catch (e) {
      _handleError('Ajout cours', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editCourse(Course course) async {
    isLoading.value = true;
    try {
      await _api.updateCourse(course);
      await fetchCourses();
      Get.snackbar('Succès', 'Cours mis à jour avec succès');
    } catch (e) {
      _handleError('Mise à jour cours', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeCourse(Course course) async {
    isLoading.value = true;
    try {
      await _api.deleteCourse(id: course.id, documentId: course.documentId);
      _allCourses.removeWhere((item) =>
          item.id == course.id ||
          (course.documentId.isNotEmpty &&
              item.documentId == course.documentId));
      _applySearch();
      Get.snackbar('Succès', 'Cours supprimé avec succès');
    } catch (e) {
      _handleError('Suppression cours', e);
    } finally {
      isLoading.value = false;
    }
  }

  List<Course> get filteredCourses => courses;

  void setSearch(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      courses.assignAll(_allCourses);
      return;
    }

    courses.assignAll(
      _allCourses.where(
        (course) =>
            course.title.toLowerCase().contains(query) ||
            course.description.toLowerCase().contains(query) ||
            course.level.toLowerCase().contains(query) ||
            course.status.toLowerCase().contains(query),
      ),
    );
  }

  void _handleError(String context, Object error) {
    final message = error.toString();
    print('❌ [CourseController][$context] $message');

    if (message.contains('401')) {
      Get.snackbar('Erreur 401', 'Non autorisé. Veuillez vous reconnecter.');
      return;
    }

    if (message.contains('403')) {
      Get.snackbar('Erreur 403', 'Accès refusé pour cette opération.');
      return;
    }

    if (message.contains('500')) {
      Get.snackbar('Erreur 500', 'Erreur serveur. Réessayez plus tard.');
      return;
    }

    Get.snackbar('Erreur', message.replaceFirst('Exception: ', ''));
  }

  void _watchStudentMenus() {
    if (!Get.isRegistered<HomeController>()) return;

    final home = Get.find<HomeController>();

    if (home.selectedMenu.value == _studentMyCoursesMenuIndex ||
        home.selectedMenu.value == _studentCatalogMenuIndex) {
      refreshStudentCatalog();
    }

    _menuWorker = ever<int>(home.selectedMenu, (menu) {
      if (menu == _studentMyCoursesMenuIndex ||
          menu == _studentCatalogMenuIndex) {
        refreshStudentCatalog();
      }
    });
  }
}
