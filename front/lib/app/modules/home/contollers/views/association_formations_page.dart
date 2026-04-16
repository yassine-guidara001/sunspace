import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/training_session_model.dart';
import 'package:flutter_getx_app/app/data/services/training_sessions_api.dart';
import 'package:get/get.dart';

class AssociationFormationsPage extends StatefulWidget {
  const AssociationFormationsPage({super.key});

  @override
  State<AssociationFormationsPage> createState() =>
      _AssociationFormationsPageState();
}

class _AssociationSessionMeta {
  final String recurrence;
  final DateTime? recurrenceEnd;
  final String displayNotes;

  const _AssociationSessionMeta({
    required this.recurrence,
    required this.recurrenceEnd,
    required this.displayNotes,
  });
}

class _AssociationFormationsPageState extends State<AssociationFormationsPage> {
  late final TrainingSessionsApi _sessionsApi;
  late final AuthService _authService;

  List<TrainingSession> _sessions = <TrainingSession>[];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _sessionsApi = TrainingSessionsApi();
    _authService = Get.find<AuthService>();
    _loadAssociationSessions();
  }

  Future<void> _loadAssociationSessions({bool withLoader = true}) async {
    if (withLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final userId = _authService.currentUserId;
      if (userId == null || userId <= 0) {
        if (!mounted) return;
        _showSnack('Erreur: Utilisateur non connecté');
        return;
      }

      final sessions = await _sessionsApi.getSessionsByInstructorId(userId);
      if (!mounted) return;

      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('Erreur: ${_cleanError(e)}');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  List<TrainingSession> get _filteredSessions {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _sessions;

    return _sessions.where((session) {
      final meta = _decodeAssociationNotes(session.notes);
      final content = <String>[
        session.title,
        session.courseLabel,
        meta.displayNotes,
        meta.recurrence,
        session.type.label,
        session.status.label,
      ].join(' ').toLowerCase();
      return content.contains(q);
    }).toList();
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Organiser des Formations',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 32,
                height: 1.05,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Créez des parcours d\'apprentissage personnalisés pour les membres de votre association.',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(
          height: 40,
          child: ElevatedButton.icon(
            onPressed: () => _openSessionDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau Parcours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B6BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: const InputDecoration(
          hintText: 'Rechercher une formation...',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          prefixIcon: Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredSessions.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSessionsList();
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2ECFA),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 26,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Aucun parcours en cours',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  height: 1,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Votre liste de formations est vide. Commencez par planifier une nouvelle session pour vos membres.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: () => _openSessionDialog(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Planifier mon premier parcours'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            constraints.maxWidth >= 760 ? 560.0 : constraints.maxWidth;

        return SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 24,
              runSpacing: 20,
              children: _filteredSessions
                  .map((session) => SizedBox(
                        width: cardWidth,
                        child: _buildSessionCard(session),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSessionCard(TrainingSession session) {
    final typeColor = _typeColor(session.type);
    final meta = _decodeAssociationNotes(session.notes);
    final participantText =
        '${session.participants.length} / ${session.maxParticipants} membres';

    return Container(
      height: 132,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 190,
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FF),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
            ),
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCD4FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  size: 24,
                  color: Color(0xFF0B6BFF),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          session.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEDD5),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFCD34D)),
                        ),
                        child: Text(
                          _statusLabel(session.status),
                          style: const TextStyle(
                            color: Color(0xFFF97316),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _confirmDeleteSession(session),
                        borderRadius: BorderRadius.circular(12),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(Icons.delete_outline,
                              size: 15, color: Color(0xFF7C7C7C)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(
                        session.type.label.toUpperCase(),
                        typeColor.withOpacity(0.12),
                        typeColor,
                      ),
                      if (meta.recurrence != 'Aucune')
                        _chip('RÉCURRENT', const Color(0xFFD1FAE5),
                            const Color(0xFF22C55E)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: Color(0xFF6B7280)),
                      const SizedBox(width: 5),
                      Text(
                        _formatShortDate(session.startDate),
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatRecurrenceDisplay(meta),
                    style: const TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      const Icon(Icons.people_outline,
                          size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 5),
                      Text(
                        participantText,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.article_outlined,
                          size: 12, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 5),
                      const Text(
                        '1 session',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color backgroundColor, Color foregroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }

  Color _typeColor(SessionType type) {
    switch (type) {
      case SessionType.online:
        return const Color(0xFF7C3AED);
      case SessionType.presential:
        return const Color(0xFF16A34A);
      case SessionType.hybrid:
        return const Color(0xFF2563EB);
    }
  }

  Color _statusColor(SessionStatus status) {
    switch (status) {
      case SessionStatus.planned:
        return const Color(0xFFF97316);
      case SessionStatus.inProgress:
        return const Color(0xFF16A34A);
      case SessionStatus.completed:
        return const Color(0xFF6B7280);
      case SessionStatus.cancelled:
        return const Color(0xFFDC2626);
    }
  }

  String _statusLabel(SessionStatus status) {
    switch (status) {
      case SessionStatus.planned:
        return 'PLANIFIÉE';
      case SessionStatus.inProgress:
        return 'EN COURS';
      case SessionStatus.completed:
        return 'TERMINÉE';
      case SessionStatus.cancelled:
        return 'ANNULÉE';
    }
  }

  String _formatShortDate(DateTime? value) {
    if (value == null) return '-';
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
      'déc.'
    ];

    const weekdays = <int, String>{
      DateTime.monday: 'lun.',
      DateTime.tuesday: 'mar.',
      DateTime.wednesday: 'mer.',
      DateTime.thursday: 'jeu.',
      DateTime.friday: 'ven.',
      DateTime.saturday: 'sam.',
      DateTime.sunday: 'dim.',
    };

    final prefix = weekdays[value.weekday] ?? '';
    return '$prefix ${value.day} ${months[value.month - 1]} ${value.year}'
        .trim();
  }

  String _cleanError(Object error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _dialogInputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF0B6BFF)),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _composeAssociationNotes({
    required String recurrence,
    DateTime? recurrenceEnd,
    required String notes,
  }) {
    final metaParts = <String>[
      '__association_meta__',
      'recurrence=$recurrence',
      if (recurrenceEnd != null)
        'recurrenceEnd=${recurrenceEnd.toIso8601String()}',
    ];

    final body = notes.trim();
    return body.isEmpty
        ? metaParts.join(';')
        : '${metaParts.join(';')}\n\n$body';
  }

  _AssociationSessionMeta _decodeAssociationNotes(String? rawNotes) {
    final notes = (rawNotes ?? '').trim();
    if (notes.isEmpty) {
      return const _AssociationSessionMeta(
        recurrence: 'Aucune',
        recurrenceEnd: null,
        displayNotes: '',
      );
    }

    final lines = notes.split('\n');
    final firstLine = lines.first.trim();
    if (!firstLine.startsWith('__association_meta__')) {
      return _AssociationSessionMeta(
        recurrence: 'Aucune',
        recurrenceEnd: null,
        displayNotes: notes,
      );
    }

    String recurrence = 'Aucune';
    DateTime? recurrenceEnd;
    for (final bit in firstLine.split(';').skip(1)) {
      final pair = bit.split('=');
      if (pair.length < 2) continue;
      final key = pair.first.trim();
      final value = pair.sublist(1).join('=').trim();
      if (key == 'recurrence') {
        recurrence = value.isEmpty ? 'Aucune' : value;
      } else if (key == 'recurrenceEnd') {
        recurrenceEnd = DateTime.tryParse(value)?.toLocal();
      }
    }

    final displayNotes =
        lines.length > 1 ? lines.skip(1).join('\n').trim() : '';

    return _AssociationSessionMeta(
      recurrence: recurrence,
      recurrenceEnd: recurrenceEnd,
      displayNotes: displayNotes,
    );
  }

  String _formatRecurrenceDisplay(_AssociationSessionMeta meta) {
    if (meta.recurrence == 'Aucune') {
      return meta.displayNotes.isEmpty ? 'Session unique' : meta.displayNotes;
    }

    final recurrence = meta.recurrence.toLowerCase();
    return 'Répétition $recurrence';
  }

  Future<void> _openSessionDialog(BuildContext context,
      {TrainingSession? session}) async {
    final titleCtrl = TextEditingController(text: session?.title ?? '');
    final maxCtrl = TextEditingController(
      text: '${session?.maxParticipants ?? 20}',
    );
    final linkCtrl = TextEditingController(text: session?.meetingLink ?? '');
    final notesMeta = _decodeAssociationNotes(session?.notes);
    final notesCtrl = TextEditingController(text: notesMeta.displayNotes);

    final Rx<SessionType> selectedType =
        (session?.type ?? SessionType.online).obs;
    final Rxn<DateTime> startDate = Rxn<DateTime>(session?.startDate);
    final Rxn<DateTime> endDate = Rxn<DateTime>(session?.endDate);

    final recurrenceOptions = <String>[
      'Aucune',
      'Quotidienne',
      'Hebdomadaire',
      'Mensuelle',
    ];
    final RxString selectedRecurrence = notesMeta.recurrence.obs;
    final Rxn<DateTime> recurrenceEndDate =
        Rxn<DateTime>(notesMeta.recurrenceEnd);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final screenWidth = MediaQuery.of(dialogContext).size.width;
        final dialogWidth = screenWidth < 580 ? screenWidth - 24 : 500.0;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
          child: Container(
            width: dialogWidth,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(dialogContext).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Nouvelle Session / Parcours',
                              style: TextStyle(
                                color: Color(0xFF111827),
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Planifiez une nouvelle session de formation pour vos membres.',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close, size: 18),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Titre de la session',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _dialogField(titleCtrl, 'Ex: Masterclass Q&A React'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Type',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  _dialogDropdown<SessionType>(
                                    value: selectedType.value,
                                    items: SessionType.values,
                                    labelBuilder: (item) => item.label,
                                    onChanged: (value) {
                                      if (value != null) {
                                        selectedType.value = value;
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Max Participants',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  _dialogField(maxCtrl, '20',
                                      keyboardType: TextInputType.number),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Début',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => _dateTimePickerField(
                                      context: dialogContext,
                                      value: startDate.value,
                                      hint: 'jj / mm / aaaa --:--',
                                      onPick: (value) =>
                                          startDate.value = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fin',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => _dateTimePickerField(
                                      context: dialogContext,
                                      value: endDate.value,
                                      hint: 'jj / mm / aaaa --:--',
                                      onPick: (value) => endDate.value = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Récurrence',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => _dialogDropdown<String>(
                                      value: selectedRecurrence.value,
                                      items: recurrenceOptions,
                                      labelBuilder: (item) => item,
                                      onChanged: (value) {
                                        if (value != null) {
                                          selectedRecurrence.value = value;
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Fin de récurrence',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Obx(
                                    () => _dateTimePickerField(
                                      context: dialogContext,
                                      value: recurrenceEndDate.value,
                                      hint: 'jj / mm / aaaa',
                                      onPick: (value) =>
                                          recurrenceEndDate.value = value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Lien de réunion (si en ligne)',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        _dialogField(
                          linkCtrl,
                          'https://zoom.us/...',
                          prefix: const Icon(Icons.link,
                              size: 18, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 12),
                        const Text('Notes & Objectifs',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: notesCtrl,
                          minLines: 4,
                          maxLines: 6,
                          decoration: _dialogInputDecoration(
                              'Notes pour les participants...'),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 38,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final title = titleCtrl.text.trim();
                            if (title.isEmpty ||
                                startDate.value == null ||
                                endDate.value == null) {
                              Get.snackbar('Erreur',
                                  'Veuillez remplir les champs obligatoires');
                              return;
                            }

                            final payload = TrainingSession(
                              id: session?.id ?? 0,
                              documentId: session?.documentId ?? '',
                              title: title,
                              courseAssociated: session?.courseAssociated,
                              courseLabel:
                                  session?.courseLabel ?? 'Non spécifié',
                              type: selectedType.value,
                              maxParticipants:
                                  int.tryParse(maxCtrl.text.trim()) ?? 20,
                              startDate: startDate.value,
                              endDate: endDate.value,
                              meetingLink: linkCtrl.text.trim().isEmpty
                                  ? null
                                  : linkCtrl.text.trim(),
                              notes: _composeAssociationNotes(
                                recurrence: selectedRecurrence.value,
                                recurrenceEnd: recurrenceEndDate.value,
                                notes: notesCtrl.text,
                              ),
                              status: session?.status ?? SessionStatus.planned,
                              participants: session?.participants ??
                                  const <Participant>[],
                              createdAt: session?.createdAt,
                            );

                            try {
                              if (session == null) {
                                await _sessionsApi.createSession(payload);
                              } else {
                                await _sessionsApi.updateSession(
                                    session.id, payload);
                              }

                              if (!mounted) return;
                              Navigator.of(dialogContext).pop();
                              await _loadAssociationSessions();
                              _showSnack('Session enregistrée avec succès');
                            } catch (e) {
                              _showSnack('Erreur: ${_cleanError(e)}');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B6BFF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.calendar_month, size: 16),
                          label: Text(session == null
                              ? 'Planifier la session'
                              : 'Enregistrer la session'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    titleCtrl.dispose();
    maxCtrl.dispose();
    linkCtrl.dispose();
    notesCtrl.dispose();
  }

  Future<void> _confirmDeleteSession(TrainingSession session) async {
    final shouldDelete = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Supprimer la session'),
        content: Text(
          'Voulez-vous supprimer "${session.title}" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await _sessionsApi.deleteSession(
        id: session.id,
        documentId: session.documentId,
      );
      await _loadAssociationSessions();
      _showSnack('Session supprimée');
    } catch (e) {
      _showSnack('Erreur: ${_cleanError(e)}');
    }
  }

  Widget _dialogField(
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
    Widget? prefix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _dialogInputDecoration(hint).copyWith(prefixIcon: prefix),
    );
  }

  Widget _dialogDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T item) labelBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      items: items
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(labelBuilder(item)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: _dialogInputDecoration(null),
    );
  }

  Widget _dateTimePickerField({
    required BuildContext context,
    required DateTime? value,
    required String hint,
    required ValueChanged<DateTime?> onPick,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = value ?? now;

        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 5),
        );
        if (date == null) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(initial),
        );

        final selectedTime = time ??
            (value != null
                ? TimeOfDay.fromDateTime(value)
                : const TimeOfDay(hour: 9, minute: 0));

        onPick(DateTime(date.year, date.month, date.day, selectedTime.hour,
            selectedTime.minute));
      },
      child: InputDecorator(
        decoration: _dialogInputDecoration(hint).copyWith(
          suffixIcon: const Icon(Icons.calendar_today,
              size: 16, color: Color(0xFF111827)),
        ),
        child: Text(
          value == null ? hint : _formatDateTime(value),
          style: TextStyle(
            color: value == null ? const Color(0xFF9CA3AF) : Colors.black87,
          ),
        ),
      ),
    );
  }
}
