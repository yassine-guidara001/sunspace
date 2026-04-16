import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_profile_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/reservations_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

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
  static const String _baseApiUrl = 'http://localhost:3001/api';

  final selectedMenu = 0.obs; // dashboard selected par defaut
  final isSidebarCollapsed = false.obs;
  final currentUsername = 'Utilisateur'.obs;
  final currentEmail = ''.obs;

  final isDashboardLoading = false.obs;
  final dashboardSummary = const AdminDashboardSummary().obs;
  final dashboardActivities = <Map<String, String>>[].obs;
  final dashboardPopularCourses = <Map<String, dynamic>>[].obs;

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

    if (route == Routes.HOME) {
      loadDashboardData();
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
    loadDashboardData();
    fetchUsers();
  }

  Future<void> loadDashboardData() async {
    isDashboardLoading.value = true;
    try {
      final spaces =
          await _fetchCollection('/spaces?pagination%5BpageSize%5D=200');
      final reservations = await _fetchCollection(
        '/reservations?populate%5Bspace%5D%5Bpopulate%5D=*'
        '&populate%5Buser%5D%5Bfields%5D=username,email'
        '&pagination%5BpageSize%5D=200',
      );
      final courses =
          await _fetchCollection('/courses?pagination%5BpageSize%5D=200');
      final users =
          await _fetchCollection('/users?pagination%5BpageSize%5D=500');

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      final totalSpaces = spaces.length;
      final spacesThisMonth = spaces
          .where((space) => _isSameMonth(_parseDate(space['createdAt']), now))
          .length;

      final activeReservations = reservations
          .where((reservation) =>
              _isActiveReservationStatus(_reservationStatus(reservation)))
          .length;
      final reservationsThisMonth = reservations
          .where((reservation) =>
              _isSameMonth(_parseDate(reservation['createdAt']), now) &&
              _isActiveReservationStatus(_reservationStatus(reservation)))
          .length;

      final publishedCourses = courses
          .where((course) => _courseStatus(course).contains('publi'))
          .length;
      final coursesThisMonth = courses
          .where((course) =>
              _isSameMonth(_parseDate(course['createdAt']), now) &&
              _courseStatus(course).contains('publi'))
          .length;

      final activeUsers = users.where((user) {
        final blocked = (user['blocked'] == true);
        final status =
            (user['status'] ?? user['mystatus'] ?? '').toString().toLowerCase();
        return !blocked && !status.contains('inactif');
      }).length;
      final usersThisWeek = users
          .where((user) => _isInCurrentWeek(_parseDate(user['createdAt']), now))
          .length;

      double revenueMonth = 0;
      double bookedHoursMonth = 0;
      for (final reservation in reservations) {
        final status = _reservationStatus(reservation);
        if (!_isActiveReservationStatus(status)) continue;

        final start = _parseDate(reservation['start_datetime']);
        final end = _parseDate(reservation['end_datetime']);
        if (!_isSameMonth(start, now)) continue;

        revenueMonth += _toDouble(reservation['total_amount']);
        if (start != null && end != null && end.isAfter(start)) {
          bookedHoursMonth += end.difference(start).inMinutes / 60.0;
        }
      }

      final maxCapacityHours =
          (totalSpaces <= 0 ? 1 : totalSpaces) * 9 * daysInMonth;
      final occupancyRatio = maxCapacityHours <= 0
          ? 0.0
          : (bookedHoursMonth / maxCapacityHours).clamp(0.0, 1.0);
      final occupancyPercent = (occupancyRatio * 100).round();

      final sortedReservations = List<Map<String, dynamic>>.from(reservations)
        ..sort((a, b) {
          final da = _parseDate(a['start_datetime']) ??
              _parseDate(a['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final db = _parseDate(b['start_datetime']) ??
              _parseDate(b['createdAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da);
        });

      final activities = sortedReservations.take(4).map((reservation) {
        final space = reservation['space'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(reservation['space'])
            : <String, dynamic>{};
        final user = reservation['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(reservation['user'])
            : <String, dynamic>{};

        final title = (space['name'] ?? 'Reservation').toString();
        final client =
            (user['username'] ?? user['email'] ?? 'Utilisateur').toString();
        final date = _formatShortDate(
            _parseDate(reservation['start_datetime']) ??
                _parseDate(reservation['createdAt']));
        final status = _reservationLabel(reservation);

        return {
          'title': title,
          'client': client,
          'date': date,
          'status': status,
        };
      }).toList();

      final popularCourses = List<Map<String, dynamic>>.from(courses)
          .map((course) {
        final students = _toInt(
          course['enrollmentsCount'] ??
              course['studentsCount'] ??
              course['studentCount'] ??
              course['attendeesCount'] ??
              course['participants'],
        );
        final ratingRaw = course['rating'] ?? course['averageRating'] ?? 0;
        final rating = _toDouble(ratingRaw);
        return {
          'title': (course['title'] ?? 'Cours').toString(),
          'students': students,
          'rating': rating > 0 ? rating : 4.5,
        };
      }).toList()
        ..sort(
            (a, b) => (b['students'] as int).compareTo(a['students'] as int));

      dashboardSummary.value = AdminDashboardSummary(
        totalSpaces: totalSpaces,
        spacesSubtitle: '+$spacesThisMonth ce mois',
        activeReservations: activeReservations,
        reservationsSubtitle: '+$reservationsThisMonth ce mois',
        publishedCourses: publishedCourses,
        coursesSubtitle: '+$coursesThisMonth publies ce mois',
        activeUsers: activeUsers,
        usersSubtitle: '+$usersThisWeek cette semaine',
        monthlyRevenueLabel: '${revenueMonth.toStringAsFixed(2)} DT',
        occupancyLabel: '$occupancyPercent%',
        occupancyProgress: occupancyRatio,
        occupancyHelperText:
            'Heures reservees: ${bookedHoursMonth.toStringAsFixed(0)}h / ${maxCapacityHours.toStringAsFixed(0)}h',
      );

      dashboardActivities.assignAll(activities);
      dashboardPopularCourses.assignAll(popularCourses.take(3));
    } catch (_) {
      // Keep dashboard rendering resilient even if one backend source fails.
    } finally {
      isDashboardLoading.value = false;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCollection(String endpoint) async {
    final response = await http.get(
      Uri.parse('$_baseApiUrl$endpoint'),
      headers: _authService.authHeaders,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  String _reservationStatus(Map<String, dynamic> reservation) {
    return (reservation['status'] ?? reservation['mystatus'] ?? '')
        .toString()
        .toLowerCase();
  }

  String _courseStatus(Map<String, dynamic> course) {
    return (course['status'] ?? course['mystatus'] ?? '')
        .toString()
        .toLowerCase();
  }

  bool _isActiveReservationStatus(String status) {
    if (status.contains('cancel') || status.contains('annul')) return false;
    if (status.contains('reject') || status.contains('rejet')) return false;
    if (status.contains('complete') || status.contains('termine')) return false;
    return true;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  bool _isSameMonth(DateTime? date, DateTime now) {
    if (date == null) return false;
    return date.year == now.year && date.month == now.month;
  }

  bool _isInCurrentWeek(DateTime? date, DateTime now) {
    if (date == null) return false;
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '--';
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _reservationLabel(Map<String, dynamic> reservation) {
    final raw = _reservationStatus(reservation);
    if (raw.contains('confirm')) return 'Confirme';
    if (raw.contains('pending') || raw.contains('attente')) return 'En attente';
    if (raw.contains('cancel') || raw.contains('annul')) return 'Annulee';
    if (raw.contains('reject') || raw.contains('rejet')) return 'Rejetee';
    return 'En attente';
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

class AdminDashboardSummary {
  const AdminDashboardSummary({
    this.totalSpaces = 0,
    this.spacesSubtitle = '+0 ce mois',
    this.activeReservations = 0,
    this.reservationsSubtitle = '+0 ce mois',
    this.publishedCourses = 0,
    this.coursesSubtitle = '+0 publies ce mois',
    this.activeUsers = 0,
    this.usersSubtitle = '+0 cette semaine',
    this.monthlyRevenueLabel = '0.00 DT',
    this.occupancyLabel = '0%',
    this.occupancyProgress = 0,
    this.occupancyHelperText = 'Heures reservees: 0h / 0h',
  });

  final int totalSpaces;
  final String spacesSubtitle;
  final int activeReservations;
  final String reservationsSubtitle;
  final int publishedCourses;
  final String coursesSubtitle;
  final int activeUsers;
  final String usersSubtitle;
  final String monthlyRevenueLabel;
  final String occupancyLabel;
  final double occupancyProgress;
  final String occupancyHelperText;
}
