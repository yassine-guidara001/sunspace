import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';

class CustomSidebar extends StatelessWidget {
  const CustomSidebar({super.key, this.drawerMode = false});

  static const double _expandedWidth = 280;
  static const double _collapsedWidth = 74;
  static const double _mobileBreakpoint = 920;

  final bool drawerMode;

  static Future<void> openDrawerMenu(BuildContext context) async {
    final height = MediaQuery.of(context).size.height;

    await Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: SizedBox(
          width: math.min(320, MediaQuery.of(context).size.width - 32),
          height: height * 0.9,
          child: const CustomSidebar(drawerMode: true),
        ),
      ),
    );
  }

  // ── Récupère le rôle depuis le storage ───────────────────────────────────
  String _getRole() {
    try {
      final storage = Get.find<StorageService>();
      final userData = storage.getUserData();
      if (userData == null) return '';

      // Strapi v4/v5 : role peut être {id, name, type, ...}
      final role = userData['role'];
      if (role is Map) {
        final name =
            (role['name'] ?? role['type'] ?? '').toString().toLowerCase();
        return name;
      }
      if (role is String) return role.toLowerCase();

      // Fallback : cherche dans d'autres champs
      final roleStr = (userData['role_name'] ??
              userData['userRole'] ??
              userData['user_role'] ??
              '')
          .toString()
          .toLowerCase();
      return roleStr;
    } catch (_) {
      return '';
    }
  }

  bool get _isAdmin {
    final r = _getRole();
    return r.isEmpty || // pas de rôle = admin par défaut (intern)
        r.contains('admin') ||
        r.contains('administrator');
  }

  bool get _isGestionnaire {
    final r = _getRole();
    return r.contains('gestionnaire') || r.contains('gestionnairedespace');
  }

  bool get _isEnseignantOnly {
    final r = _getRole();
    return r.contains('enseignant') ||
        r.contains('teacher') ||
        r.contains('formateur');
  }

  bool get _isEtudiantOnly {
    final r = _getRole();
    return (r.contains('etudiant') ||
            r.contains('student') ||
            r.contains('authenticated')) &&
        !_isAdmin &&
        !_isEnseignantOnly &&
        !_isProfessionnel &&
        !_isAssociation;
  }

  bool get _isProfessionnel {
    final r = _getRole();
    return r.contains('professionnel') || r.contains('professional');
  }

  bool get _isAssociation {
    final r = _getRole();
    if (r.contains('association') || r.contains('association_member'))
      return true;
    try {
      final ctrl = Get.find<HomeController>();
      final email = ctrl.currentEmail.value.toLowerCase();
      final name = ctrl.currentUsername.value.toLowerCase();
      if (email.contains('association') || name.contains('association'))
        return true;
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final isMobile = MediaQuery.of(context).size.width < _mobileBreakpoint;

    if (isMobile && !drawerMode) {
      return const SizedBox.shrink();
    }

    return Obx(() {
      final isCollapsed = controller.isSidebarCollapsed.value;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        width: isCollapsed ? _collapsedWidth : _expandedWidth,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        padding: EdgeInsets.fromLTRB(
            isCollapsed ? 8 : 16, 20, isCollapsed ? 8 : 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(controller, isCollapsed),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildMenuItems(controller, isCollapsed),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildFooter(controller, isCollapsed),
          ],
        ),
      );
    });
  }

  List<Widget> _buildMenuItems(HomeController controller, bool isCollapsed) {
    final items = <Widget>[];
    final isAdmin = _isAdmin;
    final isEnseignant = _isEnseignantOnly;
    final isEtudiant = _isEtudiantOnly;
    final isProfessionnel = _isProfessionnel;

    final isGestionnaire = _isGestionnaire;

    // ── Items communs ────────────────────────────────────────────────────
    items.add(_menuItem(controller, 0, Icons.grid_view, 'Tableau de bord',
        Routes.HOME, isCollapsed));
    items.add(_menuItem(controller, 1, Icons.location_on_outlined,
        'Réserver un espace', Routes.PLAN, isCollapsed));
    items.add(_menuItem(controller, 2, Icons.calendar_today_outlined,
        'Mes Réservations', Routes.MY_RESERVATIONS, isCollapsed));
    items.add(const SizedBox(height: 8));

    // ── Admin ou Gestionnaire ─────────────────────────────────────────────
    if (isAdmin || isGestionnaire) {
      items.add(_menuItem(controller, 3, Icons.business_outlined, 'Espaces',
          Routes.SPACES, isCollapsed));
      items.add(_menuItem(controller, 4, Icons.build_circle_outlined,
          'Équipements', Routes.EQUIPMENTS, isCollapsed));

      if (isAdmin) {
        items.add(_menuItem(controller, 5, Icons.people_alt_outlined,
            'Utilisateurs', Routes.USERS, isCollapsed));
      }

      items.add(_menuItem(controller, 6, Icons.calendar_today_outlined,
          'Réservations', Routes.RESERVATIONS, isCollapsed));

      if (isAdmin) {
        items.add(_menuItem(controller, 7, Icons.handshake_outlined,
            'Associations', Routes.ASSOCIATIONS, isCollapsed));
      }
    }

    // ── Section ENSEIGNANT ───────────────────────────────────────────────
    if (isAdmin || isEnseignant) {
      items.add(const SizedBox(height: 20));
      items.add(_sectionTitle('ENSEIGNANT', isCollapsed));
      items.add(_menuItem(
          controller,
          8,
          Icons.menu_book_outlined,
          isEnseignant ? 'Mes formations' : 'Formations',
          Routes.FORMATIONS,
          isCollapsed));
      items.add(_menuItem(controller, 9, Icons.layers_outlined, 'Sessions',
          Routes.SESSIONS, isCollapsed));
      items.add(_menuItem(controller, 10, Icons.school_outlined, 'Étudiants',
          Routes.TEACHER_STUDENTS, isCollapsed));
      items.add(_menuItem(controller, 11, Icons.chrome_reader_mode_outlined,
          'Devoirs', Routes.DEVOIRS, isCollapsed));
      items.add(_menuItem(controller, 12, Icons.forum_outlined, 'Communication',
          Routes.COMMUNICATION, isCollapsed));
    }

    // ── Section ÉTUDIANT ─────────────────────────────────────────────────
    if (isAdmin || isEtudiant) {
      items.add(const SizedBox(height: 20));
      items.add(_sectionTitle('ÉTUDIANT', isCollapsed));
      items.add(_menuItem(controller, 13, Icons.menu_book_outlined, 'Mes cours',
          Routes.FORMATIONS, isCollapsed));
      items.add(_menuItem(controller, 14, Icons.assignment_outlined,
          'Mes devoirs', Routes.DEVOIRS, isCollapsed));
      items.add(_menuItem(controller, 15, Icons.school_outlined,
          'Catalogue de cours', Routes.FORMATIONS, isCollapsed));
      items.add(_menuItem(controller, 16, Icons.apartment_outlined,
          'Espaces d\'étude', Routes.STUDENT_SPACES, isCollapsed));
      items.add(_menuItem(controller, 17, Icons.calendar_today_outlined,
          'Sessions', Routes.SESSIONS, isCollapsed));
      items.add(_menuItem(controller, 19, Icons.groups_outlined,
          'Communication', Routes.COMMUNICATION, isCollapsed));
    }

    // ── Section PROFESSIONNEL ────────────────────────────────────────────
    if (isAdmin || isProfessionnel) {
      items.add(const SizedBox(height: 20));
      items.add(_sectionTitle('PROFESSIONNEL', isCollapsed));
      items.add(_menuItem(controller, 20, Icons.school_outlined, 'Formations',
          Routes.FORMATIONS, isCollapsed));
      items.add(_menuItem(controller, 21, Icons.credit_card_outlined,
          'Abonnements', Routes.PROFESSIONAL_SUBSCRIPTIONS, isCollapsed));
      items.add(_menuItem(controller, 22, Icons.person_outline, 'Mon profil',
          Routes.PROFILE, isCollapsed));
    }

    // ── Section ASSOCIATION ──────────────────────────────────────────────
    if (isAdmin) {
      items.add(const SizedBox(height: 20));
      items.add(_sectionTitle('ASSOCIATION', isCollapsed));
      items.add(_menuItem(controller, 23, Icons.menu_book_outlined,
          'Formations', Routes.FORMATIONS, isCollapsed));
      items.add(_menuItem(controller, 24, Icons.people_outline, 'Membres',
          Routes.ASSOCIATION_MEMBERS, isCollapsed));
      items.add(_menuItem(
          controller,
          25,
          Icons.bar_chart_outlined,
          'Budget & Utilisation',
          Routes.ASSOCIATION_BUDGET_USAGE,
          isCollapsed));
    }

    return items;
  }

  Widget _buildHeader(HomeController controller, bool isCollapsed) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: const Color(0xFF0B6BFF),
            borderRadius: BorderRadius.circular(8)),
        child: const Center(
          child: Text('S',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
      if (!isCollapsed) ...[
        const SizedBox(width: 10),
        const Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('SUNSPACE',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Dashboard',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
          ]),
        ),
        const SizedBox(width: 8),
      ] else
        const Spacer(),
      Tooltip(
        message: isCollapsed ? 'Agrandir le menu' : 'Réduire le menu',
        child: InkWell(
          onTap: controller.toggleSidebarCollapse,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Icon(
              isCollapsed
                  ? Icons.keyboard_double_arrow_right
                  : Icons.keyboard_double_arrow_left,
              size: 16,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _sectionTitle(String title, bool isCollapsed) {
    if (isCollapsed) return const SizedBox(height: 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 11)),
    );
  }

  Widget _buildFooter(HomeController controller, bool isCollapsed) {
    final storage = Get.find<StorageService>();
    final storedEmail = (storage.read<String>('last_login_email') ?? '').trim();
    final displayEmail = controller.currentEmail.value.isNotEmpty
        ? controller.currentEmail.value
        : storedEmail;
    final displayName = controller.currentUsername.value == 'Utilisateur' &&
            displayEmail.isNotEmpty
        ? displayEmail
        : controller.currentUsername.value;
    final displayInitial =
        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    if (isCollapsed) {
      return Column(children: [
        Tooltip(
          message: displayName,
          child: CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFDDEAFE),
            child: Text(displayInitial,
                style: const TextStyle(
                    color: Color(0xFF0B6BFF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 10),
        Tooltip(
          message: 'Paramètres',
          child: InkWell(
            onTap: controller.openSettings,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.settings_outlined,
                  size: 16, color: Color(0xFF0B6BFF)),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Tooltip(
          message: 'Déconnexion',
          child: InkWell(
            onTap: () => Get.offAllNamed(Routes.LOGIN),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(10)),
              child:
                  const Icon(Icons.logout, size: 16, color: Color(0xFF64748B)),
            ),
          ),
        ),
      ]);
    }

    return Column(children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFDDEAFE),
            child: Text(displayInitial,
                style: const TextStyle(
                    color: Color(0xFF0B6BFF), fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                displayEmail.isEmpty ? 'email indisponible' : displayEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ]),
          ),
          Tooltip(
            message: 'Paramètres',
            child: InkWell(
              onTap: controller.openSettings,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.settings_outlined,
                    size: 16, color: Color(0xFF0B6BFF)),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      InkWell(
        onTap: () => Get.offAllNamed(Routes.LOGIN),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 18, color: Colors.grey),
              SizedBox(width: 8),
              Text('Déconnexion',
                  style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _menuItem(
    HomeController controller,
    int index,
    IconData icon,
    String title,
    String route,
    bool isCollapsed,
  ) {
    return Obx(() {
      final isSelected = controller.selectedMenu.value == index;
      final content = Container(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B6BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment:
              isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 19),
            if (!isCollapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color:
                            isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13)),
              ),
            ],
          ],
        ),
      );

      final tappable = InkWell(
        onTap: () => controller.changeMenu(index, route),
        borderRadius: BorderRadius.circular(12),
        child: content,
      );

      return isCollapsed ? Tooltip(message: title, child: tappable) : tappable;
    });
  }
}
