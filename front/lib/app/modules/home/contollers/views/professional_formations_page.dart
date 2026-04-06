import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_formations_controller.dart';
import 'package:get/get.dart';

class ProfessionalFormationsPage
    extends GetView<ProfessionalFormationsController> {
  const ProfessionalFormationsPage({super.key});

  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF0B6BFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearch(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.school_outlined, color: _primary, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Mes formations',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Les formations créées par l’enseignant connecté apparaissent ici.',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _StatCard(
            value: controller.courses.length.toString(),
            label: 'Formations',
            highlighted: true,
          ),
        ],
      );
    });
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: TextField(
        onChanged: controller.setSearch,
        decoration: const InputDecoration(
          hintText: 'Rechercher une formation, un cours, une note...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.errorMessage.value.trim().isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_outlined,
                  size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: controller.loadInstructorCourses,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }

      final rows = controller.filteredCourses;

      if (rows.isEmpty) {
        return const Center(
          child: Text(
            'Aucune formation créée pour le moment',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadInstructorCourses(withLoader: false),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1200
                ? 3
                : width >= 820
                    ? 2
                    : 1;
            final cardWidth = (width - ((columns - 1) * 16)) / columns;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: rows
                    .map((course) => SizedBox(
                          width: cardWidth,
                          child: _SessionCard(
                            course: course,
                          ),
                        ))
                    .toList(),
              ),
            );
          },
        ),
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final bool highlighted;

  const _StatCard({
    required this.value,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 72,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEAF2FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              highlighted ? const Color(0xFFBCD7FF) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: highlighted
                  ? const Color(0xFF0B6BFF)
                  : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  final Course course;

  const _SessionCard({
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColor(course.level);
    final statusColor = course.status.toLowerCase().contains('publi')
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFBCD7FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school_outlined, size: 13, color: levelColor),
                    const SizedBox(width: 4),
                    Text(
                      course.level,
                      style: TextStyle(
                        color: levelColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Créé le ${_formatDate(course.createdAt)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.sell_outlined,
                  size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Text(
                course.status,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (course.description.trim().isNotEmpty) ...[
            Text(
              course.description.trim(),
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _badge(course.level, levelColor.withOpacity(0.12), levelColor),
              const SizedBox(width: 8),
              _badge(course.status, statusColor.withOpacity(0.12), statusColor),
            ],
          ),
        ],
      ),
    );
  }

  Color _levelColor(String level) {
    final normalized = level.toLowerCase();
    if (normalized.contains('avanc')) return const Color(0xFF7C3AED);
    if (normalized.contains('inter')) return const Color(0xFF2563EB);
    return const Color(0xFF16A34A);
  }

  Widget _badge(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';

    const weekdays = <String>[
      'lun.',
      'mar.',
      'mer.',
      'jeu.',
      'ven.',
      'sam.',
      'dim.',
    ];

    const months = <String>[
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];

    final wd = weekdays[value.weekday - 1];
    final d = value.day.toString();
    final month = months[value.month - 1];
    return '$wd $d $month ${value.year}';
  }
}
