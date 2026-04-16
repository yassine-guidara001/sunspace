import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/training_session_model.dart';
import 'package:flutter_getx_app/app/data/services/training_sessions_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';

class ProfessionalFormationsController extends GetxController {
  static const int _professionalFormationsMenuIndex = 20;

  final TrainingSessionsApi _sessionsApi;
  final AuthService _authService;

  Worker? _menuWorker;

  ProfessionalFormationsController({
    TrainingSessionsApi? sessionsApi,
    AuthService? authService,
  })  : _sessionsApi = sessionsApi ?? TrainingSessionsApi(),
        _authService = authService ?? Get.find<AuthService>();

  final RxList<TrainingSession> sessions = <TrainingSession>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString searchQuery = ''.obs;
  final RxInt activeTab = 0.obs; // 0: disponibles, 1: mes formations
  final RxSet<int> enrollingSessionIds = <int>{}.obs;

  int? get _currentUserId {
    final id = _authService.currentUserId;
    if (id != null && id > 0) return id;
    return null;
  }

  bool isEnrolled(TrainingSession session) {
    final userId = _currentUserId;
    if (userId == null) return false;
    return session.participants.any((participant) => participant.id == userId);
  }

  List<TrainingSession> get mySessions {
    return sessions.where(isEnrolled).toList();
  }

  List<TrainingSession> get availableSessions {
    return sessions.where((session) => !isEnrolled(session)).toList();
  }

  int get mySessionsCount => mySessions.length;
  int get availableSessionsCount => availableSessions.length;

  List<TrainingSession> get filteredSessions {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return sessions;

    return sessions.where((session) {
      final content = <String>[
        session.title,
        session.courseLabel,
        session.notes ?? '',
        session.type.label,
        session.status.label,
      ].join(' ').toLowerCase();
      return content.contains(q);
    }).toList();
  }

  List<TrainingSession> get visibleSessions {
    final source = activeTab.value == 1 ? mySessions : availableSessions;
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source.where((session) {
      final content = <String>[
        session.title,
        session.courseLabel,
        session.notes ?? '',
        session.type.label,
        session.status.label,
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

  void setActiveTab(int index) {
    if (index < 0 || index > 1) return;
    activeTab.value = index;
  }

  Future<void> loadSessions({bool withLoader = true}) async {
    if (withLoader) {
      isLoading.value = true;
    }

    errorMessage.value = '';

    try {
      if (_authService.currentUserId == null) {
        await _authService.syncCurrentUserProfile(force: true);
      }

      final loadedSessions = await _sessionsApi.getSessions();
      sessions.assignAll(loadedSessions.where(_isSessionActive).toList());
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (withLoader) {
        isLoading.value = false;
      }
    }
  }

  bool _isSessionActive(TrainingSession session) {
    final endDate = session.endDate;
    if (endDate == null) return true;
    return endDate.isAfter(DateTime.now());
  }

  Future<void> loadInstructorCourses({bool withLoader = true}) {
    // Backward-compatible alias used by the current page actions.
    return loadSessions(withLoader: withLoader);
  }

  bool _isSessionLinkedToCourse(TrainingSession session) {
    final hasCourseId = (session.courseAssociated ?? 0) > 0;
    final normalizedLabel = session.courseLabel.trim().toLowerCase();
    final hasCourseLabel =
        normalizedLabel.isNotEmpty && normalizedLabel != 'non spécifié';
    return hasCourseId && hasCourseLabel;
  }

  Future<void> enrollInSession(TrainingSession session) async {
    final userId = _currentUserId;
    if (userId == null || userId <= 0) {
      errorMessage.value = 'Utilisateur non connecté';
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    if (isEnrolled(session)) {
      setActiveTab(1);
      return;
    }

    if (session.participants.length >= session.maxParticipants) {
      Get.snackbar('Information', 'Session complète');
      return;
    }

    enrollingSessionIds.add(session.id);

    try {
      final attendeeIds = <int>{
        ...session.participants.map((participant) => participant.id),
        userId,
      }.toList();

      final identifier = session.documentId.trim().isNotEmpty
          ? session.documentId.trim()
          : session.id;

      final updated = await _sessionsApi.updateSessionAttendees(
        identifier,
        attendeeIds: attendeeIds,
      );

      final index = sessions.indexWhere((item) => item.id == updated.id);
      if (index >= 0) {
        sessions[index] = updated;
      } else {
        sessions.insert(0, updated);
      }

      setActiveTab(1);
      Get.snackbar('Succès', 'Inscription effectuée avec succès');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
    } finally {
      enrollingSessionIds.remove(session.id);
    }
  }

  Future<void> unenrollFromSession(TrainingSession session) async {
    final userId = _currentUserId;
    if (userId == null || userId <= 0) {
      errorMessage.value = 'Utilisateur non connecté';
      Get.snackbar('Erreur', 'Utilisateur non connecté');
      return;
    }

    if (!isEnrolled(session)) {
      setActiveTab(0);
      return;
    }

    enrollingSessionIds.add(session.id);

    try {
      final attendeeIds = session.participants
          .map((participant) => participant.id)
          .where((id) => id != userId)
          .toList();

      final identifier = session.documentId.trim().isNotEmpty
          ? session.documentId.trim()
          : session.id;

      final updated = await _sessionsApi.updateSessionAttendees(
        identifier,
        attendeeIds: attendeeIds,
      );

      final index = sessions.indexWhere((item) => item.id == updated.id);
      if (index >= 0) {
        sessions[index] = updated;
      } else {
        sessions.insert(0, updated);
      }

      setActiveTab(1);
      Get.snackbar('Succès', 'Désinscription effectuée avec succès');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = message;
      Get.snackbar('Erreur', message);
    } finally {
      enrollingSessionIds.remove(session.id);
    }
  }

  void _watchProfessionalMenu() {
    if (!Get.isRegistered<HomeController>()) {
      return;
    }

    final home = Get.find<HomeController>();

    _menuWorker = ever<int>(home.selectedMenu, (menu) {
      if (menu == _professionalFormationsMenuIndex) {
        loadSessions();
      }
    });

    if (home.selectedMenu.value == _professionalFormationsMenuIndex) {
      loadSessions();
    }
  }
}
