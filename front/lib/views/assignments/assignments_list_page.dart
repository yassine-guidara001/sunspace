import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/student_course_access_page.dart';
import 'package:flutter_getx_app/controllers/assignments_controller.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/views/assignments/assignment_details_page.dart';
import 'package:flutter_getx_app/views/assignments/assignment_form_page.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';

class AssignmentsListPage extends GetView<AssignmentsController> {
  const AssignmentsListPage({super.key});

  static const Color _pageBg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(),
                Expanded(child: _AssignmentsListContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentsListContent extends StatefulWidget {
  const _AssignmentsListContent();

  @override
  State<_AssignmentsListContent> createState() =>
      _AssignmentsListContentState();
}

class _AssignmentsListContentState extends State<_AssignmentsListContent> {
  static const int _studentAssignmentsMenuIndex = 14;

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final controller = Get.find<AssignmentsController>();
    controller.fetchCourses();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssignmentsController>();
    final home = Get.find<HomeController>();

    return Obx(() {
      final isStudentMode =
          home.selectedMenu.value == _studentAssignmentsMenuIndex;

      return Padding(
        padding: const EdgeInsets.all(24),
        child: isStudentMode
            ? _buildStudentContent(controller)
            : _buildTeacherContent(controller),
      );
    });
  }

  Widget _buildTeacherContent(AssignmentsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: AssignmentsListPage._primary, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Devoirs',
                      style: TextStyle(
                        height: 1.02,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Gérez les devoirs et les évaluations',
                  style: TextStyle(
                    color: Color(0xFF757575),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: () => Get.to(() => const AssignmentFormPage()),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau Devoir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AssignmentsListPage._primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AssignmentsListPage._border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher un devoir...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AssignmentsListPage._border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AssignmentsListPage._border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AssignmentsListPage._border),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AssignmentsListPage._border),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 3, child: _HeadCell('Titre')),
                      Expanded(flex: 2, child: _HeadCell('Cours')),
                      Expanded(flex: 2, child: _HeadCell('Échéance')),
                      Expanded(flex: 2, child: _HeadCell('Points')),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _HeadCell('Actions'),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final query = _searchCtrl.text.trim().toLowerCase();
                    final rows = controller.assignments.where((item) {
                      if (query.isEmpty) return true;
                      return item.title.toLowerCase().contains(query) ||
                          item.courseName.toLowerCase().contains(query);
                    }).toList();

                    if (rows.isEmpty &&
                        controller.errorMessage.value.trim().isNotEmpty) {
                      return _buildErrorState(controller);
                    }

                    if (rows.isEmpty) {
                      return _buildEmptyState('Aucun devoir trouvé');
                    }

                    return ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        thickness: 1,
                        color: AssignmentsListPage._border,
                      ),
                      itemBuilder: (_, index) {
                        final item = rows[index];
                        return Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.courseName,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _formatDate(item.dueDate),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item.maxPoints.toString(),
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        tooltip: 'Voir',
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        onPressed: () async {
                                          final detailed = await controller
                                              .fetchAssignmentById(
                                            item.id,
                                            documentId: item.documentId,
                                          );
                                          if (detailed == null) return;

                                          Get.to(
                                            () => AssignmentDetailsPage(
                                              assignment: detailed,
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove_red_eye_outlined,
                                          color: Color(0xFF6B7280),
                                          size: 17,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Modifier',
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        onPressed: () => Get.to(
                                          () => AssignmentFormPage(
                                            assignment: item,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF111827),
                                          size: 17,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Supprimer',
                                        visualDensity: VisualDensity.compact,
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        onPressed: () {
                                          Get.defaultDialog(
                                            title: 'Confirmer',
                                            middleText: 'Supprimer ce devoir ?',
                                            textCancel: 'Annuler',
                                            textConfirm: 'Supprimer',
                                            confirmTextColor: Colors.white,
                                            buttonColor:
                                                const Color(0xFFD32F2F),
                                            onConfirm: () async {
                                              Get.back();
                                              await controller.removeAssignment(
                                                item.id,
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFD32F2F),
                                          size: 17,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentContent(AssignmentsController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.assignment_outlined, color: Color(0xFF3B82F6), size: 28),
            SizedBox(width: 10),
            Text(
              'Mes Devoirs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
                height: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Gérez vos soumissions et consultez vos notes.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Rechercher un devoir...',
              hintStyle: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: Color(0xFF9CA3AF),
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final query = _searchCtrl.text.trim().toLowerCase();
            final rows = controller.assignments.where((item) {
              if (query.isEmpty) return true;
              return item.title.toLowerCase().contains(query) ||
                  item.courseName.toLowerCase().contains(query);
            }).toList();

            if (rows.isEmpty &&
                controller.errorMessage.value.trim().isNotEmpty) {
              return _buildErrorState(controller);
            }

            if (rows.isEmpty) {
              return _buildEmptyState('Aucun devoir disponible');
            }

            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (_, index) {
                final item = rows[index];
                final now = DateTime.now();
                final isOverdue = item.dueDate.isBefore(now);
                final statusText = isOverdue ? 'En retard' : 'À faire';
                final statusBg = isOverdue
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFFEF3C7);
                final statusFg = isOverdue
                    ? const Color(0xFFEA580C)
                    : const Color(0xFFEA580C);

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFFE5E7EB), width: 1),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCEEFD),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'TEST',
                                    style: TextStyle(
                                      color: Color(0xFF3B82F6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      color: statusFg,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Échéance: ${_formatDate(item.dueDate)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                const Icon(
                                  Icons.star_border,
                                  size: 16,
                                  color: Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.maxPoints} Points',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      SizedBox(
                        height: 42,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _openSubmissionFlow(controller, item);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Soumettre',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.chevron_right, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildErrorState(AssignmentsController controller) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 10),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: controller.fetchAssignments,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 42, color: Color(0xFF94A3B8)),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  Future<void> _openSubmissionFlow(
    AssignmentsController controller,
    Assignment assignment,
  ) async {
    final resolvedCourse =
        await _resolveCourseForAssignment(controller, assignment);
    if (!mounted) return;

    Get.to(
      () => StudentCourseAccessPage(
        course: resolvedCourse,
        initialTab: 0,
      ),
    );
  }

  Future<Course> _resolveCourseForAssignment(
    AssignmentsController controller,
    Assignment assignment,
  ) async {
    final assignmentCourseId = assignment.courseId;
    final assignmentCourseDocumentId =
        (assignment.courseDocumentId?.toString().trim() ?? '');

    final fromLoadedList = controller.courses.firstWhereOrNull((course) {
      if (assignmentCourseId != null && course.id == assignmentCourseId) {
        return true;
      }

      if (assignmentCourseDocumentId.isNotEmpty &&
          course.documentId.trim() == assignmentCourseDocumentId) {
        return true;
      }

      return false;
    });

    if (fromLoadedList != null) {
      return fromLoadedList;
    }

    if (assignmentCourseId != null && assignmentCourseId > 0) {
      try {
        return await CoursesApi().getCourseById(assignmentCourseId);
      } catch (_) {
        // ignore and fallback to minimal course object
      }
    }

    final fallbackTitle = assignment.courseName.toString().trim().isNotEmpty
        ? assignment.courseName.toString().trim()
        : 'Cours';

    return Course(
      id: assignmentCourseId ?? 0,
      documentId: assignmentCourseDocumentId,
      title: fallbackTitle,
      description: '',
      level: 'Intermédiaire',
      price: 0,
      status: 'Publié',
      createdAt: DateTime.now(),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String text;

  const _HeadCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
    );
  }
}
