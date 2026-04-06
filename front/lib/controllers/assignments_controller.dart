import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/services/assignments_api.dart';
import 'package:get/get.dart';

class AssignmentsController extends GetxController {
  static const int _teacherAssignmentsMenuIndex = 11;
  static const int _studentAssignmentsMenuIndex = 14;

  final AssignmentsApi _api;
  final CoursesApi _coursesApi;
  Worker? _menuWorker;

  AssignmentsController({AssignmentsApi? api, CoursesApi? coursesApi})
      : _api = api ?? AssignmentsApi(),
        _coursesApi = coursesApi ?? CoursesApi();

  final RxList<Assignment> assignments = <Assignment>[].obs;
  final RxMap<int, int> studentSubmissionCountByAssignment = <int, int>{}.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxList<Course> courses = <Course>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAssignments();
    _watchAssignmentMenus();
  }

  @override
  void onClose() {
    _menuWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchAssignments({bool? teacherMode}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final isTeacherMode = teacherMode ?? _isTeacherAssignmentsMode();
      final result = await _api.getAssignments(onlyInstructor: isTeacherMode);
      final resolvedAssignments = result.map(_resolveCourseName).toList();
      assignments.assignAll(resolvedAssignments);

      if (isTeacherMode) {
        studentSubmissionCountByAssignment.clear();
      } else {
        await _loadStudentSubmissionState(resolvedAssignments);
      }
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> addAssignment(Map data) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final created = await _api.createAssignment(data);
      final hydrated = _hydrateCourseFromPayload(created, data);
      assignments.insert(0, _resolveCourseName(hydrated));
      Get.snackbar('Succès', 'Devoir créé avec succès');
      return true;
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> editAssignment(int id, Map data, {String? documentId}) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final updated = await _api.updateAssignment(
        id,
        data,
        documentId: documentId,
      );
      final hydrated = _hydrateCourseFromPayload(updated, data);
      final resolved = _resolveCourseName(hydrated);

      final index = assignments.indexWhere((item) => item.id == resolved.id);
      if (index >= 0) {
        assignments[index] = resolved;
      } else {
        assignments.insert(0, resolved);
      }

      Get.snackbar('Succès', 'Devoir modifié avec succès');
      return true;
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeAssignment(int id) async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _api.deleteAssignment(id);
      assignments.removeWhere((item) => item.id == id);
      studentSubmissionCountByAssignment.remove(id);
      Get.snackbar('Succès', 'Devoir supprimé avec succès');
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
    } finally {
      isLoading.value = false;
    }
  }

  bool hasStudentSubmission(Assignment assignment) {
    return (studentSubmissionCountByAssignment[assignment.id] ?? 0) > 0;
  }

  String studentStatusFor(Assignment assignment) {
    if (hasStudentSubmission(assignment)) {
      return 'Soumis';
    }

    final now = DateTime.now();
    if (!assignment.dueDate.isBefore(now)) {
      return 'A faire';
    }

    if (assignment.allowLateSubmission) {
      return 'En retard';
    }

    return 'Expire';
  }

  Future<void> _loadStudentSubmissionState(List<Assignment> items) async {
    final assignmentIds = items
        .where((assignment) => assignment.id > 0)
        .map((assignment) => assignment.id)
        .toSet();

    if (assignmentIds.isEmpty) {
      studentSubmissionCountByAssignment.clear();
      return;
    }

    try {
      final grouped = await _api.getStudentSubmissionsByAssignment(
        assignmentIds: assignmentIds,
      );

      final next = <int, int>{};
      for (final id in assignmentIds) {
        next[id] = grouped[id]?.length ?? 0;
      }

      studentSubmissionCountByAssignment.assignAll(next);
    } catch (_) {
      studentSubmissionCountByAssignment.clear();
    }
  }

  Future<void> fetchCourses() async {
    try {
      final result = await _coursesApi.getCourses();
      courses.assignAll(result);
      assignments.assignAll(assignments.map(_resolveCourseName).toList());
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
    }
  }

  Future<Assignment?> fetchAssignmentById(
    int id, {
    String? documentId,
  }) async {
    try {
      final assignment = await _api.getAssignmentById(
        id,
        documentId: documentId,
      );
      return _resolveCourseName(assignment);
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadAttachment(dynamic file) async {
    try {
      return await _api.uploadAttachment(file);
    } catch (e) {
      final message = _normalizeError(e);
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
      return null;
    }
  }

  Assignment _resolveCourseName(Assignment assignment) {
    if (assignment.courseName.trim().isNotEmpty &&
        assignment.courseName != 'Non spécifié') {
      return assignment;
    }

    Course? found;

    if (assignment.courseId != null) {
      found = courses
          .firstWhereOrNull((course) => course.id == assignment.courseId);
    }

    if (found == null) {
      final courseDocumentId = assignment.courseDocumentId?.trim() ?? '';
      if (courseDocumentId.isNotEmpty) {
        found = courses.firstWhereOrNull(
          (course) => course.documentId.trim() == courseDocumentId,
        );
      }
    }

    if (found == null) {
      return assignment;
    }

    return assignment.copyWith(
      courseName: found.title,
      courseId: assignment.courseId ?? found.id,
      courseDocumentId: assignment.courseDocumentId ?? found.documentId,
    );
  }

  Assignment _hydrateCourseFromPayload(Assignment assignment, Map data) {
    if (assignment.courseName.trim().isNotEmpty &&
        assignment.courseName != 'Non spécifié') {
      return assignment;
    }

    Course? found;
    final payloadCourseId =
        _toIntNullable(data['courseId'] ?? data['course_id']);
    final payloadCourseDocumentId = (data['course'] is String)
        ? data['course'].toString().trim()
        : (data['courseDocumentId']?.toString().trim() ?? '');

    if (payloadCourseId != null) {
      found =
          courses.firstWhereOrNull((course) => course.id == payloadCourseId);
    }

    if (found == null && payloadCourseDocumentId.isNotEmpty) {
      found = courses.firstWhereOrNull(
        (course) => course.documentId.trim() == payloadCourseDocumentId,
      );
    }

    if (found == null) {
      return assignment;
    }

    return assignment.copyWith(
      courseName: found.title,
      courseId: assignment.courseId ?? found.id,
      courseDocumentId: assignment.courseDocumentId ?? found.documentId,
    );
  }

  int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  String _normalizeError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();

    if (raw.contains('SocketException') ||
        raw.contains('Failed host lookup') ||
        raw.contains('Connection') ||
        raw.contains('Timeout')) {
      return 'Connexion impossible';
    }

    if (raw.contains('Session expirée')) return 'Session expirée';
    if (raw.contains('Accès refusé')) return 'Accès refusé';
    if (raw.contains('Ressource introuvable')) return 'Ressource introuvable';
    if (raw.contains('Données invalides')) return 'Données invalides';
    if (raw.contains('Connexion impossible')) return 'Connexion impossible';
    if (raw.contains('Erreur serveur')) return 'Erreur serveur';

    return raw.isEmpty ? 'Erreur inconnue' : raw;
  }

  bool _isTeacherAssignmentsMode() {
    if (!Get.isRegistered<HomeController>()) {
      return false;
    }

    final menu = Get.find<HomeController>().selectedMenu.value;
    return menu == _teacherAssignmentsMenuIndex;
  }

  void _watchAssignmentMenus() {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }

    final home = Get.find<HomeController>();

    _menuWorker = ever<int>(home.selectedMenu, (menu) {
      if (menu == _teacherAssignmentsMenuIndex) {
        fetchAssignments(teacherMode: true);
      }

      if (menu == _studentAssignmentsMenuIndex) {
        fetchAssignments(teacherMode: false);
      }
    });
  }
}
