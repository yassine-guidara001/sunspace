import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/services/assignments_api.dart';
import 'package:flutter_getx_app/app/data/models/teacher_student_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TeacherStudentsService {
  static const String _baseApiUrl = 'http://localhost:3001/api';
  static const String _meEndpoint = '/users/me?populate=role';

  final AuthService _authService;
  final AssignmentsApi _assignmentsApi;

  TeacherStudentsService({AuthService? authService})
      : _authService = authService ?? Get.find<AuthService>(),
        _assignmentsApi = AssignmentsApi(authService: authService);

  Future<List<TeacherStudentModel>> loadTeacherStudents() async {
    final instructorId = await _fetchInstructorId();

    if (instructorId <= 0) {
      throw Exception('Impossible de recuperer l\'identite enseignant');
    }

    final enrollmentsResponse =
        await _fetchEnrollmentsByInstructor(instructorId);

    if (enrollmentsResponse.statusCode < 200 ||
        enrollmentsResponse.statusCode >= 300) {
      throw Exception(_extractErrorMessage(enrollmentsResponse));
    }

    final decoded = _decodeJson(enrollmentsResponse.body);
    final rows = _extractDataList(decoded).map((item) {
      final raw = _asMap(item);
      final attrs = _extractAttributes(raw);

      final enrollmentId = _firstNonEmpty([
        raw['documentId'],
        raw['id'],
      ]);

      final studentRel = _extractRelationMap(attrs['student']);
      final studentAttrs = _extractAttributes(studentRel);
      final studentId = _toInt(studentRel['id'] ?? studentAttrs['id']);

      final studentName = _firstNonEmpty([
        studentAttrs['username'],
        studentAttrs['fullName'],
        studentAttrs['name'],
      ], fallback: 'Etudiant');

      final studentEmail = _firstNonEmpty([
        studentAttrs['email'],
      ], fallback: '-');

      final courseRel = _extractRelationMap(attrs['course']);
      final courseAttrs = _extractAttributes(courseRel);
      final courseId =
          _toInt(courseRel['id'] ?? courseAttrs['id'] ?? raw['courseId']);
      final courseName = _firstNonEmpty([
        courseAttrs['title'],
        courseAttrs['name'],
        courseAttrs['label'],
      ], fallback: 'Cours');

      final progressPercent = _toPercent(
        attrs['progress'] ??
            attrs['progression'] ??
            attrs['completion'] ??
            attrs['completionRate'],
      );

      final enrolledAt = _parseDate(
        attrs['enrolledAt'] ??
            attrs['enrollmentDate'] ??
            attrs['createdAt'] ??
            raw['createdAt'],
      );

      return _TeacherStudentRow(
        enrollmentId: enrollmentId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseName: courseName,
        courseId: courseId,
        progressPercent: progressPercent,
        enrolledAt: enrolledAt,
      );
    }).toList();

    final progressByEnrollment = await _buildProgressByCourseAndStudent(rows);

    return rows
        .map(
          (row) => TeacherStudentModel(
            enrollmentId: row.enrollmentId,
            studentId: row.studentId,
            studentName: row.studentName,
            studentEmail: row.studentEmail,
            courseName: row.courseName,
            progressPercent: progressByEnrollment[
                    _courseStudentKey(row.courseId, row.studentId)] ??
                row.progressPercent,
            enrolledAt: row.enrolledAt,
          ),
        )
        .toList();
  }

  Future<Map<String, int>> _buildProgressByCourseAndStudent(
    List<_TeacherStudentRow> rows,
  ) async {
    final rowsByCourse = <int, List<_TeacherStudentRow>>{};
    for (final row in rows) {
      if (row.courseId <= 0 || row.studentId <= 0) continue;
      rowsByCourse.putIfAbsent(row.courseId, () => <_TeacherStudentRow>[]);
      rowsByCourse[row.courseId]!.add(row);
    }

    if (rowsByCourse.isEmpty) {
      return const <String, int>{};
    }

    final progress = <String, int>{};

    for (final entry in rowsByCourse.entries) {
      final courseId = entry.key;
      final courseRows = entry.value;
      final assignments = await _assignmentsApi.getAssignmentsForCourse(
        courseId: courseId,
      );

      if (assignments.isEmpty) {
        for (final row in courseRows) {
          progress[_courseStudentKey(row.courseId, row.studentId)] = 0;
        }
        continue;
      }

      final submittedByStudent = <int, Set<int>>{};

      for (final assignment in assignments) {
        if (assignment.id <= 0) continue;

        final submissions =
            await _assignmentsApi.getSubmissionsForAssignmentWithStudents(
          assignment.id,
        );

        final studentIdsForThisAssignment = <int>{};
        for (final submission in submissions) {
          final submissionMap = _asMap(submission);
          final studentRel = _extractRelationMap(submissionMap['student']);
          final studentAttrs = _extractAttributes(studentRel);
          final studentId = _toInt(studentRel['id'] ?? studentAttrs['id']);
          if (studentId > 0) {
            studentIdsForThisAssignment.add(studentId);
          }
        }

        for (final studentId in studentIdsForThisAssignment) {
          submittedByStudent.putIfAbsent(studentId, () => <int>{});
          submittedByStudent[studentId]!.add(assignment.id);
        }
      }

      final totalAssignments = assignments.length;
      for (final row in courseRows) {
        final submittedCount = submittedByStudent[row.studentId]?.length ?? 0;
        final percent = totalAssignments == 0
            ? 0
            : ((submittedCount / totalAssignments) * 100).round().clamp(0, 100);
        progress[_courseStudentKey(row.courseId, row.studentId)] = percent;
      }
    }

    return progress;
  }

  Future<int> _fetchInstructorId() async {
    final cachedId = _authService.currentUserId;
    if (cachedId != null && cachedId > 0) {
      return cachedId;
    }

    final meResponse = await http.get(
      Uri.parse('$_baseApiUrl$_meEndpoint'),
      headers: _authService.authHeaders,
    );

    if (meResponse.statusCode < 200 || meResponse.statusCode >= 300) {
      throw Exception(_extractErrorMessage(meResponse));
    }

    final meDecoded = _decodeJson(meResponse.body);
    final resolvedId = _extractUserId(meDecoded);
    if (resolvedId > 0) return resolvedId;

    final synced = await _authService.syncCurrentUserProfile(force: true);
    if (synced != null) {
      final syncedId = _extractUserId(synced);
      if (syncedId > 0) return syncedId;
    }

    return 0;
  }

  Future<http.Response> _fetchEnrollmentsByInstructor(int instructorId) {
    // Requête alignée avec la capture réseau:
    // GET /enrollments?filters[course][instructor][id][$eq]=ID&populate=student&populate=course
    final enrollmentsUri = Uri.parse(
      '$_baseApiUrl/enrollments?filters[course][instructor][id][\$eq]=$instructorId&populate=student&populate=course',
    );

    return http.get(
      enrollmentsUri,
      headers: _authService.authHeaders,
    );
  }

  dynamic _decodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  List<dynamic> _extractDataList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) return [data];
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  Map<String, dynamic> _extractAttributes(Map<String, dynamic> raw) {
    final attrs = raw['attributes'];
    if (attrs is Map<String, dynamic>) return attrs;
    if (attrs is Map) return Map<String, dynamic>.from(attrs);
    return raw;
  }

  Map<String, dynamic> _extractRelationMap(dynamic relation) {
    if (relation == null) return <String, dynamic>{};

    final relationMap = _asMap(relation);
    if (relationMap.isEmpty) return <String, dynamic>{};

    final data = relationMap['data'];
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }

    if (relationMap.containsKey('id') ||
        relationMap.containsKey('attributes')) {
      return relationMap;
    }

    return <String, dynamic>{};
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  int _extractUserId(dynamic payload) {
    if (payload == null) return 0;

    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);

      // Cas standard: /users/me => { id, username, ... }
      final direct = _toInt(map['id'] ?? map['userId'] ?? map['user_id']);
      if (direct > 0 && _looksLikeUserMap(map)) return direct;

      // Cas enveloppés possibles: { data: {...} } ou { user: {...} }
      final fromData = _extractUserId(map['data']);
      if (fromData > 0) return fromData;

      final fromUser = _extractUserId(map['user']);
      if (fromUser > 0) return fromUser;

      // Dernier fallback: id direct même sans clés utilisateur explicites.
      if (direct > 0) return direct;
    }

    if (payload is List) {
      for (final item in payload) {
        final id = _extractUserId(item);
        if (id > 0) return id;
      }
    }

    return 0;
  }

  bool _looksLikeUserMap(Map<String, dynamic> map) {
    const userKeys = <String>{
      'username',
      'email',
      'fullName',
      'name',
      'role',
      'confirmed',
      'blocked',
    };
    for (final key in userKeys) {
      if (map.containsKey(key)) return true;
    }
    return false;
  }

  int _toPercent(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.clamp(0, 100);
    if (value is num) return value.round().clamp(0, 100);

    final raw = value.toString().replaceAll('%', '').trim();
    final parsed = num.tryParse(raw);
    if (parsed == null) return 0;
    return parsed.round().clamp(0, 100);
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  String _firstNonEmpty(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      final text = ('$value').trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return fallback;
  }

  String _courseStudentKey(int courseId, int studentId) {
    return '$courseId:$studentId';
  }

  String _extractErrorMessage(http.Response response) {
    final decoded = _decodeJson(response.body);
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
      final message = decoded['message'];
      if (message != null) return message.toString();
    }
    return 'Erreur HTTP ${response.statusCode}';
  }
}

class _TeacherStudentRow {
  const _TeacherStudentRow({
    required this.enrollmentId,
    required this.studentId,
    required this.studentName,
    required this.studentEmail,
    required this.courseName,
    required this.courseId,
    required this.progressPercent,
    required this.enrolledAt,
  });

  final String enrollmentId;
  final int studentId;
  final String studentName;
  final String studentEmail;
  final String courseName;
  final int courseId;
  final int progressPercent;
  final DateTime? enrolledAt;
}
