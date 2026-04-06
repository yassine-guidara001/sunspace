import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/models/training_session_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/training_sessions_controller.dart';
import 'package:get/get.dart';

class TrainingSessionsPage extends GetView<TrainingSessionsController> {
  const TrainingSessionsPage({super.key});

  static const int _studentSessionsMenuIndex = 17;
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF3B5BDB);

  HomeController get _homeController => Get.find<HomeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Obx(
        () {
          final isStudentMode =
              _homeController.selectedMenu.value == _studentSessionsMenuIndex;

          if (isStudentMode) {
            return _buildStudentSessionsView();
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                Expanded(child: _buildTable()),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStudentSessionsView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_note_outlined,
                  color: Color(0xFF0B6BFF), size: 28),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sessions de formation',
                    style: TextStyle(
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Retrouvez ici toutes les sessions de formation disponibles et vos inscriptions.',
                    style: TextStyle(color: _textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildStudentTabs(),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final isMySessions = controller.studentTabIndex.value == 1;
              final rows = isMySessions
                  ? controller.studentMySessions
                  : controller.studentAvailableSessions;

              return RefreshIndicator(
                onRefresh: () => controller.refreshSessionsFromServer(),
                child: rows.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          Container(
                            height: 180,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Text(
                              isMySessions
                                  ? 'Aucune session inscrite'
                                  : 'Aucune session disponible',
                              style: const TextStyle(color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, index) {
                          final session = rows[index];
                          return _buildStudentSessionCard(
                            session,
                            isMySession: isMySessions,
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTabs() {
    return Obx(() {
      final selectedTab = controller.studentTabIndex.value;

      return Row(
        children: [
          Expanded(
            child: _studentTabButton(
              label: 'Sessions disponibles',
              selected: selectedTab == 0,
              onTap: () => controller.studentTabIndex.value = 0,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _studentTabButton(
              label: 'Mes sessions',
              selected: selectedTab == 1,
              onTap: () => controller.studentTabIndex.value = 1,
            ),
          ),
        ],
      );
    });
  }

  Widget _studentTabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: const Color(0xFF111827),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSessionCard(
    TrainingSession session, {
    required bool isMySession,
  }) {
    final participantText =
        '${session.participants.length} / ${session.maxParticipants} participants';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.courseLabel,
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B6BFF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.type.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                _formatStudentDate(session.startDate),
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const Spacer(),
              const Icon(
                Icons.access_time,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                _formatStudentTimeRange(session.startDate, session.endDate),
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 14,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                participantText,
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ],
          ),
          if (isMySession &&
              (session.meetingLink?.trim().isNotEmpty ?? false)) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: Color(0xFF0B6BFF),
                ),
                SizedBox(width: 6),
                Text(
                  'Lien de la réunion',
                  style: TextStyle(
                    color: Color(0xFF0B6BFF),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: controller.isSaving.value
                    ? null
                    : () {
                        if (isMySession) {
                          controller.leaveSession(session);
                          return;
                        }
                        controller.enrollInSession(session);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isMySession ? const Color(0xFFEF4444) : _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(isMySession ? 'Se désinscrire' : 'S\'inscrire'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatStudentDate(DateTime? value) {
    if (value == null) return '-';

    const weekdays = <String>[
      'lundi',
      'mardi',
      'mercredi',
      'jeudi',
      'vendredi',
      'samedi',
      'dimanche',
    ];
    const months = <String>[
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    final weekday = weekdays[value.weekday - 1];
    final month = months[value.month - 1];

    return '$weekday ${value.day} $month ${value.year}';
  }

  String _formatStudentTimeRange(DateTime? start, DateTime? end) {
    String hhmm(DateTime? value) {
      if (value == null) return '--:--';
      final h = value.hour.toString().padLeft(2, '0');
      final m = value.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return '${hhmm(start)} - ${hhmm(end)}';
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.groups_2_outlined, color: _primary, size: 32),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mes Sessions',
                  style: TextStyle(
                    height: 1.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Planifiez et gérez vos sessions de formation',
                  style: TextStyle(
                    color: _textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () => _openSessionDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('+ Nouvelle Session'),
          ),
        ),
      ],
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final rows = controller.filteredSessions;
        if (rows.isEmpty) {
          return const Center(
            child: Text(
              'Aucune session',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          );
        }

        return Column(
          children: [
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border)),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 2, child: _HeaderCell('Titre')),
                  Expanded(flex: 2, child: _HeaderCell('Cours')),
                  Expanded(flex: 2, child: _HeaderCell('Type')),
                  Expanded(flex: 3, child: _HeaderCell('Date de début')),
                  Expanded(flex: 2, child: _HeaderCell('Statut')),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _HeaderCell('Participants'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: rows.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: _border,
                ),
                itemBuilder: (_, index) {
                  final session = rows[index];
                  return InkWell(
                    onTap: () =>
                        _openSessionDialog(Get.context!, session: session),
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              session.title,
                              style: const TextStyle(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              session.courseLabel,
                              style: const TextStyle(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _typeText(session.type),
                              style: const TextStyle(),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              _formatDateTime(session.startDate),
                              style: const TextStyle(),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              _statusText(session.status),
                              style: const TextStyle(
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '${session.participants.length} / ${session.maxParticipants}',
                                style: const TextStyle(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y à $h:$min';
  }

  Future<void> _openSessionDialog(BuildContext context,
      {TrainingSession? session}) async {
    await controller.fetchCourses();

    final titleCtrl = TextEditingController(text: session?.title ?? '');
    final maxCtrl =
        TextEditingController(text: '${session?.maxParticipants ?? 10}');
    final linkCtrl = TextEditingController(text: session?.meetingLink ?? '');
    final notesCtrl = TextEditingController(text: session?.notes ?? '');

    final Rx<SessionType> selectedType =
        (session?.type ?? SessionType.online).obs;
    final Rxn<DateTime> startDate = Rxn<DateTime>(session?.startDate);
    final Rxn<DateTime> endDate = Rxn<DateTime>(session?.endDate);
    final RxnInt selectedCourseId = RxnInt(session?.courseAssociated);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 520,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Obx(() {
                final showMeeting = selectedType.value == SessionType.online ||
                    selectedType.value == SessionType.hybrid;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          session == null
                              ? 'Nouvelle Session de Formation'
                              : 'Modifier la Session',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close,
                              size: 18, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Planifiez une nouvelle session pour vos étudiants.',
                      style: TextStyle(
                        color: _textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Titre de la session'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: _dialogInputDecoration('Session Q&A...'),
                    ),
                    const SizedBox(height: 10),
                    const Text('Cours associé'),
                    const SizedBox(height: 6),
                    _courseDropdown(selectedCourseId),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Type'),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<SessionType>(
                                value: selectedType.value,
                                items: SessionType.values
                                    .map((item) => DropdownMenuItem(
                                          value: item,
                                          child: Text(item.label),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) selectedType.value = value;
                                },
                                decoration: _dialogInputDecoration(null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Max Participants'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: maxCtrl,
                                keyboardType: TextInputType.number,
                                decoration: _dialogInputDecoration('10'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Début'),
                              const SizedBox(height: 6),
                              _dateTimeField(
                                value: startDate.value,
                                onPick: (value) => startDate.value = value,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Fin'),
                              const SizedBox(height: 6),
                              _dateTimeField(
                                value: endDate.value,
                                onPick: (value) => endDate.value = value,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (showMeeting) ...[
                      const SizedBox(height: 10),
                      const Text('Lien de réunion (si en ligne)'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: linkCtrl,
                        decoration:
                            _dialogInputDecoration('https://zoom.us/...'),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text('Notes'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      minLines: 3,
                      maxLines: 4,
                      decoration: _dialogInputDecoration(
                          'Notes pour les participants...'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Obx(() {
                        return ElevatedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () async {
                                  final title = titleCtrl.text.trim();
                                  if (title.isEmpty) {
                                    Get.snackbar(
                                      'Erreur',
                                      'Le titre est obligatoire',
                                    );
                                    return;
                                  }

                                  final maxParticipants =
                                      int.tryParse(maxCtrl.text.trim()) ?? 10;

                                  final selectedCourse = selectedCourseId.value;
                                  final courseLabel = _courseLabelById(
                                    selectedCourse,
                                    controller.courses,
                                  );

                                  final payload = TrainingSession(
                                    id: session?.id ?? 0,
                                    documentId: session?.documentId ?? '',
                                    title: title,
                                    courseAssociated: selectedCourse,
                                    courseLabel: courseLabel,
                                    type: selectedType.value,
                                    maxParticipants: maxParticipants,
                                    startDate: startDate.value,
                                    endDate: endDate.value,
                                    meetingLink: linkCtrl.text.trim().isEmpty
                                        ? null
                                        : linkCtrl.text.trim(),
                                    notes: notesCtrl.text.trim().isEmpty
                                        ? null
                                        : notesCtrl.text.trim(),
                                    status: session?.status ??
                                        SessionStatus.planned,
                                    participants:
                                        session?.participants ?? const [],
                                    createdAt: session?.createdAt,
                                  );

                                  if (session == null) {
                                    await controller.addSession(payload);
                                  } else {
                                    await controller.editSession(
                                      session.id,
                                      payload,
                                    );
                                  }

                                  if (!controller.isSaving.value) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            session == null
                                ? 'Planifier la session'
                                : 'Enregistrer les modifications',
                          ),
                        );
                      }),
                    ),
                  ],
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _courseDropdown(RxnInt selectedCourseId) {
    return Obx(() {
      final items = <DropdownMenuItem<int?>>[
        const DropdownMenuItem<int?>(
          value: null,
          child: Text('Non spécifié'),
        ),
        ...controller.courses.map((course) {
          return DropdownMenuItem<int?>(
            value: course.id,
            child: Text(course.title),
          );
        }),
      ];

      return DropdownButtonFormField<int?>(
        value: selectedCourseId.value,
        items: items,
        onChanged: (value) => selectedCourseId.value = value,
        decoration: _dialogInputDecoration('Sélectionner un cours'),
      );
    });
  }

  Widget _dateTimeField({
    required DateTime? value,
    required ValueChanged<DateTime?> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? now;
        final date = await showDatePicker(
          context: Get.context!,
          initialDate: initial,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 5),
        );
        if (date == null) return;

        final time = await showTimePicker(
          context: Get.context!,
          initialTime: TimeOfDay.fromDateTime(initial),
        );
        if (time == null) return;

        onPick(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      },
      child: InputDecorator(
        decoration: _dialogInputDecoration('jj / mm / aaaa --:--').copyWith(
          suffixIcon: const Icon(Icons.calendar_today,
              size: 16, color: Color(0xFF111827)),
        ),
        child: Text(
          value == null ? 'jj / mm / aaaa --:--' : _formatDateTime(value),
          style: TextStyle(
            color: value == null ? const Color(0xFF9CA3AF) : Colors.black87,
          ),
        ),
      ),
    );
  }

  InputDecoration _dialogInputDecoration(String? hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
    );
  }

  String _courseLabelById(int? id, List<Course> courses) {
    if (id == null) return 'Non spécifié';
    final item = courses.firstWhereOrNull((course) => course.id == id);
    return item?.title ?? 'Non spécifié';
  }

  String _typeText(SessionType type) {
    switch (type) {
      case SessionType.online:
        return 'En_ligne';
      case SessionType.presential:
        return 'Présentiel';
      case SessionType.hybrid:
        return 'Hybride';
    }
  }

  String _statusText(SessionStatus status) {
    if (status == SessionStatus.planned) return '—';
    if (status == SessionStatus.inProgress) return 'En cours';
    if (status == SessionStatus.completed) return 'Terminée';
    return 'Annulée';
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;

  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}
