import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/models/training_session_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/data/services/training_sessions_api.dart';
import 'package:flutter_getx_app/app/widgets/delete_confirmation_dialog.dart';
import 'package:get/get.dart';

class TrainingSessionsController extends GetxController {
  static const int _studentSessionsMenuIndex = 17;

  final TrainingSessionsApi _api;
  final CoursesApi _coursesApi;
  final AuthService _authService;
  Worker? _menuWorker;

  TrainingSessionsController({
    TrainingSessionsApi? api,
    CoursesApi? coursesApi,
    AuthService? authService,
  })  : _api = api ?? TrainingSessionsApi(),
        _coursesApi = coursesApi ?? CoursesApi(),
        _authService = authService ?? Get.find<AuthService>();

  final RxList<TrainingSession> sessions = <TrainingSession>[].obs;
  final RxList<Course> courses = <Course>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString searchQuery = ''.obs;
  final RxInt studentTabIndex = 0.obs;

  int? get currentUserId => _authService.currentUserId;

  /// Retourne les sessions qui ne sont pas expirées (date de fin > maintenant)
  List<TrainingSession> get activeSessions =>
      sessions.where(_isSessionActive).toList();

  List<TrainingSession> get studentAvailableSessions => activeSessions
      .where((session) => !_isCurrentUserParticipant(session))
      .toList();

  List<TrainingSession> get studentMySessions =>
      activeSessions.where(_isCurrentUserParticipant).toList();

  List<TrainingSession> get filteredSessions {
    final q = searchQuery.value.trim().toLowerCase();
    final active = activeSessions;
    if (q.isEmpty) return active;

    return active.where((session) {
      final content = <String>[
        session.title,
        session.courseLabel,
        session.type.label,
        session.status.label,
      ].join(' ').toLowerCase();
      return content.contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchSessions();
    fetchCourses();
    _watchStudentSessionsMenu();
  }

  @override
  void onClose() {
    _menuWorker?.dispose();
    super.onClose();
  }

  Future<void> fetchSessions() async {
    isLoading.value = true;
    try {
      final result = await _api.getSessions();
      sessions.assignAll(result.map(_resolveCourseLabelForSession).toList());
      print('✅ Sessions chargées: ${result.length}');
    } catch (e) {
      print('❌ Erreur fetchSessions: $e');
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshSessionsFromServer({bool withLoader = true}) async {
    if (withLoader) {
      await fetchSessions();
      return;
    }

    try {
      final result = await _api.getSessions();
      sessions.assignAll(result.map(_resolveCourseLabelForSession).toList());
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> enrollInSession(TrainingSession session) async {
    final userId = await _resolveCurrentUserId();
    if (userId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    if (_isCurrentUserParticipant(session)) {
      studentTabIndex.value = 1;
      return;
    }

    if (session.participants.length >= session.maxParticipants) {
      Get.snackbar('Information', 'Session complète');
      return;
    }

    isSaving.value = true;
    final previousSession = session;
    try {
      final attendeeIds = <int>{
        ...session.participants.map((item) => item.id),
        userId,
      }.toList();

      // Mise à jour optimiste: la session apparaît immédiatement dans "Mes sessions".
      final optimisticParticipants = <Participant>[
        ...session.participants,
        if (!session.participants.any((item) => item.id == userId))
          Participant(
            id: userId,
            documentId: userId.toString(),
            firstname: '',
            lastname: '',
            email: '',
          ),
      ];
      _replaceSession(session.copyWith(participants: optimisticParticipants));
      studentTabIndex.value = 1;

      final identifier = session.documentId.trim().isNotEmpty
          ? session.documentId
          : session.id;

      final updated = await _api.updateSessionAttendees(
        identifier,
        attendeeIds: attendeeIds,
      );

      _replaceSession(_resolveCourseLabelForSession(
        updated,
        fallbackLabel: session.courseLabel,
        fallbackCourseId: session.courseAssociated,
      ));

      await refreshSessionsFromServer(withLoader: false);
      Get.snackbar('Succès', 'Inscription effectuée');
    } catch (e) {
      _replaceSession(previousSession);
      await refreshSessionsFromServer(withLoader: false);
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSaving.value = false;
    }
  }

  Future<int?> _resolveCurrentUserId() async {
    final cachedUserId = currentUserId;
    if (cachedUserId != null && cachedUserId > 0) {
      return cachedUserId;
    }

    try {
      await _authService.syncCurrentUserProfile(force: true);
    } catch (_) {}

    final refreshedUserId = currentUserId;
    if (refreshedUserId != null && refreshedUserId > 0) {
      return refreshedUserId;
    }

    return null;
  }

  Future<void> leaveSession(TrainingSession session) async {
    final userId = currentUserId;
    if (userId == null) {
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    if (!_isCurrentUserParticipant(session)) {
      return;
    }

    isSaving.value = true;
    try {
      final attendeeIds = session.participants
          .map((item) => item.id)
          .where((id) => id != userId)
          .toSet()
          .toList();

      final identifier = session.documentId.trim().isNotEmpty
          ? session.documentId
          : session.id;

      final updated = await _api.updateSessionAttendees(
        identifier,
        attendeeIds: attendeeIds,
      );

      _replaceSession(_resolveCourseLabelForSession(
        updated,
        fallbackLabel: session.courseLabel,
        fallbackCourseId: session.courseAssociated,
      ));

      await refreshSessionsFromServer(withLoader: false);

      Get.snackbar('Succès', 'Désinscription effectuée');
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> fetchCourses() async {
    try {
      final result = await _coursesApi.getCourses();
      courses.assignAll(result);
      sessions.assignAll(sessions.map(_resolveCourseLabelForSession).toList());
      print('✅ Cours chargés: ${result.length}');
    } catch (e) {
      print('❌ Erreur fetchCourses: $e');
    }
  }

  Future<void> addSession(TrainingSession session) async {
    isSaving.value = true;
    try {
      final created = await _api.createSession(session);
      final resolved = _resolveCourseLabelForSession(
        created,
        fallbackLabel: session.courseLabel,
        fallbackCourseId: session.courseAssociated,
      );
      sessions.insert(0, resolved);
      await refreshSessionsFromServer(withLoader: false);
      Get.snackbar('Succès', 'Session créée avec succès');
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> editSession(dynamic id, TrainingSession session) async {
    isSaving.value = true;
    try {
      final updated = await _api.updateSession(id, session);
      final resolved = _resolveCourseLabelForSession(
        updated,
        fallbackLabel: session.courseLabel,
        fallbackCourseId: session.courseAssociated,
      );

      final index = sessions.indexWhere((item) => item.id == resolved.id);
      if (index >= 0) {
        sessions[index] = resolved;
      } else {
        sessions.insert(0, resolved);
      }
      await refreshSessionsFromServer(withLoader: false);
      Get.snackbar('Succès', 'Session mise à jour');
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> removeSession(TrainingSession session) async {
    final bool confirmed = await showDeleteConfirmationDialog(
      title: 'Supprimer la session',
      itemName: session.title,
      description: 'La session sera supprimée définitivement du système.',
    );

    if (!confirmed) return;

    try {
      await _api.deleteSession(
        id: session.id,
        documentId: session.documentId,
      );
      sessions.removeWhere((item) => item.id == session.id);
      await refreshSessionsFromServer(withLoader: false);
      Get.snackbar('Succès', 'Session supprimée');
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  TrainingSession _resolveCourseLabelForSession(
    TrainingSession session, {
    String? fallbackLabel,
    int? fallbackCourseId,
  }) {
    final currentLabel = session.courseLabel.trim();
    final currentCourseId = session.courseAssociated ?? fallbackCourseId;

    if (currentLabel.isNotEmpty && currentLabel != 'Non spécifié') {
      return session;
    }

    final matchedCourse =
        courses.firstWhereOrNull((course) => course.id == currentCourseId);

    final resolvedLabel = matchedCourse?.title ??
        ((fallbackLabel != null && fallbackLabel.trim().isNotEmpty)
            ? fallbackLabel.trim()
            : 'Non spécifié');

    return session.copyWith(
      courseAssociated: currentCourseId,
      courseLabel: resolvedLabel,
    );
  }

  bool _isCurrentUserParticipant(TrainingSession session) {
    final userId = currentUserId;
    if (userId == null) return false;
    return session.participants.any((participant) => participant.id == userId);
  }

  /// Vérifie si une session est active (non expirée)
  bool _isSessionActive(TrainingSession session) {
    final endDate = session.endDate;
    if (endDate == null)
      return true; // Pas de date de fin = session toujours active
    return endDate.isAfter(DateTime.now());
  }

  void _replaceSession(TrainingSession updated) {
    final index = sessions.indexWhere((item) => item.id == updated.id);
    if (index >= 0) {
      sessions[index] = updated;
      return;
    }
    sessions.insert(0, updated);
  }

  void _watchStudentSessionsMenu() {
    if (!Get.isRegistered<HomeController>()) return;

    final home = Get.find<HomeController>();

    _menuWorker = ever<int>(home.selectedMenu, (menuIndex) {
      if (menuIndex == _studentSessionsMenuIndex) {
        refreshSessionsFromServer();
      }
    });

    if (home.selectedMenu.value == _studentSessionsMenuIndex) {
      refreshSessionsFromServer();
    }
  }
}
