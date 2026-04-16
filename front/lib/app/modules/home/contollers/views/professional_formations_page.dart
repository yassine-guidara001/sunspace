import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/training_session_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/professional_formations_controller.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfessionalFormationsPage
    extends GetView<ProfessionalFormationsController> {
  const ProfessionalFormationsPage({super.key});

  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF0B6BFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearch(),
          const SizedBox(height: 14),
          _buildTabs(),
          const SizedBox(height: 14),
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
                    SizedBox(width: 10),
                    Text(
                      'Formations Continues',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Inscrivez-vous aux sessions de formation disponibles pour développer vos compétences.',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _StatCard(
              value: _myFormationsCount().toString(),
              label: 'Mes inscriptions',
              highlighted: true),
          const SizedBox(width: 10),
          _StatCard(
              value: controller.availableSessionsCount.toString(),
              label: 'Disponibles'),
        ],
      );
    });
  }

  int _myFormationsCount() {
    return controller.mySessionsCount;
  }

  Widget _buildSearch() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.setSearch,
        decoration: const InputDecoration(
          hintText: 'Rechercher une formation, un cours, un formateur...',
          hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TabChip(
              icon: Icons.calendar_month_outlined,
              label: 'Sessions disponibles',
              count: controller.availableSessionsCount,
              active: controller.activeTab.value == 0,
              onTap: () => controller.setActiveTab(0),
            ),
            _TabChip(
              icon: Icons.check_circle_outline,
              label: 'Mes formations',
              count: _myFormationsCount(),
              active: controller.activeTab.value == 1,
              onTap: () => controller.setActiveTab(1),
            ),
          ],
        ),
      );
    });
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
                onPressed: controller.loadSessions,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        );
      }

      final rows = controller.visibleSessions;

      if (rows.isEmpty) {
        final emptyLabel = controller.activeTab.value == 1
            ? 'Aucune formation inscrite pour le moment'
            : 'Aucune session disponible pour le moment';
        return Center(
          child: Text(
            emptyLabel,
            style: const TextStyle(color: Color(0xFF94A3B8)),
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () => controller.loadSessions(withLoader: false),
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
                    .map((session) => SizedBox(
                          width: cardWidth,
                          child: _SessionCard(
                            session: session,
                            isEnrolled: controller.isEnrolled(session),
                            isEnrolling: controller.enrollingSessionIds
                                .contains(session.id),
                            onEnroll: () => controller.enrollInSession(session),
                            onUnenroll: () =>
                                controller.unenrollFromSession(session),
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
      width: 94,
      height: 64,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFDDEAFE) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
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
              fontSize: 30,
            ),
          ),
          const SizedBox(height: 3),
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
  final TrainingSession session;
  final bool isEnrolled;
  final bool isEnrolling;
  final VoidCallback onEnroll;
  final VoidCallback onUnenroll;

  const _SessionCard({
    required this.session,
    required this.isEnrolled,
    required this.isEnrolling,
    required this.onEnroll,
    required this.onUnenroll,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(session.type);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 14,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  session.title,
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
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.laptop_chromebook_rounded,
                        size: 13, color: typeColor),
                    const SizedBox(width: 4),
                    Text(
                      session.type.label,
                      style: TextStyle(
                        color: typeColor,
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
                  _formatDate(session.startDate ?? session.createdAt),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(Icons.schedule_outlined,
                  size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Text(
                _formatTimeRange(session.startDate, session.endDate),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.group_outlined,
                  size: 14, color: Color(0xFF60A5FA)),
              const SizedBox(width: 6),
              Text(
                '${session.participants.length} / ${session.maxParticipants} participants',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if ((session.meetingLink ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openMeetingLink(session.meetingLink),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded,
                        size: 14, color: Color(0xFF1D4ED8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _displayMeetingLink(session.meetingLink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Ouvrir',
                      style: TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if ((session.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              session.notes!.trim(),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isEnrolled
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: isEnrolled
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF0B6BFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEnrolling
                        ? 'En cours...'
                        : (isEnrolled ? 'Inscrit' : 'Disponible'),
                    style: TextStyle(
                      color: isEnrolled
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF0B6BFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 30,
                child: isEnrolled
                    ? OutlinedButton(
                        onPressed: isEnrolling ? null : onUnenroll,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Se désinscrire',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: isEnrolling ? null : onEnroll,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF0B6BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'S\'inscrire',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _typeColor(SessionType type) {
    switch (type) {
      case SessionType.presential:
        return const Color(0xFF16A34A);
      case SessionType.hybrid:
        return const Color(0xFF2563EB);
      case SessionType.online:
        return const Color(0xFF7C3AED);
    }
  }

  String _formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '--:-- → --:--';

    String hhmm(DateTime value) {
      final hh = value.hour.toString().padLeft(2, '0');
      final mm = value.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    }

    return '${hhmm(start)} → ${hhmm(end)}';
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

  String _displayMeetingLink(String? rawLink) {
    final text = (rawLink ?? '').trim();
    if (text.isEmpty) {
      return 'Lien de la session';
    }
    return text;
  }

  Uri? _normalizeMeetingUri(String? rawLink) {
    final text = (rawLink ?? '').trim();
    if (text.isEmpty) {
      return null;
    }

    final withScheme = text.startsWith('http://') || text.startsWith('https://')
        ? text
        : 'https://$text';

    return Uri.tryParse(withScheme);
  }

  Future<void> _openMeetingLink(String? rawLink) async {
    final uri = _normalizeMeetingUri(rawLink);
    if (uri == null) {
      Get.snackbar('Lien invalide', 'Le lien de réunion est invalide');
      return;
    }

    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      Get.snackbar('Ouverture impossible', 'Impossible d\'ouvrir le lien');
    }
  }
}

class _TabChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final bool active;
  final VoidCallback onTap;

  const _TabChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF8FAFC) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: const Color(0xFF111827),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color:
                    active ? const Color(0xFF0B6BFF) : const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
