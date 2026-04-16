import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/teacher_student_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TeacherStudentsService {
  static const String _baseApiUrl = 'http://localhost:3001/api';
  static const String _meEndpoint = '/users/me?populate=role';

  final AuthService _authService;

  TeacherStudentsService({AuthService? authService})
      : _authService = authService ?? Get.find<AuthService>();

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

      return TeacherStudentModel(
        enrollmentId: enrollmentId,
        studentId: studentId,
        studentName: studentName,
        studentEmail: studentEmail,
        courseName: courseName,
        progressPercent: progressPercent,
        enrolledAt: enrolledAt,
      );
    }).toList();

    return rows;
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
