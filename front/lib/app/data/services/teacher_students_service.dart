import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/teacher_student_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class TeacherStudentsService {
  static const String _baseApiUrl = 'http://localhost:3001/api';

  final AuthService _authService;

  TeacherStudentsService({AuthService? authService})
      : _authService = authService ?? Get.find<AuthService>();

  Future<List<TeacherStudentModel>> loadTeacherStudents() async {
    final meResponse = await http.get(
      Uri.parse('$_baseApiUrl/users/me?populate=*'),
      headers: _authService.authHeaders,
    );

    if (meResponse.statusCode < 200 || meResponse.statusCode >= 300) {
      throw Exception(_extractErrorMessage(meResponse));
    }

    final meDecoded = _decodeJson(meResponse.body);
    final meMap = _asMap(meDecoded['data'] ?? meDecoded);
    final instructorId = _toInt(meMap['id']);

    if (instructorId <= 0) {
      throw Exception('Impossible de recuperer l\'identite enseignant');
    }

    final enrollmentsUri = Uri.parse(
      '$_baseApiUrl/enrollments?filters[course][instructor][id][\$eq]=$instructorId&populate=student&populate=course',
    );

    final enrollmentsResponse = await http.get(
      enrollmentsUri,
      headers: _authService.authHeaders,
    );

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
    return DateTime.tryParse(value.toString());
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
