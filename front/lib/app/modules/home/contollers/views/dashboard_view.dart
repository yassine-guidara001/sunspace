import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';

import 'custom_sidebar.dart';
import 'dashboard_topbar.dart';
import 'widgets/sunspace_ai_fab.dart';

class DashboardView extends GetView<HomeController> {
  const DashboardView({super.key});

  // ── Rôle ──────────────────────────────────────────────────────────────────
  String _getRole() {
    try {
      final userData = Get.find<StorageService>().getUserData();
      if (userData == null) return '';
      final role = userData['role'];
      if (role is Map)
        return (role['name'] ?? role['type'] ?? '').toString().toLowerCase();
      if (role is String) return role.toLowerCase();
    } catch (_) {}
    return '';
  }

  bool get _isEnseignant {
    final r = _getRole();
    return r.contains('enseignant') || r.contains('teacher');
  }

  bool get _isEtudiant {
    final r = _getRole();
    return (r.contains('etudiant') ||
            r.contains('student') ||
            r.contains('authenticated')) &&
        !_isEnseignant &&
        !_isProfessionnel &&
        !_isAssociation &&
        _getRole().isNotEmpty;
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
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF4),
      floatingActionButton: const SunspaceAiFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Row(children: [
        const CustomSidebar(),
        Expanded(
          child: Column(children: [
            const DashboardTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
                child: LayoutBuilder(builder: (context, constraints) {
                  if (_isEnseignant) {
                    return _TeacherDashboard(controller: controller);
                  }
                  if (_isEtudiant) {
                    return _StudentDashboard(controller: controller);
                  }
                  if (_isProfessionnel) {
                    return _ProfessionnelDashboard(controller: controller);
                  }
                  if (_isAssociation) {
                    return _AssociationDashboard(
                        controller: controller, width: constraints.maxWidth);
                  }
                  return _AdminDashboard(
                      controller: controller, width: constraints.maxWidth);
                }),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Dashboard Enseignant ─────────────────────────────────────────────────────
class _TeacherDashboard extends StatelessWidget {
  final HomeController controller;
  const _TeacherDashboard({required this.controller});

  String get _name {
    final raw = controller.currentUsername.value.trim();
    final email = controller.currentEmail.value.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'utilisateur') {
      return email.contains('@') ? email.split('@').first : email;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Obx(() =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tableau de bord',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Bienvenue $_name',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155))),
            ])),
        const SizedBox(height: 20),

        // ── Layout desktop ───────────────────────────────────────────────
        LayoutBuilder(builder: (ctx, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          final mainCard = _buildTeacherTasks();
          final sideCard = _buildOptimizationCard();

          if (desktop) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: mainCard),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: sideCard),
            ]);
          }
          return Column(
              children: [mainCard, const SizedBox(height: 16), sideCard]);
        }),

        const SizedBox(height: 16),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildTeacherTasks() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4DCE6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Gestion des Enseignements',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Tâches pédagogiques en attente',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 20),
        _taskItem(
          icon: Icons.menu_book_outlined,
          iconColor: const Color(0xFF0B6BFF),
          iconBg: const Color(0xFFDBEAFE),
          title: 'Gérer mes formations',
          subtitle: 'Créez et modifiez vos cours',
          onTap: () => controller.changeMenu(8, Routes.FORMATIONS),
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.people_outline,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          title: 'Suivi des étudiants',
          subtitle: 'Consultez les progrès de vos élèves',
          onTap: () => controller.changeMenu(10, Routes.TEACHER_STUDENTS),
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.calendar_month_outlined,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFFEF3C7),
          title: 'Planifier une session',
          subtitle: 'Organisez une nouvelle session de formation',
          onTap: () => controller.changeMenu(9, Routes.SESSIONS),
        ),
      ]),
    );
  }

  Widget _taskItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ])),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ]),
      ),
    );
  }

  Widget _buildOptimizationCard() {
    return Column(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1664FF), Color(0xFF2684FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Optimisez votre temps',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          const SizedBox(height: 8),
          const Text(
            'Réservez vos créneaux de formation à l\'avance pour garantir votre place.',
            style:
                TextStyle(color: Color(0xFFE5EEFF), height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.changeMenu(1, Routes.PLAN),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1458E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réserver maintenant',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Cours populaires
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4DCE6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COURS POPULAIRES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          _courseItem('Démarrage avec Next.js', 324, 4.8),
          const SizedBox(height: 10),
          _courseItem('Design UX/UI', 412, 4.9),
          const SizedBox(height: 10),
          _courseItem('Maîtriser TypeScript', 189, 4.7),
        ]),
      ),
    ]);
  }

  Widget _courseItem(String title, int students, double rating) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: const Color(0xFFE2ECFF),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.school_outlined,
            size: 14, color: Color(0xFF1D4ED8)),
      ),
      const SizedBox(width: 10),
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
      Row(children: [
        const Icon(Icons.people_outline, size: 12, color: Color(0xFF64748B)),
        const SizedBox(width: 2),
        Text('$students',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text('$rating',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]),
    ]);
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Réserver',
        'icon': Icons.location_on_outlined,
        'index': 1,
        'route': Routes.PLAN
      },
      {
        'label': 'Mes Formations',
        'icon': Icons.menu_book_outlined,
        'index': 8,
        'route': Routes.FORMATIONS
      },
      {
        'label': 'Catalogue',
        'icon': Icons.school_outlined,
        'index': 8,
        'route': Routes.FORMATIONS
      },
      {
        'label': 'Mon Profil',
        'icon': Icons.person_outline,
        'index': 0,
        'route': Routes.HOME
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions rapides',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A))),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (ctx, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            final isFirst = i == 0;
            return InkWell(
              onTap: () => controller.changeMenu(
                  a['index'] as int, a['route'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4DCE6)),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a['icon'] as IconData,
                          size: 15,
                          color: isFirst
                              ? const Color(0xFF0B6BFF)
                              : const Color(0xFF475569)),
                      const SizedBox(height: 5),
                      Text(a['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFirst
                                  ? const Color(0xFF0B6BFF)
                                  : const Color(0xFF0F172A))),
                    ]),
              ),
            );
          },
        );
      }),
    ]);
  }
}

// ─── Dashboard Étudiant ───────────────────────────────────────────────────────
class _StudentDashboard extends StatelessWidget {
  final HomeController controller;
  const _StudentDashboard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Obx(() {
        final name = controller.currentUsername.value.trim().isEmpty
            ? 'Étudiant'
            : controller.currentUsername.value;
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tableau de bord',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
          Text('Bienvenue $name',
              style: const TextStyle(fontSize: 18, color: Color(0xFF334155))),
        ]);
      }),
      const SizedBox(height: 20),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4DCE6)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mes activités',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _item(Icons.menu_book_outlined, 'Mes cours', 'Accéder à vos cours',
              () => controller.changeMenu(13, Routes.FORMATIONS)),
          const Divider(height: 20),
          _item(
              Icons.apartment_outlined,
              'Espaces d\'étude',
              'Réserver un espace',
              () => controller.changeMenu(16, Routes.STUDENT_SPACES)),
          const Divider(height: 20),
          _item(Icons.assignment_outlined, 'Mes devoirs', 'Voir vos devoirs',
              () => controller.changeMenu(14, Routes.DEVOIRS)),
        ]),
      ),
    ]);
  }

  Widget _item(IconData icon, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF0B6BFF), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(sub,
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ])),
        const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
      ]),
    );
  }
}

// ─── Dashboard Professionnel ──────────────────────────────────────────────────
class _ProfessionnelDashboard extends StatelessWidget {
  final HomeController controller;
  const _ProfessionnelDashboard({required this.controller});

  String get _name {
    final raw = controller.currentUsername.value.trim();
    final email = controller.currentEmail.value.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'utilisateur') {
      return email.contains('@') ? email.split('@').first : email;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────────────
        Obx(() =>
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tableau de bord',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Bienvenue $_name',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155))),
            ])),
        const SizedBox(height: 20),

        // ── Layout desktop ───────────────────────────────────────────────
        LayoutBuilder(builder: (ctx, constraints) {
          final desktop = constraints.maxWidth >= 1000;
          final mainCard = _buildGestionCard();
          final sideCard = _buildRightPanel();

          if (desktop) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: mainCard),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: sideCard),
            ]);
          }
          return Column(
              children: [mainCard, const SizedBox(height: 16), sideCard]);
        }),

        const SizedBox(height: 16),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildGestionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4DCE6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Gestion Professionnelle',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        const Text('Vos outils de productivité',
            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        const SizedBox(height: 20),
        _taskItem(
          icon: Icons.apartment_outlined,
          iconColor: const Color(0xFF0B6BFF),
          iconBg: const Color(0xFFDBEAFE),
          title: 'Mes Espaces',
          subtitle: 'Gérez vos espaces de travail',
          onTap: () => controller.changeMenu(
              3, Routes.SPACES), // Or a specific spaces route
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.assignment_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          title: 'Mes Réservations',
          subtitle: 'Consultez vos réservations passées et futures',
          onTap: () => controller.changeMenu(2, Routes.MY_RESERVATIONS),
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.credit_card_outlined,
          iconColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFFEDE9FE),
          title: 'Formations & Abonnements',
          subtitle: 'Suivez vos abonnements actifs',
          onTap: () =>
              controller.changeMenu(21, Routes.PROFESSIONAL_SUBSCRIPTIONS),
        ),
      ]),
    );
  }

  Widget _taskItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ])),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ]),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1664FF), Color(0xFF2684FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Optimisez votre temps',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          const SizedBox(height: 8),
          const Text(
            'Réservez vos créneaux de formation à l\'avance pour garantir votre place.',
            style:
                TextStyle(color: Color(0xFFE5EEFF), height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.changeMenu(1, Routes.PLAN),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1458E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réserver maintenant',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Cours populaires
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4DCE6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COURS POPULAIRES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          _courseItem('Démarrage avec Next.js', 324, 4.8),
          const SizedBox(height: 10),
          _courseItem('Design UX/UI', 412, 4.9),
          const SizedBox(height: 10),
          _courseItem('Maîtriser TypeScript', 189, 4.7),
        ]),
      ),
    ]);
  }

  Widget _courseItem(String title, int students, double rating) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: const Color(0xFFE2ECFF),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.school_outlined,
            size: 14, color: Color(0xFF1D4ED8)),
      ),
      const SizedBox(width: 10),
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
      Row(children: [
        const Icon(Icons.people_outline, size: 12, color: Color(0xFF64748B)),
        const SizedBox(width: 2),
        Text('$students',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text('$rating',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]),
    ]);
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'label': 'Réserver',
        'icon': Icons.location_on_outlined,
        'index': 1,
        'route': Routes.PLAN
      },
      {
        'label': 'Espaces',
        'icon': Icons.apartment_outlined,
        'index': 3,
        'route': Routes.SPACES
      },
      {
        'label': 'Réservations',
        'icon': Icons.calendar_today_outlined,
        'index': 2,
        'route': Routes.MY_RESERVATIONS
      },
      {
        'label': 'Mon Profil',
        'icon': Icons.person_outline,
        'index': 22,
        'route': Routes.PROFILE
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions rapides',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A))),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (ctx, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            final isFirst = i == 0;
            return InkWell(
              onTap: () => controller.changeMenu(
                  a['index'] as int, a['route'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4DCE6)),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a['icon'] as IconData,
                          size: 15,
                          color: isFirst
                              ? const Color(0xFF0B6BFF)
                              : const Color(0xFF475569)),
                      const SizedBox(height: 5),
                      Text(a['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFirst
                                  ? const Color(0xFF0B6BFF)
                                  : const Color(0xFF0F172A))),
                    ]),
              ),
            );
          },
        );
      }),
    ]);
  }
}

// ─── Dashboard Association ────────────────────────────────────────────────────
class _AssociationDashboard extends StatelessWidget {
  final HomeController controller;
  final double width;
  const _AssociationDashboard({required this.controller, required this.width});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _header(),
      const SizedBox(height: 20),
      _centerContent(),
      const SizedBox(height: 16),
      _quickActionsSection(),
    ]);
  }

  Widget _header() {
    return Obx(() {
      var name = controller.currentUsername.value.trim();
      if (name.isEmpty || name.toLowerCase() == 'utilisateur') {
        name = controller.currentEmail.value.split('@').first;
      }
      if (name.isEmpty) name = 'association_member';

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tableau de bord',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('Bienvenue $name',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155))),
      ]);
    });
  }

  Widget _centerContent() {
    final desktop = width >= 1000;
    final mainCard = _buildGestionCard();
    final sideCard = _buildRightPanel();

    if (desktop) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 3, child: mainCard),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: sideCard),
      ]);
    }
    return Column(children: [mainCard, const SizedBox(height: 16), sideCard]);
  }

  Widget _buildGestionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4DCE6)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Bienvenue sur SUNSPACE',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                SizedBox(height: 4),
                Text('Gérez votre espace de travail',
                    style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.grid_view,
                  size: 16, color: Color(0xFF0B6BFF)),
            )
          ],
        ),
        const SizedBox(height: 24),
        _taskItem(
          icon: Icons.grid_view,
          iconColor: const Color(0xFF0B6BFF),
          iconBg: const Color(0xFFDBEAFE),
          title: 'Tableau de bord',
          subtitle: "Vue d'ensemble de votre activité",
          onTap: () => controller.changeMenu(0, Routes.HOME),
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.calendar_today_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFDCFCE7),
          title: 'Réserver un espace',
          subtitle: 'Trouvez et réservez votre bureau',
          onTap: () => controller.changeMenu(1, Routes.PLAN),
        ),
        const Divider(height: 24),
        _taskItem(
          icon: Icons.person_outline,
          iconColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFFEDE9FE),
          title: 'Mon Profil',
          subtitle: 'Gérez vos informations personnelles',
          onTap: () => controller.changeMenu(22, Routes.PROFILE),
        ),
      ]),
    );
  }

  Widget _taskItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF64748B))),
              ])),
          const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
        ]),
      ),
    );
  }

  Widget _buildRightPanel() {
    return Column(children: [
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1664FF), Color(0xFF2684FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Optimisez votre temps',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17)),
          const SizedBox(height: 8),
          const Text(
            'Réservez vos créneaux de formation à l\'avance pour garantir votre place.',
            style:
                TextStyle(color: Color(0xFFE5EEFF), height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.changeMenu(1, Routes.PLAN),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1458E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Réserver maintenant',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      // Cours populaires
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFD4DCE6)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('COURS POPULAIRES',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1)),
          const SizedBox(height: 12),
          _courseItem('Démarrage avec Next.js', 224, 4.8),
          const SizedBox(height: 10),
          _courseItem('Design UX/UI', 412, 4.9),
          const SizedBox(height: 10),
          _courseItem('Maîtriser TypeScript', 189, 4.7),
        ]),
      ),
    ]);
  }

  Widget _courseItem(String title, int students, double rating) {
    return Row(children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
            color: const Color(0xFFE2ECFF),
            borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.school_outlined,
            size: 14, color: Color(0xFF1D4ED8)),
      ),
      const SizedBox(width: 10),
      Expanded(
          child: Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
      Row(children: [
        const Icon(Icons.people_outline, size: 12, color: Color(0xFF64748B)),
        const SizedBox(width: 2),
        Text('$students',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(width: 8),
        const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
        const SizedBox(width: 2),
        Text('$rating',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
      ]),
    ]);
  }

  Widget _quickActionsSection() {
    final actions = [
      {
        'label': 'Tableau de bord',
        'icon': Icons.grid_view,
        'index': 0,
        'route': Routes.HOME
      },
      {
        'label': 'Réserver',
        'icon': Icons.calendar_today_outlined,
        'index': 1,
        'route': Routes.PLAN
      },
      {
        'label': 'Paramètres',
        'icon': Icons.settings_outlined,
        'index': -1,
        'route': Routes.SETTINGS
      },
      {
        'label': 'Mon Profil',
        'icon': Icons.person_outline,
        'index': 22,
        'route': Routes.PROFILE
      },
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions rapides',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A))),
      const SizedBox(height: 12),
      LayoutBuilder(builder: (ctx, constraints) {
        final cols = constraints.maxWidth >= 900 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.0,
          ),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            final isFirst = i == 0;
            return InkWell(
              onTap: () {
                if (a['route'] == Routes.SETTINGS) {
                  controller.openSettings();
                } else {
                  controller.changeMenu(
                      a['index'] as int, a['route'] as String);
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4DCE6)),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(a['icon'] as IconData,
                          size: 15,
                          color: isFirst
                              ? const Color(0xFF0B6BFF)
                              : const Color(0xFF475569)),
                      const SizedBox(height: 5),
                      Text(a['label'] as String,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isFirst
                                  ? const Color(0xFF0B6BFF)
                                  : const Color(0xFF0F172A))),
                    ]),
              ),
            );
          },
        );
      }),
    ]);
  }
}

// ─── Dashboard Admin (original) ───────────────────────────────────────────────
class _AdminDashboard extends StatelessWidget {
  final HomeController controller;
  final double width;
  const _AdminDashboard({required this.controller, required this.width});

  static const _quickActions = [
    _ActionData('Espaces', Icons.apartment_outlined, 3, Routes.SPACES),
    _ActionData('Utilisateurs', Icons.group_outlined, 5, Routes.USERS),
    _ActionData(
        'Réservations', Icons.calendar_today_outlined, 6, Routes.RESERVATIONS),
    _ActionData('Système', Icons.settings_outlined, 25, Routes.SETTINGS),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
        () => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(),
              const SizedBox(height: 20),
              _statsGrid(),
              const SizedBox(height: 16),
              _centerContent(),
              const SizedBox(height: 16),
              _quickActionsSection(),
              const SizedBox(height: 16),
              _bottomStats(),
            ]));
  }

  List<_StatData> _stats() {
    final s = controller.dashboardSummary.value;
    return [
      _StatData(
        'Espaces Totaux',
        '${s.totalSpaces}',
        s.spacesSubtitle,
        Icons.apartment_rounded,
        const Color(0xFF1F6FEB),
      ),
      _StatData(
        'Réservations Actives',
        '${s.activeReservations}',
        s.reservationsSubtitle,
        Icons.calendar_month_outlined,
        const Color(0xFFF59E0B),
      ),
      _StatData(
        'Cours Publiés',
        '${s.publishedCourses}',
        s.coursesSubtitle,
        Icons.menu_book_rounded,
        const Color(0xFF16A34A),
      ),
      _StatData(
        'Utilisateurs Actifs',
        '${s.activeUsers}',
        s.usersSubtitle,
        Icons.groups_2_outlined,
        const Color(0xFFA855F7),
      ),
    ];
  }

  List<_ActivityData> _activities() {
    final rows = controller.dashboardActivities;
    if (rows.isEmpty) {
      return const [
        _ActivityData('Aucune activité', '---', '--/--/----', 'En attente'),
      ];
    }
    return rows
        .map((row) => _ActivityData(
              row['title'] ?? 'Reservation',
              row['client'] ?? 'Utilisateur',
              row['date'] ?? '--/--/----',
              row['status'] ?? 'En attente',
            ))
        .toList();
  }

  List<_CourseData> _courses() {
    final rows = controller.dashboardPopularCourses;
    if (rows.isEmpty) {
      return const [
        _CourseData('Aucun cours disponible', 0, 0),
      ];
    }
    return rows
        .map((row) => _CourseData(
              (row['title'] ?? 'Cours').toString(),
              row['students'] is int
                  ? row['students'] as int
                  : int.tryParse('${row['students']}') ?? 0,
              row['rating'] is num
                  ? (row['rating'] as num).toDouble()
                  : double.tryParse('${row['rating']}') ?? 0,
            ))
        .toList();
  }

  Widget _header() {
    return Obx(() {
      var name = controller.currentUsername.value.trim();
      if (name.isEmpty || name.toLowerCase() == 'utilisateur') {
        name = controller.currentEmail.value.split('@').first;
      }
      if (name.isEmpty) name = 'intern';

      return Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Tableau de bord',
              style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          Text('Bienvenue $name',
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155))),
        ])),
        if (controller.isDashboardLoading.value)
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        SizedBox(
          height: 38,
          child: OutlinedButton.icon(
            onPressed: controller.loadDashboardData,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF334155),
              side: const BorderSide(color: Color(0xFFD4DCE6)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 38,
          child: ElevatedButton.icon(
            onPressed: () => controller.changeMenu(3, Routes.SPACES),
            icon: const Icon(Icons.library_add_outlined, size: 16),
            label: const Text('Ajouter un espace'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]);
    });
  }

  Widget _statsGrid() {
    final cols = width >= 1200
        ? 4
        : width >= 900
            ? 2
            : 1;
    final ratio = width >= 1200
        ? 2.8
        : width >= 900
            ? 2.6
            : 3.1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: ratio),
      itemCount: _stats().length,
      itemBuilder: (_, i) => StatCard(
          title: _stats()[i].title,
          value: _stats()[i].value,
          subtitle: _stats()[i].subtitle,
          icon: _stats()[i].icon,
          iconColor: _stats()[i].iconColor),
    );
  }

  Widget _centerContent() {
    final desktop = width >= 1100;
    final activities = _buildActivities();
    final side = Column(children: [
      _buildOptCard(),
      const SizedBox(height: 12),
      _buildCoursesCard(),
    ]);
    if (!desktop)
      return Column(children: [activities, const SizedBox(height: 12), side]);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 3, child: activities),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: side),
    ]);
  }

  Widget _buildActivities() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4DCE6))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('Activités récentes',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A))),
                  Text('Dernières réservations effectuées',
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ])),
            TextButton.icon(
              onPressed: () => controller.changeMenu(6, Routes.RESERVATIONS),
              icon: const Text('Voir tout'),
              label: const Icon(Icons.arrow_forward, size: 14),
            ),
          ]),
          const SizedBox(height: 8),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities().length,
            separatorBuilder: (_, __) => const Divider(height: 18),
            itemBuilder: (_, i) => ActivityItem(
                title: _activities()[i].title,
                client: _activities()[i].client,
                date: _activities()[i].date,
                status: _activities()[i].status),
          ),
        ]),
      ),
    );
  }

  Widget _buildOptCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1664FF), Color(0xFF2684FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Optimisez votre temps',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 17)),
        const SizedBox(height: 8),
        const Text(
            'Consultez les rapports détaillés pour une gestion plus fine.',
            style: TextStyle(color: Color(0xFFE5EEFF), height: 1.4)),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.openSettings,
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1458E0),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Paramètres'),
          ),
        ),
      ]),
    );
  }

  Widget _buildCoursesCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4DCE6))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Cours populaires',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 10),
          ..._courses().map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE2ECFF),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.school_outlined,
                          size: 16, color: Color(0xFF1D4ED8))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(c.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Row(children: [
                          const Icon(Icons.person_outline,
                              size: 12, color: Color(0xFF64748B)),
                          Text(' ${c.students}  ',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                          const Icon(Icons.star_rounded,
                              size: 12, color: Color(0xFFF59E0B)),
                          Text(' ${c.rating}',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF64748B))),
                        ]),
                      ])),
                ]),
              )),
        ]),
      ),
    );
  }

  Widget _quickActionsSection() {
    final cols = width >= 1200
        ? 4
        : width >= 700
            ? 2
            : 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Actions rapides',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A))),
      const SizedBox(height: 12),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _quickActions.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 4.4),
        itemBuilder: (_, i) => QuickActionButton(
          label: _quickActions[i].label,
          icon: _quickActions[i].icon,
          onTap: () {
            if (_quickActions[i].route == Routes.SETTINGS) {
              controller.openSettings();
              return;
            }
            controller.changeMenu(
                _quickActions[i].menuIndex, _quickActions[i].route);
          },
        ),
      ),
    ]);
  }

  Widget _bottomStats() {
    final stacked = width < 980;
    final s = controller.dashboardSummary.value;
    final r = ProgressStatCard(
        title: 'Revenu du mois',
        value: s.monthlyRevenueLabel,
        deltaText: 'Backend',
        progressValue: s.occupancyProgress,
        progressColor: const Color(0xFF22C55E),
        helperText: 'Mis a jour en direct',
        icon: Icons.attach_money_rounded);
    final o = ProgressStatCard(
        title: "Taux d'occupation",
        value: s.occupancyLabel,
        deltaText: 'Backend',
        progressValue: s.occupancyProgress,
        progressColor: const Color(0xFF2563EB),
        helperText: s.occupancyHelperText,
        icon: Icons.bar_chart_rounded);
    if (stacked) return Column(children: [r, const SizedBox(height: 10), o]);
    return Row(children: [
      Expanded(child: r),
      const SizedBox(width: 12),
      Expanded(child: o)
    ]);
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  const StatCard(
      {super.key,
      required this.title,
      required this.value,
      required this.subtitle,
      required this.icon,
      required this.iconColor});
  final String title, value, subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4DCE6))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
        child: Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 9,
                        letterSpacing: 0.7,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(value,
                    style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 33,
                        height: 1,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 12, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF22C55E),
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ]),
              ])),
          Icon(icon, color: iconColor, size: 18),
        ]),
      ),
    );
  }
}

class ActivityItem extends StatelessWidget {
  const ActivityItem(
      {super.key,
      required this.title,
      required this.client,
      required this.date,
      required this.status});
  final String title, client, date, status;

  @override
  Widget build(BuildContext context) {
    final isPending = status.toLowerCase() == 'en attente';
    final bg = isPending ? const Color(0xFFFACC15) : const Color(0xFF22C55E);
    final text = isPending ? const Color(0xFF854D0E) : const Color(0xFF166534);
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
        Text('Client: $client - $date',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bg.withOpacity(0.16),
            borderRadius: BorderRadius.circular(999)),
        child: Text(status,
            style: TextStyle(
                color: text, fontWeight: FontWeight.w700, fontSize: 11)),
      ),
    ]);
  }
}

class QuickActionButton extends StatelessWidget {
  const QuickActionButton(
      {super.key,
      required this.label,
      required this.icon,
      required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Ink(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4DCE6))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 15, color: const Color(0xFF475569)),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A))),
        ]),
      ),
    );
  }
}

class ProgressStatCard extends StatelessWidget {
  const ProgressStatCard(
      {super.key,
      required this.title,
      required this.value,
      required this.deltaText,
      required this.progressValue,
      required this.progressColor,
      required this.helperText,
      required this.icon});
  final String title, value, deltaText, helperText;
  final double progressValue;
  final Color progressColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFD4DCE6))),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w600))),
            Icon(icon, color: progressColor, size: 16),
          ]),
          const SizedBox(height: 16),
          Text(value,
              style: const TextStyle(
                  fontSize: 37,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 20),
          Row(children: [
            Text(deltaText,
                style: TextStyle(
                    color: progressColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(helperText,
                style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ]),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progressValue,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Data classes ─────────────────────────────────────────────────────────────
class _StatData {
  const _StatData(
      this.title, this.value, this.subtitle, this.icon, this.iconColor);
  final String title, value, subtitle;
  final IconData icon;
  final Color iconColor;
}

class _ActivityData {
  const _ActivityData(this.title, this.client, this.date, this.status);
  final String title, client, date, status;
}

class _CourseData {
  const _CourseData(this.title, this.students, this.rating);
  final String title;
  final int students;
  final double rating;
}

class _ActionData {
  const _ActionData(this.label, this.icon, this.menuIndex, this.route);
  final String label, route;
  final IconData icon;
  final int menuIndex;
}
