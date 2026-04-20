import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:flutter_getx_app/app/data/services/courses_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/services/assignments_api.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final StorageService _storageService = Get.find<StorageService>();
  final HomeController _homeController = Get.find<HomeController>();
  final TextEditingController _searchCtrl = TextEditingController();

  late int _activeTab;
  bool _isLoadingAssignments = false;
  String _assignmentsError = '';
  List<Assignment> _todoAssignments = <Assignment>[];
  Map<int, List<Map<String, dynamic>>> _submissionsByAssignment =
      const <int, List<Map<String, dynamic>>>{};
  Course? _loadedCourse;
  List<String> _lessons = const <String>[];
  Set<int> _completedLessonIndexes = <int>{};

  Course get _currentCourse => _loadedCourse ?? widget.course;
  int get _completedLessonsCount => _completedLessonIndexes.length;
  int get _totalLessonsCount => _lessons.length;
  int get _progressPercent {
    if (_totalLessonsCount == 0) return 0;
    return ((_completedLessonsCount / _totalLessonsCount) * 100).round();
  }

  double get _progressValue {
    if (_totalLessonsCount == 0) return 0;
    return _completedLessonsCount / _totalLessonsCount;
  }

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab.clamp(0, 1);
    _prepareLessonsAndProgress(widget.course);

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
        await _prepareLessonsAndProgress(courseDetails);

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

  Future<void> _prepareLessonsAndProgress(Course course) async {
    final extractedLessons = _extractLessons(course);
    final restoredIndexes =
        _readProgressIndexes(course, extractedLessons.length);

    if (!mounted) return;
    setState(() {
      _lessons = extractedLessons;
      _completedLessonIndexes = restoredIndexes;
    });
  }

  List<String> _extractLessons(Course course) {
    final description = course.description.trim();

    if (description.isNotEmpty) {
      final lines = description
          .split(RegExp(r'[\r\n]+'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();

      final bulletPattern = RegExp(r'^([\-*•]|\d+[\.)-])\s+');
      final bulletLessons = lines
          .where((line) => bulletPattern.hasMatch(line))
          .map((line) => line.replaceFirst(bulletPattern, '').trim())
          .where((line) => line.isNotEmpty)
          .toList();

      if (bulletLessons.isNotEmpty) {
        return bulletLessons;
      }

      final sentenceLessons = description
          .split(RegExp(r'[.!?]+'))
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .take(8)
          .toList();

      if (sentenceLessons.isNotEmpty) {
        return sentenceLessons;
      }
    }

    final baseTitle = course.title.trim().isEmpty ? 'ce cours' : course.title;
    return <String>[
      'Découvrir les objectifs de $baseTitle',
      'Étudier les notions essentielles',
      'Valider les acquis avec un exercice',
    ];
  }

  Set<int> _readProgressIndexes(Course course, int lessonsLength) {
    if (lessonsLength <= 0) return <int>{};

    final raw = _storageService.read<dynamic>(_progressStorageKey(course));
    if (raw is! Map) return <int>{};

    final map = Map<String, dynamic>.from(raw as Map);
    final completedRaw = map['completed'];
    if (completedRaw is! List) return <int>{};

    return completedRaw
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .where((index) => index >= 0 && index < lessonsLength)
        .toSet();
  }

  Future<void> _toggleLessonCompletion(
      int lessonIndex, bool isCompleted) async {
    if (lessonIndex < 0 || lessonIndex >= _lessons.length) return;

    setState(() {
      if (isCompleted) {
        _completedLessonIndexes.add(lessonIndex);
      } else {
        _completedLessonIndexes.remove(lessonIndex);
      }
    });

    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    final sortedIndexes = _completedLessonIndexes.toList()..sort();
    await _storageService.write(
      _progressStorageKey(_currentCourse),
      <String, dynamic>{
        'completed': sortedIndexes,
        'updatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  String _progressStorageKey(Course course) {
    final dynamic userData = _storageService.getUserData() ??
        _storageService.read<dynamic>('user_data');
    var userId = 'anonymous';

    if (userData is Map) {
      final candidate =
          userData['id'] ?? userData['userId'] ?? userData['user_id'];
      if (candidate != null && candidate.toString().trim().isNotEmpty) {
        userId = candidate.toString().trim();
      }
    }

    final courseKey = course.id > 0
        ? 'id_${course.id}'
        : (course.documentId.trim().isNotEmpty
            ? 'doc_${course.documentId.trim()}'
            : 'title_${base64Url.encode(utf8.encode(course.title.trim().toLowerCase()))}');

    return 'student_course_progress:$userId:$courseKey';
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 920;

    return Scaffold(
      backgroundColor: _bg,
      body: Row(
        children: [
          if (!isCompact) const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isCompact),
                Expanded(
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: isCompact
                            ? Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: _border),
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
                              )
                            : Row(
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
                                    child: Padding(
                                      padding:
                                          EdgeInsets.fromLTRB(16, 18, 16, 12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 3,
                                                backgroundColor:
                                                    Color(0xFF2563EB),
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
                                          const SizedBox(height: 14),
                                          Text(
                                            '$_progressPercent%',
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontWeight: FontWeight.w800,
                                              fontSize: 22,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            child: LinearProgressIndicator(
                                              minHeight: 8,
                                              value: _progressValue,
                                              backgroundColor:
                                                  const Color(0xFFE2E8F0),
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                      Color>(
                                                Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '$_completedLessonsCount sur $_totalLessonsCount leçons terminées',
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                              fontWeight: FontWeight.w500,
                                              fontSize: 12,
                                            ),
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

  Widget _buildTopBar(BuildContext context, bool isCompact) {
    if (_homeController.currentUsername.value == 'Utilisateur' &&
        _homeController.currentEmail.value.trim().isEmpty) {
      Future.microtask(
          () => _homeController.refreshCurrentUserIdentity(force: false));
    }

    final displayName = _homeController.currentUsername.value.trim().isEmpty ||
            _homeController.currentUsername.value == 'Utilisateur'
        ? (_homeController.currentEmail.value.trim().isNotEmpty
            ? _homeController.currentEmail.value.trim()
            : 'Utilisateur')
        : _homeController.currentUsername.value.trim();

    final displayInitial = displayName.isNotEmpty
        ? displayName.substring(0, 1).toUpperCase()
        : 'U';

    return Container(
      height: isCompact ? 60 : 70,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              tooltip: 'Menu',
              onPressed: () => CustomSidebar.openDrawerMenu(context),
              icon: const Icon(Icons.menu, color: Color(0xFF475569)),
            ),
          ] else
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
            tooltip: 'Notifications',
            onPressed: () {
              _homeController.selectedMenu.value = -1;
              if (Get.currentRoute != Routes.NOTIFICATIONS) {
                Get.toNamed(Routes.NOTIFICATIONS);
              }
            },
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF475569), size: 20),
          ),
          CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE2E8F0),
            child: Text(
              displayInitial,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 8),
            Text(
              displayName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
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
    return Container(
      width: double.infinity,
      color: const Color(0xFFF4F7FB),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFE9EEF6),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFFB7C1D1),
                  size: 34,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Prêt à apprendre ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Sélectionnez votre première leçon dans le menu\nlatéral pour débuter ce cours.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
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
            const Icon(
              Icons.wifi_off_outlined,
              size: 42,
              color: Color(0xFF94A3B8),
            ),
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
              label: const Text('Reessayer'),
            ),
          ],
        ),
      );
    }

    final rows = _visibleAssignments;

    if (rows.isEmpty) {
      return _buildAssignmentsEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(18),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, index) {
        final assignment = rows[index];
        return _buildAssignmentCard(assignment);
      },
    );
  }

  Widget _buildAssignmentsEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 34,
            backgroundColor: Color(0xFFF1F5F9),
            child: Icon(
              Icons.menu_book_outlined,
              color: Color(0xFFCBD5E1),
              size: 30,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Prêt à apprendre ?',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Aucun devoir disponible pour ce cours pour le moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final submissions = _submissionsByAssignment[assignment.id] ?? const [];
    final latestSubmission = submissions.isNotEmpty ? submissions.first : null;
    final hasSubmission = latestSubmission != null;
    final now = DateTime.now();
    final isExpired = assignment.dueDate.isBefore(now) &&
        !assignment.allowLateSubmission &&
        !hasSubmission;
    final actionLabel = hasSubmission ? 'Re-soumettre' : 'Soumettre';
    final submissionStatus = _submissionStatusMeta(latestSubmission);
    final submittedAt = latestSubmission?['submittedAt']?.toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 16,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAssignmentInfo(assignment),
                    const SizedBox(height: 16),
                    if (hasSubmission)
                      _buildSubmittedStatusPanel(
                        statusTitle: submissionStatus.label,
                        statusColor: submissionStatus.color,
                        statusBg: submissionStatus.background,
                        submittedAtRaw: submittedAt,
                      )
                    else
                      _buildSubmissionActionButton(
                        assignment,
                        isExpired,
                        actionLabel,
                      ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _buildAssignmentInfo(assignment)),
                    Container(
                      width: 1,
                      height: 120,
                      margin: const EdgeInsets.symmetric(horizontal: 18),
                      color: _border,
                    ),
                    SizedBox(
                      width: 190,
                      child: hasSubmission
                          ? _buildSubmittedStatusPanel(
                              statusTitle: submissionStatus.label,
                              statusColor: submissionStatus.color,
                              statusBg: submissionStatus.background,
                              submittedAtRaw: submittedAt,
                            )
                          : _buildSubmissionActionButton(
                              assignment,
                              isExpired,
                              actionLabel,
                            ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildAssignmentInfo(Assignment assignment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF2FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF1D6FF2),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                assignment.title.trim().isEmpty
                    ? 'DEVOIR'
                    : assignment.title.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.watch_later_outlined,
              size: 14,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              'A rendre le ${_formatDate(assignment.dueDate)}',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (assignment.instructions.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            assignment.instructions.trim(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${assignment.maxPoints} Points Max',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            if ((assignment.attachmentUrl ?? '').trim().isNotEmpty)
              InkWell(
                onTap: () => _openAssignmentAttachment(assignment),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.download_outlined,
                        size: 13,
                        color: Color(0xFF1D4ED8),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'CONSIGNES PDF',
                        style: TextStyle(
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmissionActionButton(
    Assignment assignment,
    bool isExpired,
    String actionLabel,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 46,
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
            const Icon(Icons.send_outlined, size: 16),
            const SizedBox(width: 8),
            Text(
              actionLabel,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittedStatusPanel({
    required String statusTitle,
    required Color statusColor,
    required Color statusBg,
    required String? submittedAtRaw,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCDEDD7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFDFF4E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF16A34A),
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Devoir Soumis',
            style: TextStyle(
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if ((submittedAtRaw ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _formatSubmissionDate(submittedAtRaw!),
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusTitle,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _SubmissionStatusMeta _submissionStatusMeta(Map<String, dynamic>? item) {
    final raw = (item?['status'] ?? '').toString().trim().toLowerCase();

    if (raw.contains('review') ||
        raw.contains('révision') ||
        raw.contains('revision')) {
      return const _SubmissionStatusMeta(
        label: 'En révision',
        color: Color(0xFFEA580C),
        background: Color(0xFFFFEDD5),
      );
    }

    if (raw.contains('approved') || raw.contains('valid')) {
      return const _SubmissionStatusMeta(
        label: 'Validé',
        color: Color(0xFF15803D),
        background: Color(0xFFDCFCE7),
      );
    }

    if (raw.contains('reject')) {
      return const _SubmissionStatusMeta(
        label: 'À corriger',
        color: Color(0xFFB91C1C),
        background: Color(0xFFFEE2E2),
      );
    }

    return const _SubmissionStatusMeta(
      label: 'En révision',
      color: Color(0xFFEA580C),
      background: Color(0xFFFFEDD5),
    );
  }

  Future<void> _openAssignmentAttachment(Assignment assignment) async {
    final rawUrl = assignment.attachmentUrl?.trim() ?? '';
    if (rawUrl.isEmpty) {
      Get.snackbar('Erreur', 'Aucune consigne PDF disponible');
      return;
    }

    final resolved =
        rawUrl.startsWith('http://') || rawUrl.startsWith('https://')
            ? rawUrl
            : 'http://localhost:3001$rawUrl';
    final uri = Uri.tryParse(resolved);

    if (uri == null) {
      Get.snackbar('Erreur', 'Lien PDF invalide');
      return;
    }

    var opened = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!opened) {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!opened) {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le PDF');
    }
  }

  String _formatSubmissionDate(String raw) {
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return raw;
    }

    return _formatDate(parsed);
  }

  Future<void> _showSubmitDialog(Assignment assignment) async {
    final noteCtrl = TextEditingController();
    Map<String, dynamic>? selectedFile;
    String? selectedFileName;
    bool isSubmitting = false;
    var dialogOpen = true;

    void closeDialog() {
      if (!dialogOpen) return;
      dialogOpen = false;
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    }

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
                                  onPressed: closeDialog,
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
                                  onPressed: isSubmitting ? null : closeDialog,
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
                                              String submissionContent =
                                                  noteCtrl.text.trim();

                                              if (selectedFile != null) {
                                                final uploaded =
                                                    await _assignmentsApi
                                                        .uploadAttachment(
                                                            selectedFile!);
                                                final fileName =
                                                    uploaded['name']
                                                            ?.toString() ??
                                                        selectedFileName ??
                                                        'fichier';
                                                final fileUrl = uploaded['url']
                                                        ?.toString() ??
                                                    '';

                                                final uploadLine =
                                                    'Fichier: $fileName${fileUrl.isNotEmpty ? ' ($fileUrl)' : ''}';

                                                submissionContent =
                                                    submissionContent.isEmpty
                                                        ? uploadLine
                                                        : '$submissionContent\n$uploadLine';
                                              }

                                              await _assignmentsApi
                                                  .submitAssignment(
                                                assignmentId: assignment.id,
                                                content: submissionContent,
                                                status: 'IN_REVIEW',
                                              );

                                              await _loadTodoAssignments();

                                              if (!mounted) return;
                                              closeDialog();
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
                                              if (dialogOpen) {
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

class _SubmissionStatusMeta {
  final String label;
  final Color color;
  final Color background;

  const _SubmissionStatusMeta({
    required this.label,
    required this.color,
    required this.background,
  });
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
