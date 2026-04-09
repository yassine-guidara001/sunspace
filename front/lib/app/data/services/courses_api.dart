import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/models/course_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CoursesApi {
  static const String baseUrl = 'http://localhost:3001/api';

  final StorageService _storageService;

  CoursesApi({StorageService? storageService})
      : _storageService = storageService ?? Get.find<StorageService>();

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/local'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'identifier': identifier.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final decodedRaw = _decodeMap(response.body);
      final decoded = _unwrapDataMap(decodedRaw);
      final token =
          (decoded['jwt'] ?? decoded['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('LOGIN Error: JWT manquant');
      }

      await _storageService.saveToken(token);
      await _storageService.write('jwt', token);
      await _storageService.write('token', token);
      return token;
    }

    throw _buildHttpException('LOGIN', response);
  }

  Future<List<Course>> getCourses() async {
    final uri = Uri.parse('$baseUrl/courses?populate=*&sort=createdAt:desc');
    final response = await http.get(uri, headers: _headersOptionalAuth());

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        final items = decoded['data'] as List<dynamic>;
        return items
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    }

    throw _buildHttpException('GET_COURSES', response);
  }

  Future<List<Course>> getInstructorCourses(int instructorId) async {
    if (instructorId <= 0) {
      return <Course>[];
    }

    final uri = Uri.parse(
      '$baseUrl/courses?filters[instructor][id][\$eq]=$instructorId&populate=*&sort=createdAt:desc',
    );
    final response = await http.get(uri, headers: _headersOptionalAuth());

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        final items = decoded['data'] as List<dynamic>;
        return items
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Course.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }

      return <Course>[];
    }

    throw _buildHttpException('GET_INSTRUCTOR_COURSES', response);
  }

  Future<List<Course>> getStudentMyCourses() async {
    final meUri = Uri.parse('$baseUrl/users/me');
    final meResponse = await http.get(meUri, headers: _headersJson());

    if (!_isSuccess(meResponse.statusCode)) {
      throw _buildHttpException('GET_MY_COURSES_ME', meResponse);
    }

    final meData = _unwrapDataMap(_decodeMap(meResponse.body));
    final studentId =
        meData['id'] ?? (meData['user'] is Map ? meData['user']['id'] : null);

    if (studentId == null) {
      throw Exception("ID d'étudiant introuvable dans /users/me");
    }

    final enrollmentsUri = Uri.parse(
      '$baseUrl/enrollments?filters[student][id][\$eq]=$studentId&populate=course',
    );
    final enrollmentsResponse =
        await http.get(enrollmentsUri, headers: _headersJson());

    if (enrollmentsResponse.statusCode == 404) {
      return <Course>[];
    }

    if (!_isSuccess(enrollmentsResponse.statusCode)) {
      throw _buildHttpException(
          'GET_MY_COURSES_ENROLLMENTS', enrollmentsResponse);
    }

    final decodedEnrollments = _decodeMap(enrollmentsResponse.body);
    final courses = _extractCoursesFromEnrollmentPayload(
      decodedEnrollments,
      currentUserId: studentId,
    );

    return courses;
  }

  Future<void> enrollCurrentStudentToCourse(Course course) async {
    final userId = await _resolveCurrentUserIdForEnrollment();

    final resolvedCourseId =
        course.id > 0 ? course.id : int.tryParse(course.documentId.trim());
    if (resolvedCourseId == null || resolvedCourseId <= 0) {
      throw Exception('Cours invalide: identifiant introuvable');
    }

    final alreadyEnrolled = await _hasExistingEnrollment(
      course: course,
    );
    if (alreadyEnrolled) {
      return;
    }

    final uri = Uri.parse('$baseUrl/enrollments');

    final primaryBody = <String, dynamic>{
      'data': {
        if (userId != null) 'student': userId,
        'course': resolvedCourseId,
        'enrolled_at': DateTime.now().toUtc().toIso8601String(),
        'mystatus': 'Active',
      }
    };

    final primaryResponse = await http.post(
      uri,
      headers: _headersJson(),
      body: jsonEncode(primaryBody),
    );

    if (_isSuccess(primaryResponse.statusCode) ||
        primaryResponse.statusCode == 409 ||
        _isDuplicateEnrollmentMessage(primaryResponse.body)) {
      return;
    }

    if (primaryResponse.statusCode == 404) {
      throw Exception('INSCRIPTION indisponible: endpoint /enrollments absent');
    }

    throw _buildHttpException('ENROLL_COURSE', primaryResponse);
  }

  Future<int?> _resolveCurrentUserIdForEnrollment() async {
    final fromStorage = _readCurrentUserId();
    if (fromStorage != null && fromStorage > 0) {
      return fromStorage;
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: _headersJson(),
      );
      if (!_isSuccess(response.statusCode)) {
        return null;
      }

      final meData = _unwrapDataMap(_decodeMap(response.body));
      final userId = _toIntNullable(
        meData['id'] ??
            (meData['user'] is Map ? (meData['user'] as Map)['id'] : null),
      );

      if (userId != null && userId > 0) {
        final cached = _readCurrentUserData() ?? <String, dynamic>{};
        final updated = Map<String, dynamic>.from(cached)..['id'] = userId;
        await _storageService.saveUserData(updated);
        await _storageService.write('user_data', updated);
        await _storageService.write('user', updated);
      }

      return userId;
    } catch (_) {
      return null;
    }
  }

  Future<Course> getCourseById(int id) async {
    if (id <= 0) {
      throw Exception('GET_COURSE_BY_ID Error: id invalide');
    }

    final populateQuery = [
      'populate[modules][populate]=*',
      'populate[instructor][fields]=username,email',
    ].join('&');

    final candidateUris = <Uri>[
      Uri.parse(
        '$baseUrl/courses?filters[id][\$eq]=$id&$populateQuery',
      ),
      Uri.parse('$baseUrl/courses/$id?$populateQuery'),
    ];

    http.Response? lastResponse;

    for (final uri in candidateUris) {
      final response = await http.get(
        uri,
        headers: _headersOptionalAuth(),
      );
      lastResponse = response;

      if (_isSuccess(response.statusCode)) {
        final decoded = _decodeMap(response.body);
        final data = decoded['data'];

        if (data is List && data.isNotEmpty) {
          final first = data.first;
          if (first is Map<String, dynamic>) {
            return Course.fromJson(first);
          }
        }

        if (data is Map<String, dynamic>) {
          return Course.fromJson(data);
        }

        return Course.fromJson(decoded);
      }

      if (response.statusCode == 400 || response.statusCode == 404) {
        continue;
      }

      throw _buildHttpException('GET_COURSE_BY_ID', response);
    }

    if (lastResponse != null) {
      throw _buildHttpException('GET_COURSE_BY_ID', lastResponse);
    }

    throw Exception('GET_COURSE_BY_ID Error: aucune reponse serveur');
  }

  Future<Course> createCourse(Course course) async {
    final payloadVariants =
        _buildCoursePayloadVariants(course.toJson(withDataWrapper: false));

    http.Response? lastResponse;

    for (var i = 0; i < payloadVariants.length; i++) {
      final response = await http.post(
        Uri.parse('$baseUrl/courses'),
        headers: _headersJson(),
        body: jsonEncode(payloadVariants[i]),
      );
      lastResponse = response;

      if (_isSuccess(response.statusCode)) {
        return Course.fromJson(_decodeMap(response.body));
      }

      // Fallback de compatibilité pour anciens backends Strapi.
      if (response.statusCode == 400 || response.statusCode == 404) {
        final wrappedResponse = await http.post(
          Uri.parse('$baseUrl/courses'),
          headers: _headersJson(),
          body: jsonEncode({'data': payloadVariants[i]}),
        );
        lastResponse = wrappedResponse;

        if (_isSuccess(wrappedResponse.statusCode)) {
          return Course.fromJson(_decodeMap(wrappedResponse.body));
        }
      }

      final hasAnotherVariant = i < payloadVariants.length - 1;
      if (hasAnotherVariant &&
          _isPayloadValidationStatus(response.statusCode)) {
        continue;
      }

      break;
    }

    if (lastResponse != null) {
      throw _buildHttpException('CREATE_COURSE', lastResponse);
    }

    throw Exception('CREATE_COURSE Error: aucune reponse serveur');
  }

  Future<Course> updateCourse(Course course) async {
    final payloadVariants =
        _buildCoursePayloadVariants(course.toJson(withDataWrapper: false));

    final candidateUris = <Uri>[
      if (course.documentId.trim().isNotEmpty)
        Uri.parse(
          '$baseUrl/courses/${Uri.encodeComponent(course.documentId.trim())}',
        ),
      if (course.id > 0) Uri.parse('$baseUrl/courses/${course.id}'),
    ];

    if (candidateUris.isEmpty) {
      throw Exception('UPDATE_COURSE Error: identifiant manquant');
    }

    http.Response? lastResponse;

    for (final uri in candidateUris) {
      var shouldTryNextUri = false;

      for (var i = 0; i < payloadVariants.length; i++) {
        final response = await http.put(
          uri,
          headers: _headersJson(),
          body: jsonEncode(payloadVariants[i]),
        );
        lastResponse = response;

        if (_isSuccess(response.statusCode)) {
          if (response.body.trim().isEmpty) {
            return course;
          }
          return Course.fromJson(_decodeMap(response.body));
        }

        // Fallback de compatibilité pour anciens backends Strapi.
        if (response.statusCode == 400 || response.statusCode == 404) {
          final wrappedResponse = await http.put(
            uri,
            headers: _headersJson(),
            body: jsonEncode({'data': payloadVariants[i]}),
          );
          lastResponse = wrappedResponse;

          if (_isSuccess(wrappedResponse.statusCode)) {
            if (wrappedResponse.body.trim().isEmpty) {
              return course;
            }
            return Course.fromJson(_decodeMap(wrappedResponse.body));
          }
        }

        if (response.statusCode == 404) {
          shouldTryNextUri = true;
          break;
        }

        final hasAnotherVariant = i < payloadVariants.length - 1;
        if (hasAnotherVariant &&
            _isPayloadValidationStatus(response.statusCode)) {
          continue;
        }

        break;
      }

      if (shouldTryNextUri) {
        continue;
      }

      break;
    }

    if (lastResponse != null && !_isSuccess(lastResponse.statusCode)) {
      throw _buildHttpException('UPDATE_COURSE', lastResponse);
    }

    throw Exception('UPDATE_COURSE Error: aucune reponse serveur');
  }

  Future<void> deleteCourse({required int id, String? documentId}) async {
    final trimmedDocumentId = documentId?.trim() ?? '';

    final candidateUris = <Uri>[
      if (trimmedDocumentId.isNotEmpty)
        Uri.parse('$baseUrl/courses/${Uri.encodeComponent(trimmedDocumentId)}'),
      if (id > 0) Uri.parse('$baseUrl/courses/$id'),
    ];

    if (candidateUris.isEmpty) {
      throw Exception('DELETE_COURSE Error: identifiant manquant');
    }

    http.Response? lastResponse;

    for (final uri in candidateUris) {
      final response = await http.delete(uri, headers: _headersJson());
      lastResponse = response;

      if (_isSuccess(response.statusCode)) {
        return;
      }

      if (response.statusCode == 404) {
        continue;
      }

      break;
    }

    if (lastResponse != null) {
      throw _buildHttpException('DELETE_COURSE', lastResponse);
    }

    throw Exception('DELETE_COURSE Error: aucune reponse serveur');
  }

  Map<String, String> _headersJson() {
    final token = _readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Auth Error: token JWT manquant');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

    return headers;
  }

  Map<String, String> _headersOptionalAuth() {
    final token = _readToken();

    final headers = <String, String>{
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  String? _readToken() {
    final token = _storageService.getToken() ??
        _storageService.read<String>('jwt') ??
        _storageService.read<String>('token');

    if (token == null) return null;

    final normalized = token.trim();
    if (normalized.toLowerCase().startsWith('bearer ')) {
      return normalized.substring(7).trim();
    }

    return normalized.isEmpty ? null : normalized;
  }

  int? _readCurrentUserId() {
    final user = _readCurrentUserData();
    if (user == null) return null;

    final rawId = user['id'];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '');
  }

  Map<String, dynamic>? _readCurrentUserData() {
    final fromService = _storageService.getUserData();
    if (fromService != null) {
      return Map<String, dynamic>.from(fromService);
    }

    final fromKey = _storageService.read<Map<String, dynamic>>('user_data') ??
        _storageService.read<Map<String, dynamic>>('user');
    if (fromKey == null) {
      return null;
    }

    return Map<String, dynamic>.from(fromKey);
  }

  bool _isSuccess(int code) => code >= 200 && code < 300;

  Exception _buildHttpException(String action, http.Response response) {
    final statusCode = response.statusCode;
    final serverMessage = _extractErrorMessage(response.body);

    if (statusCode == 401) {
      return Exception('401 Unauthorized: $serverMessage');
    }

    if (statusCode == 403) {
      return Exception('403 Forbidden: $serverMessage');
    }

    if (statusCode >= 500) {
      return Exception('500 Server Error: $serverMessage');
    }

    return Exception('HTTP $statusCode: $serverMessage');
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final msg = error['message'];
          if (msg != null) return msg.toString();
        }

        final msg = decoded['message'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {
      // ignore
    }

    return body;
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw Exception('Format JSON inattendu');
  }

  Map<String, dynamic> _unwrapDataMap(Map<String, dynamic> payload) {
    var current = payload;

    while (current['data'] is Map<String, dynamic>) {
      current = Map<String, dynamic>.from(current['data'] as Map);
    }

    return current;
  }

  Future<bool> _hasExistingEnrollment({
    required Course course,
  }) async {
    try {
      final myCourses = await getStudentMyCourses();
      return myCourses.any((item) => _courseMatches(item, course));
    } catch (_) {
      return false;
    }
  }

  bool _courseMatches(Course left, Course right) {
    if (left.id > 0 && right.id > 0 && left.id == right.id) {
      return true;
    }

    final leftDoc = left.documentId.trim();
    final rightDoc = right.documentId.trim();
    return leftDoc.isNotEmpty && rightDoc.isNotEmpty && leftDoc == rightDoc;
  }

  bool _isDuplicateEnrollmentMessage(String body) {
    final message = _extractErrorMessage(body).toLowerCase();
    return message.contains('already') ||
        message.contains('exists') ||
        message.contains('duplicate') ||
        message.contains('unique') ||
        message.contains('deja');
  }

  List<Map<String, dynamic>> _buildCoursePayloadVariants(
      Map<String, dynamic> source) {
    final cleaned = Map<String, dynamic>.from(source);

    final rawStatus =
        (cleaned['status'] ?? cleaned['mystatus'])?.toString().trim();

    cleaned.remove('status');
    cleaned.remove('mystatus');
    cleaned.remove('id');
    cleaned.remove('documentId');
    cleaned.remove('document_id');
    cleaned.remove('createdAt');
    cleaned.remove('updatedAt');
    cleaned.remove('publishedAt');

    cleaned.removeWhere((key, value) => value == null);

    final variants = <Map<String, dynamic>>[];
    final seen = <String>{};

    final withStatus = Map<String, dynamic>.from(cleaned);
    if (rawStatus != null && rawStatus.isNotEmpty) {
      withStatus['status'] = rawStatus;
    }

    final withMystatus = Map<String, dynamic>.from(cleaned);
    if (rawStatus != null && rawStatus.isNotEmpty) {
      withMystatus['mystatus'] = rawStatus;
    }

    for (final candidate in [withStatus, withMystatus]) {
      final key = jsonEncode(candidate);
      if (seen.add(key)) {
        variants.add(candidate);
      }
    }

    return variants;
  }

  bool _isPayloadValidationStatus(int statusCode) {
    return statusCode == 400 ||
        statusCode == 404 ||
        statusCode == 405 ||
        statusCode == 422;
  }

  List<Course> _extractCoursesFromEnrollmentPayload(
    Map<String, dynamic> payload, {
    int? currentUserId,
    String? currentUserDocumentId,
  }) {
    final rootData = payload['data'];

    final enrollmentNodes = <dynamic>[
      if (rootData is List) ...rootData,
      if (rootData is Map<String, dynamic>) rootData,
      if (payload['enrollments'] is List) ...(payload['enrollments'] as List),
    ];

    final courses = <Course>[];
    final seen = <String>{};

    for (final enrollment in enrollmentNodes) {
      if (enrollment is! Map) continue;

      final enrollmentMap =
          _extractDataNode(Map<String, dynamic>.from(enrollment));
      if (!_isEnrollmentOwnedByCurrentUser(
        enrollmentMap,
        currentUserId: currentUserId,
        currentUserDocumentId: currentUserDocumentId,
      )) {
        continue;
      }

      final relatedCourseNodes = <dynamic>[
        enrollmentMap['course'],
        enrollmentMap['courses'],
      ];

      for (final node in relatedCourseNodes) {
        final extracted = _extractCoursesNode(node);
        for (final course in extracted) {
          final key = course.id > 0
              ? 'id:${course.id}'
              : 'doc:${course.documentId.trim()}';
          if (seen.add(key)) {
            courses.add(course);
          }
        }
      }
    }

    return courses;
  }

  List<Course> _extractCoursesNode(dynamic node) {
    if (node == null) {
      return <Course>[];
    }

    if (node is List) {
      return node
          .whereType<Map>()
          .map((item) => Course.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    if (node is Map<String, dynamic>) {
      final data = node['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((item) => Course.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      if (data is Map<String, dynamic>) {
        return [Course.fromJson(data)];
      }

      if (_looksLikeCourseMap(node)) {
        return [Course.fromJson(node)];
      }
    }

    return <Course>[];
  }

  bool _looksLikeCourseMap(Map<String, dynamic> map) {
    if (map.containsKey('title') || map.containsKey('description')) {
      return true;
    }

    final attributes = map['attributes'];
    if (attributes is Map<String, dynamic>) {
      return attributes.containsKey('title') ||
          attributes.containsKey('description');
    }

    return false;
  }

  bool _isEnrollmentOwnedByCurrentUser(
    Map<String, dynamic> enrollment, {
    int? currentUserId,
    String? currentUserDocumentId,
  }) {
    final userRelations = <dynamic>[
      enrollment['student'],
      enrollment['user'],
    ];

    final hasUserInfo = userRelations.any((item) => item != null);
    if (!hasUserInfo) {
      return true;
    }

    for (final relation in userRelations) {
      if (_matchesCurrentUser(
        relation,
        currentUserId: currentUserId,
        currentUserDocumentId: currentUserDocumentId,
      )) {
        return true;
      }
    }

    return false;
  }

  bool _matchesCurrentUser(
    dynamic relation, {
    int? currentUserId,
    String? currentUserDocumentId,
  }) {
    if (relation == null) return false;

    if (relation is num) {
      return currentUserId != null && relation.toInt() == currentUserId;
    }

    if (relation is String) {
      final value = relation.trim();
      if (value.isEmpty) return false;

      final relationAsInt = int.tryParse(value);
      if (relationAsInt != null && currentUserId != null) {
        return relationAsInt == currentUserId;
      }

      return currentUserDocumentId != null && value == currentUserDocumentId;
    }

    if (relation is List) {
      for (final item in relation) {
        if (_matchesCurrentUser(
          item,
          currentUserId: currentUserId,
          currentUserDocumentId: currentUserDocumentId,
        )) {
          return true;
        }
      }
      return false;
    }

    if (relation is Map<String, dynamic>) {
      final normalized = _extractDataNode(relation);
      final id = _toIntNullable(normalized['id']);
      if (id != null && currentUserId != null && id == currentUserId) {
        return true;
      }

      final documentId =
          (normalized['documentId'] ?? normalized['document_id'] ?? '')
              .toString()
              .trim();
      if (documentId.isNotEmpty &&
          currentUserDocumentId != null &&
          documentId == currentUserDocumentId) {
        return true;
      }

      final data = relation['data'];
      if (data != null) {
        return _matchesCurrentUser(
          data,
          currentUserId: currentUserId,
          currentUserDocumentId: currentUserDocumentId,
        );
      }
    }

    return false;
  }

  Map<String, dynamic> _extractDataNode(Map<String, dynamic> json) {
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return _extractDataNode(data);
      }
    }

    final attributes = json['attributes'];
    if (attributes is Map<String, dynamic>) {
      return {
        'id': json['id'] ?? attributes['id'],
        'documentId': json['documentId'] ?? json['document_id'],
        ...attributes,
      };
    }

    return json;
  }

  int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
