import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_profile_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/reservations_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  /// ===============================
  /// 🔵 SIDEBAR MENU
  /// ===============================
  static const Set<int> _profileSyncMenuIndexes = <int>{
    8, // Enseignant - Formations
    9, // Enseignant - Sessions
    10, // Enseignant - Étudiants
    11, // Enseignant - Devoirs
    12, // Enseignant - Communication
    13, // Étudiant - Mes cours
    14, // Étudiant - Mes devoirs
    15, // Étudiant - Catalogue Cours
    17, // Étudiant - Sessions
    20, // Professionnel - Formations
    21, // Professionnel - Abonnements
    22, // Professionnel - Mon profil
    23, // Association - Formations
    // 25 retiré : Budget & Utilisation lit l'userId depuis le storage local,
    // pas besoin de synchro /users/me à chaque clic.
  };

  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storageService = Get.find<StorageService>();

  final selectedMenu = 0.obs; // dashboard selected par defaut
  final isSidebarCollapsed = false.obs;
  final currentUsername = 'Utilisateur'.obs;
  final currentEmail = ''.obs;

  String get currentUserInitial {
    final username = currentUsername.value.trim();
    if (username.isEmpty) return 'U';
    return username.substring(0, 1).toUpperCase();
  }

  void toggleSidebarCollapse() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
  }

  void setSidebarCollapsed(bool value) {
    isSidebarCollapsed.value = value;
  }

  void changeMenu(int index, String route) {
    selectedMenu.value = index;

    if (_profileSyncMenuIndexes.contains(index)) {
      _syncCurrentUserForSidebarSection();
    }

    // Keep student spaces navigation silent (no API preload) to match expected
    // network behavior when opening the floor plan page.
    if (route == Routes.STUDENT_SPACES) {
      if (Get.currentRoute != Routes.STUDENT_SPACES) {
        Get.toNamed(route);
      }
      return;
    }

    // Force /users/me sync each time Profile menu is clicked.
    if (route == Routes.PROFILE) {
      _syncCurrentUserForProfileMenu();

      if (Get.isRegistered<ProfessionalProfileController>()) {
        Get.find<ProfessionalProfileController>().loadProfile();
      }
    }

    // Keep reservations pages in sync with backend on each menu click.
    if (route == Routes.RESERVATIONS) {
      if (Get.isRegistered<ReservationsController>()) {
        Get.find<ReservationsController>().loadReservations();
      }
    }

    if (Get.currentRoute != route) {
      Get.toNamed(route);
    }
  }

  Future<void> openSettings() async {
    await _refreshCurrentUserProfile(force: true);

    if (Get.currentRoute != Routes.SETTINGS) {
      Get.toNamed(Routes.SETTINGS);
    }
  }

  Future<void> _syncCurrentUserForSidebarSection() async {
    await _refreshCurrentUserProfile();
  }

  Future<void> _syncCurrentUserForProfileMenu() async {
    await _refreshCurrentUserProfile(force: true);
  }

  Future<void> refreshCurrentUserIdentity({bool force = true}) async {
    await _refreshCurrentUserProfile(force: force);
  }

  Future<void> _refreshCurrentUserProfile({bool force = false}) async {
    _hydrateCurrentUserFromStorage();

    try {
      final profile = await _authService.syncCurrentUserProfile(force: force);
      if (profile != null) {
        _applyCurrentUser(profile);
      }
    } catch (_) {
      // Ignore sync errors here so sidebar navigation remains responsive.
    }
  }

  void _hydrateCurrentUserFromStorage() {
    final cached = _storageService.getUserData();
    if (cached != null) {
      _applyCurrentUser(cached);
    }
  }

  void _applyCurrentUser(Map<String, dynamic> profile) {
    final candidateMaps = _collectCandidateMaps(profile);

    currentEmail.value = _extractUserValue(
      candidateMaps,
      const ['email', 'mail', 'e_mail'],
      fallback: '',
    );

    if (currentEmail.value.isEmpty) {
      final lastLoginEmail =
          (_storageService.read<String>('last_login_email') ?? '').trim();
      if (lastLoginEmail.isNotEmpty) {
        currentEmail.value = lastLoginEmail;
      }
    }

    if (currentEmail.value.isEmpty) {
      final tokenEmail = _extractEmailFromJwt();
      if (tokenEmail.isNotEmpty) {
        currentEmail.value = tokenEmail;
      }
    }

    currentUsername.value = _extractUserValue(
      candidateMaps,
      const [
        'username',
        'name',
        'fullName',
        'nom',
        'displayName',
        'firstname',
        'firstName',
      ],
      fallback:
          currentEmail.value.isNotEmpty ? currentEmail.value : 'Utilisateur',
    );

    if (currentUsername.value == 'Utilisateur' &&
        currentEmail.value.isNotEmpty) {
      currentUsername.value = currentEmail.value;
    }
  }

  String _extractEmailFromJwt() {
    final token = (_authService.token ?? '').trim();
    if (token.isEmpty) return '';

    final parts = token.split('.');
    if (parts.length < 2) return '';

    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return '';

      final map = Map<String, dynamic>.from(decoded);
      final email = _extractUserValue(
        [map],
        const ['email', 'upn', 'preferred_username', 'username', 'sub'],
        fallback: '',
      );

      if (email.contains('@')) {
        return email;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  List<Map<String, dynamic>> _collectCandidateMaps(Map<String, dynamic> root) {
    final results = <Map<String, dynamic>>[];
    final queue = <dynamic>[root];

    while (queue.isNotEmpty && results.length < 40) {
      final current = queue.removeAt(0);

      if (current is Map) {
        final map = Map<String, dynamic>.from(current);
        results.add(map);
        for (final value in map.values) {
          if (value is Map || value is List) {
            queue.add(value);
          }
        }
        continue;
      }

      if (current is List) {
        for (final item in current) {
          if (item is Map || item is List) {
            queue.add(item);
          }
        }
      }
    }

    return results;
  }

  String _extractUserValue(
    List<Map<String, dynamic>> maps,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      for (final map in maps) {
        final raw = map[key];
        if (raw == null) continue;

        final text = raw.toString().trim();
        if (text.isNotEmpty && text.toLowerCase() != 'null') {
          return text;
        }
      }
    }
    return fallback;
  }

  /// ===============================
  /// 🔵 USERS MANAGEMENT
  /// ===============================

  final isLoading = true.obs;
  final users = <User>[].obs;
  final _allUsers = <User>[];

  @override
  void onInit() {
    super.onInit();
    _hydrateCurrentUserFromStorage();
    _refreshCurrentUserProfile();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;

    await Future.delayed(const Duration(seconds: 1));

    _allUsers.clear();

    users.value = List.from(_allUsers);
    isLoading.value = false;
  }

  Future<void> refreshUsers() async {
    await fetchUsers();
  }

  void searchUsers(String query) {
    if (query.isEmpty) {
      users.value = List.from(_allUsers);
    } else {
      users.value = _allUsers
          .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
  }

  void selectUser(User user) {
    Get.snackbar(
      "Utilisateur",
      "Vous avez sélectionné : ${user.name}",
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void createUser(String name, String email, {String role = 'Utilisateur'}) {
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      email: email,
      role: role,
      status: 'Actif',
      registeredAt: DateTime.now(),
    );

    users.add(newUser);
    _allUsers.add(newUser);
  }

  void deleteUser(int id) {
    users.removeWhere((u) => u.id == id);
    _allUsers.removeWhere((u) => u.id == id);
  }
}

/// ================== MODEL ==================
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final DateTime registeredAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.registeredAt,
  });
}
