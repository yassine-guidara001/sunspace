import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/services/assignments_api.dart';
import 'package:get/get.dart';

class StudentCourseAccessPage extends StatefulWidget {
  final Course course;
  final int initialTab;

  const StudentCourseAccessPage({
    super.key,
    required this.course,
    this.initialTab = 0,
  });

  @override
  State<StudentCourseAccessPage> createState() =>
      _StudentCourseAccessPageState();
}

class _StudentCourseAccessPageState extends State<StudentCourseAccessPage> {
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF1D6FF2);

  final AssignmentsApi _assignmentsApi = AssignmentsApi();
  final CoursesApi _coursesApi = CoursesApi();
  final TextEditingController _searchCtrl = TextEditingController();

  late int _activeTab;
  bool _isLoadingAssignments = false;
  String _assignmentsError = '';
  List<Assignment> _todoAssignments = <Assignment>[];
  Map<int, List<Map<String, dynamic>>> _submissionsByAssignment =
      const <int, List<Map<String, dynamic>>>{};
  Course? _loadedCourse;

  Course get _currentCourse => _loadedCourse ?? widget.course;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);

    // Charger les données du cours au démarrage
    _loadCourseData();

    if (_activeTab == 1) {
      _loadTodoAssignments();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCourseData() async {
    try {
      // Charger les détails complets pour disposer des relations utiles.
      if (widget.course.id > 0) {
        final courseDetails = await _coursesApi.getCourseById(widget.course.id);
        if (!mounted) return;
        setState(() {
          _loadedCourse = courseDetails;
        });

        if (_activeTab == 1 && !_isLoadingAssignments) {
          await _loadTodoAssignments();
        }
      }
    } catch (e) {
      // Conserver les données minimales du cours en cas d'erreur.
    }
  }

  Future<void> _loadTodoAssignments() async {
    setState(() {
      _isLoadingAssignments = true;
      _assignmentsError = '';
    });

    try {
      final course = _currentCourse;
      final courseDocumentId = course.documentId.trim();

      if (course.id <= 0 && courseDocumentId.isEmpty) {
        throw Exception('Cours invalide: identifiant manquant');
      }

      // 1) Requete stricte des devoirs du cours courant.
      final result = await _assignmentsApi.getAssignmentsForCourse(
        courseId: course.id > 0 ? course.id : null,
        courseDocumentId: courseDocumentId.isNotEmpty ? courseDocumentId : null,
        onlyTodo: false,
      );

      result.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // 2) Requete submissions agrégée pour éviter le N+1.
      final assignmentIds = result
          .where((assignment) => assignment.id > 0)
          .map((e) => e.id)
          .toSet();

      final groupedSubmissions = assignmentIds.isEmpty
          ? const <int, List<Map<String, dynamic>>>{}
          : await _assignmentsApi.getStudentSubmissionsByAssignment(
              assignmentIds: assignmentIds,
            );

      if (!mounted) return;
      setState(() {
        _todoAssignments = result;
        _submissionsByAssignment = groupedSubmissions;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _assignmentsError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAssignments = false;
        });
      }
    }
  }

  void _switchTab(int tab) {
    if (_activeTab == tab) return;

    setState(() {
      _activeTab = tab;
    });

    if (tab == 1 && _todoAssignments.isEmpty && !_isLoadingAssignments) {
      _loadTodoAssignments();
    }
  }

  List<Assignment> get _visibleAssignments {
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isEmpty) return _todoAssignments;

    return _todoAssignments.where((assignment) {
      return assignment.title.toLowerCase().contains(query) ||
          assignment.instructions.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: _border),
                                    right: BorderSide(color: _border),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildTabs(),
                                    Expanded(
                                      child: _activeTab == 0
                                          ? _buildLessonsPlaceholder()
                                          : _buildAssignmentsPanel(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              width: 210,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: _border),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 3,
                                          backgroundColor: Color(0xFF2563EB),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'PROGRESSION',
                                          style: TextStyle(
                                            color: Color(0xFF111827),
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF475569), size: 20),
          ),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          const Text(
            'intern',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new,
                size: 14, color: Color(0xFF6B7280)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentCourse.title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SESSION ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Instructeur',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE5F0FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFD7FF)),
            ),
            child: Text(
              _currentCourse.level,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _switchTab(0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    right: const BorderSide(color: _border),
                    bottom: BorderSide(
                      color: _activeTab == 0
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 14, color: Color(0xFF111827)),
                      SizedBox(width: 6),
                      Text(
                        'Leçons',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _switchTab(1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _activeTab == 1
                          ? const Color(0xFF2563EB)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_outlined,
                          size: 14, color: Color(0xFF111827)),
                      const SizedBox(width: 6),
                      const Text(
                        'Devoirs',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${_todoAssignments.length}',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonsPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 56, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'Prêt à apprendre ?',
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Sélectionnez votre première leçon dans le menu\nlatéral pour débuter ce cours.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsPanel() {
    if (_isLoadingAssignments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_assignmentsError.trim().isNotEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 8),
            Text(
              _assignmentsError,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadTodoAssignments,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final rows = _visibleAssignments;

    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'Aucun devoir pour ce cours',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: _border)),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Rechercher un devoir...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final assignment = rows[index];
              return _buildAssignmentCard(assignment);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final hasSubmission =
        (_submissionsByAssignment[assignment.id]?.isNotEmpty ?? false);
    final now = DateTime.now();
    final isExpired = assignment.dueDate.isBefore(now) &&
        !assignment.allowLateSubmission &&
        !hasSubmission;
    final actionLabel = hasSubmission ? 'Re-soumettre' : 'Soumettre';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.assignment_outlined,
                      color: Color(0xFF1D6FF2), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w700,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A rendre le ${_formatDate(assignment.dueDate)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${assignment.maxPoints} Points Max',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: _border,
          ),
          SizedBox(
            width: 160,
            height: 44,
            child: ElevatedButton(
              onPressed: isExpired
                  ? null
                  : () {
                      _showSubmitDialog(assignment);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isExpired ? const Color(0xFFCBD5E1) : _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_outlined, size: 16),
                  SizedBox(width: 8),
                  Text(
                    actionLabel,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSubmitDialog(Assignment assignment) async {
    final noteCtrl = TextEditingController();
    Map<String, dynamic>? selectedFile;
    String? selectedFileName;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: const Color(0x660F172A),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final view = MediaQuery.of(context);
            final maxDialogWidth = view.size.width > 860 ? 560.0 : 680.0;

            return Dialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              child: Padding(
                padding: EdgeInsets.only(bottom: view.viewInsets.bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: maxDialogWidth,
                    maxHeight: view.size.height * 0.9,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Material(
                      color: Colors.white,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(24, 18, 16, 20),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4F8FF5), Color(0xFF92B6EA)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        assignment.title.trim().isEmpty
                                            ? 'TP'
                                            : assignment.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 30,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Finalisez votre travail et envoyez-le ici.',
                                        style: TextStyle(
                                          color: Color(0xFFD9E8FF),
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  splashRadius: 18,
                                  icon: const Icon(
                                    Icons.close,
                                    color: Color(0xFF1E3A8A),
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 18, 24, 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.description_outlined,
                                          size: 16, color: Color(0xFF3B82F6)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Contenu ou observations',
                                        style: TextStyle(
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: noteCtrl,
                                    minLines: 4,
                                    maxLines: 6,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Décrivez votre travail ou ajoutez un commentaire...',
                                      hintStyle: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      filled: true,
                                      fillColor: const Color(0xFFF8FAFC),
                                      contentPadding: const EdgeInsets.all(12),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: _border),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            const BorderSide(color: _border),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Row(
                                    children: [
                                      Icon(Icons.upload_file_outlined,
                                          size: 16, color: Color(0xFF3B82F6)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Fichier joint (PDF, ZIP, etc.)',
                                        style: TextStyle(
                                          color: Color(0xFF111827),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () async {
                                      final picked =
                                          await _pickSubmissionAttachment();
                                      if (picked == null) return;

                                      setDialogState(() {
                                        selectedFile = picked;
                                        selectedFileName =
                                            picked['name']?.toString();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(14),
                                    child: CustomPaint(
                                      painter: _DashedRRectPainter(
                                        color: const Color(0xFF8AB6FF),
                                        radius: 14,
                                        dashWidth: 7,
                                        dashSpace: 5,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7FAFF),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAF2FF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Icon(
                                                Icons.upload,
                                                color: Color(0xFF1D6FF2),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              selectedFileName == null
                                                  ? 'Cliquez ou glissez votre fichier'
                                                  : selectedFileName!,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: selectedFileName == null
                                                    ? const Color(0xFF0F172A)
                                                    : const Color(0xFF1D4ED8),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Taille max 10MB · Formats autorisés: .pdf, .zip, .docx',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3F6FB),
                              border: Border(
                                top: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Spacer(),
                                TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  child: const Text(
                                    'Annuler',
                                    style: TextStyle(
                                      color: Color(0xFF475569),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 42,
                                  child: ElevatedButton.icon(
                                    onPressed: isSubmitting
                                        ? null
                                        : () async {
                                            if (noteCtrl.text.trim().isEmpty &&
                                                selectedFile == null) {
                                              Get.snackbar(
                                                'Information',
                                                'Ajoutez un commentaire ou un fichier avant l\'envoi',
                                              );
                                              return;
                                            }

                                            setDialogState(() {
                                              isSubmitting = true;
                                            });

                                            try {
                                              if (selectedFile != null) {
                                                await _assignmentsApi
                                                    .uploadAttachment(
                                                        selectedFile!);
                                              }

                                              if (!mounted) return;
                                              Navigator.of(context).pop();
                                              Get.snackbar(
                                                'Succès',
                                                'Votre envoi a été pris en compte.',
                                              );
                                            } catch (e) {
                                              Get.snackbar(
                                                'Erreur',
                                                e.toString().replaceFirst(
                                                    'Exception: ', ''),
                                              );
                                            } finally {
                                              if (context.mounted) {
                                                setDialogState(() {
                                                  isSubmitting = false;
                                                });
                                              }
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D6FF2),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    icon: isSubmitting
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.send, size: 16),
                                    label: const Text(
                                      'Finaliser l\'envoi',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    noteCtrl.dispose();
  }

  Future<Map<String, dynamic>?> _pickSubmissionAttachment() async {
    const allowedExtensions = <String>['pdf', 'zip', 'docx'];

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: allowedExtensions,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final picked = result.files.single;
      final rawBytes = picked.bytes;
      final streamBytes = (rawBytes == null || rawBytes.isEmpty)
          ? await _readBytesFromStream(picked.readStream)
          : null;

      final resolvedBytes =
          (rawBytes != null && rawBytes.isNotEmpty) ? rawBytes : streamBytes;

      final path = _safePath(picked);
      final hasBytes = resolvedBytes != null && resolvedBytes.isNotEmpty;
      final hasPath = path != null && path.isNotEmpty;

      if (!hasBytes && !hasPath) {
        Get.snackbar('Erreur', 'Impossible de lire le fichier sélectionné');
        return null;
      }

      return {
        'name': picked.name,
        if (hasBytes) 'bytes': resolvedBytes,
        if (hasPath) 'path': path,
      };
    } catch (e) {
      Get.snackbar('Erreur', 'Sélection du fichier échouée');
      return null;
    }
  }

  Future<Uint8List?> _readBytesFromStream(Stream<List<int>>? stream) async {
    if (stream == null) return null;

    try {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(chunk);
      }

      if (chunks.isEmpty) return null;
      return Uint8List.fromList(chunks);
    } catch (_) {
      return null;
    }
  }

  String? _safePath(PlatformFile file) {
    try {
      final path = file.path?.trim();
      if (path == null || path.isEmpty) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }
}

class _DashedRRectPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth;
  final double dashSpace;

  const _DashedRRectPainter({
    required this.color,
    required this.radius,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final nextDistance = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.radius != radius ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace;
  }
}
