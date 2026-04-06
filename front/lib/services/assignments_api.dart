import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AssignmentsApi {
  static const String _baseApiUrl = 'http://localhost:3001/api';
  static const String _serverBaseUrl = 'http://localhost:3001';
  static const Duration _requestTimeout = Duration(seconds: 20);

  final AuthService _authService;

  AssignmentsApi({AuthService? authService})
      : _authService = authService ?? Get.find<AuthService>();

  Future<List<Assignment>> getAssignments({bool onlyInstructor = false}) async {
    final userId = _authService.currentUserId;

    final populateQuery = [
      'populate=course',
      'populate=submissions',
      'populate=attachment',
    ].join('&');

    // Pour les enseignants : filtrer par cours qu'ils enseignent
    if (onlyInstructor) {
      final filteredUri = userId == null
          ? Uri.parse('$_baseApiUrl/assignments?$populateQuery')
          : Uri.parse(
              '$_baseApiUrl/assignments?filters[course][instructor][id][\$eq]=$userId&$populateQuery',
            );

      final assignments = await _fetchAssignmentsCandidate(filteredUri);
      if (assignments != null) {
        return assignments;
      }
      return const <Assignment>[];
    }

    // Pour les étudiants : récupérer en priorité les devoirs des cours inscrits.
    final enrolledCourseIds = await _getStudentEnrolledCourseIds();

    if (enrolledCourseIds.isEmpty) {
      debugPrint(
          '[AssignmentsAPI] Aucun cours inscrit trouvé, fallback sur tous les devoirs');

      final fallbackUri = Uri.parse('$_baseApiUrl/assignments?$populateQuery');
      final fallbackAssignments = await _fetchAssignmentsCandidate(fallbackUri);
      return fallbackAssignments ?? const <Assignment>[];
    }

    final allAssignments = <Assignment>[];

    // Récupérer les devoirs pour chaque cours inscrit
    for (final courseId in enrolledCourseIds) {
      final uri = Uri.parse(
        '$_baseApiUrl/assignments?filters[course][id][\$eq]=$courseId&$populateQuery',
      );

      final assignments = await _fetchAssignmentsCandidate(uri);
      if (assignments != null) {
        allAssignments.addAll(assignments);
      }
    }

    return _dedupeById(allAssignments);
  }

  Future<List<Assignment>> getAssignmentsForCourse({
    int? courseId,
    String? courseDocumentId,
    bool onlyTodo = false,
  }) async {
    final populateQuery = [
      'populate=attachment',
      'populate=submissions',
      'populate=course',
    ].join('&');

    final normalizedCourseDocumentId = courseDocumentId?.trim() ?? '';

    if ((courseId == null || courseId <= 0) &&
        normalizedCourseDocumentId.isEmpty) {
      return const <Assignment>[];
    }

    final candidateUris = <Uri>[
      if (courseId != null && courseId > 0)
        Uri.parse(
          '$_baseApiUrl/assignments?filters[course][id][\$eq]=$courseId&$populateQuery',
        ),
      if (normalizedCourseDocumentId.isNotEmpty)
        Uri.parse(
          '$_baseApiUrl/assignments?filters[course][documentId][\$eq]=${Uri.encodeComponent(normalizedCourseDocumentId)}&$populateQuery',
        ),
    ];

    final merged = <Assignment>[];

    for (final uri in candidateUris) {
      final parsed = await _fetchAssignmentsCandidate(uri);
      if (parsed == null) {
        continue;
      }

      merged.addAll(parsed);
    }

    if (merged.isEmpty) {
      return const <Assignment>[];
    }

    final unique = _dedupeById(merged);

    final filteredByCourse = unique.where((assignment) {
      var matchesId = false;
      var matchesDocumentId = false;

      if (courseId != null && courseId > 0) {
        matchesId = assignment.courseId == courseId;
      }

      if (normalizedCourseDocumentId.isNotEmpty) {
        final assignmentDoc = assignment.courseDocumentId?.trim() ?? '';
        matchesDocumentId = assignmentDoc == normalizedCourseDocumentId;
      }

      if (courseId != null &&
          courseId > 0 &&
          normalizedCourseDocumentId.isNotEmpty) {
        return matchesId || matchesDocumentId;
      }

      if (courseId != null && courseId > 0) {
        return matchesId;
      }

      if (normalizedCourseDocumentId.isNotEmpty) {
        return matchesDocumentId;
      }

      return false;
    }).toList();

    if (!onlyTodo) {
      return filteredByCourse;
    }

    final now = DateTime.now();
    return filteredByCourse.where((assignment) {
      // "A faire" only: hide expired assignments.
      return !assignment.dueDate.isBefore(now);
    }).toList();
  }

  Future<List<Assignment>?> _fetchAssignmentsCandidate(Uri baseUri) async {
    // Try paginated GET first to retrieve all assignments, then fall back.
    final firstPageUri = _withPagination(baseUri, page: 1, pageSize: 100);

    debugPrint('[AssignmentsAPI] GET $firstPageUri');
    http.Response response = await http
        .get(firstPageUri, headers: _authService.authHeaders)
        .timeout(_requestTimeout);
    _logResponse(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return _collectAllPages(baseUri, response);
    }

    if (response.statusCode == 400 ||
        response.statusCode == 404 ||
        response.statusCode == 422) {
      if (firstPageUri.toString() != baseUri.toString()) {
        debugPrint('[AssignmentsAPI] GET $baseUri');
        response = await http
            .get(baseUri, headers: _authService.authHeaders)
            .timeout(_requestTimeout);
        _logResponse(response);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return _collectAllPages(baseUri, response);
        }

        if (response.statusCode == 400 ||
            response.statusCode == 404 ||
            response.statusCode == 422) {
          return null;
        }
      }

      return null;
    }

    _throwIfError(response);
    return null;
  }

  Future<List<Assignment>> _collectAllPages(
    Uri baseUri,
    http.Response firstResponse,
  ) async {
    final items = _parseAssignmentsList(firstResponse.body);
    final pageInfo = _extractPaginationInfo(firstResponse.body);
    if (pageInfo == null || pageInfo.pageCount <= pageInfo.page) {
      return _dedupeById(items);
    }

    for (var page = pageInfo.page + 1; page <= pageInfo.pageCount; page++) {
      final pageUri = _withPagination(
        baseUri,
        page: page,
        pageSize: pageInfo.pageSize,
      );

      debugPrint('[AssignmentsAPI] GET $pageUri');
      final response = await http
          .get(pageUri, headers: _authService.authHeaders)
          .timeout(_requestTimeout);
      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        items.addAll(_parseAssignmentsList(response.body));
        continue;
      }

      if (response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 422) {
        break;
      }

      _throwIfError(response);
    }

    return _dedupeById(items);
  }

  Uri _withPagination(Uri uri, {required int page, int? pageSize}) {
    final parts = <String>[];

    if (uri.query.trim().isNotEmpty) {
      parts.add(uri.query);
    }

    parts.add('pagination[page]=${Uri.encodeQueryComponent(page.toString())}');
    if (pageSize != null && pageSize > 0) {
      parts.add(
        'pagination[pageSize]=${Uri.encodeQueryComponent(pageSize.toString())}',
      );
    }

    return uri.replace(query: parts.join('&'));
  }

  _AssignmentsPagination? _extractPaginationInfo(String body) {
    final decoded = _decodeMap(body);
    final meta = decoded['meta'];
    if (meta is! Map) return null;

    final pagination = meta['pagination'];
    if (pagination is! Map) return null;

    final page = _toIntNullable(pagination['page']) ?? 1;
    final pageCount = _toIntNullable(pagination['pageCount']) ?? 1;
    final pageSize = _toIntNullable(pagination['pageSize']);

    return _AssignmentsPagination(
      page: page,
      pageCount: pageCount,
      pageSize: pageSize,
    );
  }

  List<Assignment> _dedupeById(List<Assignment> items) {
    final unique = <int, Assignment>{};
    for (final item in items) {
      unique[item.id] = item;
    }
    return unique.values.toList();
  }

  Future<Assignment> getAssignmentById(
    int id, {
    String? documentId,
  }) async {
    final trimmedDocumentId = documentId?.trim() ?? '';
    final candidateUris = <Uri>[
      if (trimmedDocumentId.isNotEmpty)
        Uri.parse(
            '$_baseApiUrl/assignments/${Uri.encodeComponent(trimmedDocumentId)}?populate=*'),
      Uri.parse('$_baseApiUrl/assignments/$id?populate=*'),
    ];

    http.Response? lastResponse;

    for (final uri in candidateUris) {
      debugPrint('[AssignmentsAPI] GET $uri');

      final response = await http
          .get(uri, headers: _authService.authHeaders)
          .timeout(_requestTimeout);

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Assignment.fromJson(_decodeMap(response.body));
      }

      lastResponse = response;

      if (response.statusCode == 404) {
        continue;
      }

      _throwIfError(response);
    }

    if (lastResponse != null) {
      _throwIfError(lastResponse);
    }

    throw Exception('Ressource introuvable');
  }

  Future<Assignment> createAssignment(Map data) async {
    final uri = Uri.parse('$_baseApiUrl/assignments');
    final payload = {'data': _sanitizePayload(Map<String, dynamic>.from(data))};

    debugPrint('[AssignmentsAPI] POST $uri');
    debugPrint('[AssignmentsAPI] Payload: $payload');

    final response = await http
        .post(
          uri,
          headers: _authService.authHeaders,
          body: jsonEncode(payload),
        )
        .timeout(_requestTimeout);

    _logResponse(response);
    _throwIfError(response);

    return Assignment.fromJson(_decodeMap(response.body));
  }

  Future<Assignment> updateAssignment(int id, Map data,
      {String? documentId}) async {
    final identifier = (documentId != null && documentId.trim().isNotEmpty)
        ? documentId.trim()
        : '$id';
    final uri = Uri.parse('$_baseApiUrl/assignments/$identifier');
    final payload = {'data': _sanitizePayload(Map<String, dynamic>.from(data))};

    debugPrint('[AssignmentsAPI] PUT $uri');
    debugPrint('[AssignmentsAPI] Payload: $payload');

    http.Response response = await http
        .put(
          uri,
          headers: _authService.authHeaders,
          body: jsonEncode(payload),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 405) {
      debugPrint('[AssignmentsAPI] PUT non autorisé, tentative PATCH $uri');
      response = await http
          .patch(
            uri,
            headers: _authService.authHeaders,
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout);
    }

    _logResponse(response);
    _throwIfError(response);

    return Assignment.fromJson(_decodeMap(response.body));
  }

  Future<void> deleteAssignment(int id) async {
    final uri = Uri.parse('$_baseApiUrl/assignments/$id');
    debugPrint('[AssignmentsAPI] DELETE $uri');

    final response = await http
        .delete(uri, headers: _authService.authHeaders)
        .timeout(_requestTimeout);
    _logResponse(response);
    _throwIfError(response);
  }

  Future<Map<String, dynamic>> uploadAttachment(dynamic file) async {
    final uri = Uri.parse('$_baseApiUrl/upload');
    debugPrint('[AssignmentsAPI] POST $uri (upload)');

    final token = _authService.token;
    if (token == null || token.isEmpty) {
      throw Exception('Session expirée');
    }

    final bytes = _extractFileBytes(file);
    final path = _extractFilePath(file);
    final filename = _extractFileName(file);

    final hasBytes = bytes != null && bytes.isNotEmpty;
    final hasPath = path != null && path.isNotEmpty;

    if ((!hasBytes && !hasPath) || filename.isEmpty) {
      throw Exception('Fichier invalide pour upload');
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';

    if (hasPath && !kIsWeb) {
      request.files.add(await http.MultipartFile.fromPath('files', path));
    } else {
      request.files.add(
        http.MultipartFile.fromBytes('files', bytes!, filename: filename),
      );
    }

    final streamed = await request.send().timeout(_requestTimeout);
    final response = await http.Response.fromStream(streamed);

    _logResponse(response);
    _throwIfError(response);

    final decoded = jsonDecode(response.body);
    if (decoded is List && decoded.isNotEmpty) {
      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        final fileId = _toIntNullable(first['id']);
        if (fileId == null) {
          throw Exception('ID de fichier introuvable');
        }

        final rawUrl = (first['url'] ?? '').toString();
        if (rawUrl.isEmpty) {
          throw Exception('URL de fichier introuvable');
        }

        final fileUrl =
            rawUrl.startsWith('http') ? rawUrl : '$_serverBaseUrl$rawUrl';

        return {
          'id': fileId,
          'url': fileUrl,
          'name': (first['name'] ?? filename).toString(),
        };
      }
    }

    throw Exception('Réponse upload invalide');
  }

  Map<String, dynamic> _sanitizePayload(Map<String, dynamic> source) {
    final normalizedDescription =
        _normalizeDescription(source['description'] ?? source['instructions']);
    final hasAttachmentField =
        source.containsKey('attachment') || source.containsKey('attachmentId');
    final resolvedCourse = _resolveCourseRelation(source);

    final attachmentValue = source.containsKey('attachmentId')
        ? source['attachmentId']
        : source['attachment'];

    final payload = <String, dynamic>{
      'title': source['title'],
      'description': normalizedDescription,
      'course': resolvedCourse,
      'due_date': source['due_date'] ?? source['dueDate'],
      'max_points': source['max_points'] ?? source['maxPoints'] ?? 100,
      'passing_score': source['passing_score'] ??
          source['passingGrade'] ??
          source['passing_grade'] ??
          0,
      'allow_late_submission': source['allow_late_submission'] ??
          source['allowLateSubmission'] ??
          false,
      'attachment': attachmentValue,
    };

    payload.removeWhere(
      (key, value) =>
          value == null && !(hasAttachmentField && key == 'attachment'),
    );
    return payload;
  }

  dynamic _resolveCourseRelation(Map<String, dynamic> source) {
    final rawCourse = source['course'];
    final fallbackCourseId =
        _toIntNullable(source['courseId'] ?? source['course_id']);

    if (rawCourse is int) return rawCourse;
    if (rawCourse is num) return rawCourse.toInt();
    if (fallbackCourseId != null) return fallbackCourseId;

    if (rawCourse is String) {
      final trimmed = rawCourse.trim();
      if (trimmed.isEmpty) return null;
      final numeric = int.tryParse(trimmed);
      if (numeric != null) return numeric;
      return trimmed;
    }

    return rawCourse;
  }

  List<Map<String, dynamic>>? _normalizeDescription(dynamic value) {
    if (value == null) return null;

    if (value is List) {
      final list = value.whereType<Map>().map((e) {
        return Map<String, dynamic>.from(e);
      }).toList();
      return list.isEmpty ? null : list;
    }

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    return [
      {
        'type': 'paragraph',
        'children': [
          {'type': 'text', 'text': text}
        ],
      }
    ];
  }

  void _logResponse(http.Response response) {
    debugPrint(
        '[AssignmentsAPI] Response ${response.statusCode} ${response.request?.url.path}');
    debugPrint('[AssignmentsAPI] Body: ${response.body}');
  }

  void _throwIfError(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final message = _extractMessage(response.body);

    if (response.statusCode == 400) {
      throw Exception('Données invalides');
    }

    if (response.statusCode == 401) {
      _authService.handleUnauthorized();
      if (Get.currentRoute != Routes.LOGIN) {
        Get.offAllNamed(Routes.LOGIN);
      }
      throw Exception('Session expirée');
    }

    if (response.statusCode == 403) {
      throw Exception('Accès refusé');
    }

    if (response.statusCode == 404) {
      throw Exception('Ressource introuvable');
    }

    if (response.statusCode >= 500) {
      throw Exception('Erreur serveur');
    }

    throw Exception(message);
  }

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error']?['message']?.toString() ??
            decoded['message']?.toString() ??
            'Erreur inconnue';
      }
    } catch (_) {
      // ignore
    }
    return 'Connexion impossible';
  }

  Map<String, dynamic> _decodeMap(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  List<Assignment> _parseAssignmentsList(String body) {
    final decoded = _decodeMap(body);
    final data = decoded['data'];
    if (data is! List) {
      return const <Assignment>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Assignment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<Map<String, dynamic>> _parseSubmissionsList(String body) {
    final decoded = _decodeMap(body);
    final data = decoded['data'];
    if (data is! List) {
      return const <Map<String, dynamic>>[];
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  int? _extractSubmissionAssignmentId(Map<String, dynamic> submission) {
    final node = _extractContentNode(submission);
    final assignmentNode = node['assignment'];

    if (assignmentNode is int) return assignmentNode;
    if (assignmentNode is num) return assignmentNode.toInt();

    if (assignmentNode is Map<String, dynamic>) {
      final assignmentData = _extractContentNode(assignmentNode);
      return _toIntNullable(assignmentData['id']);
    }

    return _toIntNullable(assignmentNode);
  }

  Map<String, dynamic> _extractContentNode(Map<String, dynamic> json) {
    if (json.containsKey('data')) {
      final nested = json['data'];
      if (nested is Map<String, dynamic>) {
        return _extractContentNode(nested);
      }
    }

    final attributes = json['attributes'];
    if (attributes is Map<String, dynamic>) {
      return {
        'id': json['id'] ?? attributes['id'],
        ...attributes,
      };
    }

    return json;
  }

  Uint8List? _extractFileBytes(dynamic file) {
    if (file is Map<String, dynamic>) {
      final dynamic bytes = file['bytes'];
      if (bytes is Uint8List) return bytes;
      if (bytes is List<int>) return Uint8List.fromList(bytes);
    }
    return null;
  }

  String? _extractFilePath(dynamic file) {
    if (file is Map<String, dynamic>) {
      final path = file['path']?.toString().trim();
      if (path != null && path.isNotEmpty) {
        return path;
      }
    }
    return null;
  }

  String _extractFileName(dynamic file) {
    if (file is Map<String, dynamic>) {
      final name = file['name']?.toString() ?? '';
      return name.trim();
    }
    return '';
  }

  int? _toIntNullable(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Récupère les submissions pour un assignment spécifique
  Future<List<Map<String, dynamic>>> getSubmissionsForAssignment(
      int assignmentId) async {
    final userId = _authService.currentUserId;

    if (userId == null) {
      debugPrint(
          '[AssignmentsAPI] Aucun userId trouvé pour récupérer les submissions');
      return const <Map<String, dynamic>>[];
    }

    final uri = Uri.parse(
      '$_baseApiUrl/submissions?filters[assignment][id][\$eq]=$assignmentId&filters[student][id][\$eq]=$userId&populate=*',
    );

    debugPrint('[AssignmentsAPI] GET $uri');

    try {
      final response = await http
          .get(uri, headers: _authService.authHeaders)
          .timeout(_requestTimeout);

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = _decodeMap(response.body);
        final data = decoded['data'];

        if (data is List) {
          return data.whereType<Map<String, dynamic>>().toList();
        }
      }

      if (response.statusCode == 404) {
        return const <Map<String, dynamic>>[];
      }

      _throwIfError(response);
    } catch (e) {
      debugPrint(
          '[AssignmentsAPI] Erreur lors de la récupération des submissions: $e');
    }

    return const <Map<String, dynamic>>[];
  }

  /// Récupère les submissions de l'étudiant courant et les regroupe par devoir.
  Future<Map<int, List<Map<String, dynamic>>>>
      getStudentSubmissionsByAssignment({Set<int>? assignmentIds}) async {
    final userId = _authService.currentUserId;

    if (userId == null) {
      debugPrint(
          '[AssignmentsAPI] Aucun userId trouvé pour récupérer les submissions étudiant');
      return const <int, List<Map<String, dynamic>>>{};
    }

    final baseUri = Uri.parse(
      '$_baseApiUrl/submissions?filters[student][id][\$eq]=$userId&populate=assignment',
    );

    final firstPageUri = _withPagination(baseUri, page: 1, pageSize: 100);

    debugPrint('[AssignmentsAPI] GET $firstPageUri');

    final firstResponse = await http
        .get(firstPageUri, headers: _authService.authHeaders)
        .timeout(_requestTimeout);
    _logResponse(firstResponse);

    if (firstResponse.statusCode == 404) {
      return const <int, List<Map<String, dynamic>>>{};
    }

    if (firstResponse.statusCode < 200 || firstResponse.statusCode >= 300) {
      _throwIfError(firstResponse);
      return const <int, List<Map<String, dynamic>>>{};
    }

    final submissions = <Map<String, dynamic>>[];
    submissions.addAll(_parseSubmissionsList(firstResponse.body));

    final pageInfo = _extractPaginationInfo(firstResponse.body);
    if (pageInfo != null && pageInfo.pageCount > pageInfo.page) {
      for (var page = pageInfo.page + 1; page <= pageInfo.pageCount; page++) {
        final pageUri = _withPagination(
          baseUri,
          page: page,
          pageSize: pageInfo.pageSize,
        );

        debugPrint('[AssignmentsAPI] GET $pageUri');

        final response = await http
            .get(pageUri, headers: _authService.authHeaders)
            .timeout(_requestTimeout);
        _logResponse(response);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          submissions.addAll(_parseSubmissionsList(response.body));
          continue;
        }

        if (response.statusCode == 404 ||
            response.statusCode == 400 ||
            response.statusCode == 422) {
          break;
        }

        _throwIfError(response);
      }
    }

    final grouped = <int, List<Map<String, dynamic>>>{};
    final filterIds = assignmentIds ?? const <int>{};
    final shouldFilter = filterIds.isNotEmpty;

    for (final submission in submissions) {
      final assignmentId = _extractSubmissionAssignmentId(submission);
      if (assignmentId == null || assignmentId <= 0) {
        continue;
      }

      if (shouldFilter && !filterIds.contains(assignmentId)) {
        continue;
      }

      grouped.putIfAbsent(assignmentId, () => <Map<String, dynamic>>[]);
      grouped[assignmentId]!.add(submission);
    }

    return grouped;
  }

  /// Récupère les IDs des cours auxquels l'étudiant est inscrit via les enrollments
  Future<List<int>> _getStudentEnrolledCourseIds() async {
    final userId = await _resolveCurrentUserId();

    if (userId == null) {
      debugPrint('[AssignmentsAPI] Aucun userId trouvé');
      return const <int>[];
    }

    final candidateUris = <Uri>[
      Uri.parse(
        '$_baseApiUrl/enrollments?filters[student][id][\$eq]=$userId&populate=course',
      ),
    ];

    for (final uri in candidateUris) {
      debugPrint('[AssignmentsAPI] GET $uri');

      try {
        final response = await http
            .get(uri, headers: _authService.authHeaders)
            .timeout(_requestTimeout);

        _logResponse(response);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = _decodeMap(response.body);
          final data = decoded['data'];

          if (data is List) {
            final courseIds = <int>[];

            for (final enrollment in data) {
              if (enrollment is! Map) continue;

              // Compatible Node + structures legacy de type Strapi.
              final node = _extractContentNode(
                Map<String, dynamic>.from(enrollment),
              );
              final course = node['course'];

              if (course is Map<String, dynamic>) {
                final courseNode = _extractContentNode(course);
                final courseId = _toIntNullable(courseNode['id']);
                if (courseId != null) {
                  courseIds.add(courseId);
                }
                continue;
              }

              if (course is int) {
                courseIds.add(course);
                continue;
              }

              final courseId = _toIntNullable(course);
              if (courseId != null) {
                courseIds.add(courseId);
              }
            }

            debugPrint('[AssignmentsAPI] Cours inscrits: $courseIds');
            return courseIds.toSet().toList();
          }
        }

        if (response.statusCode == 404 || response.statusCode == 400) {
          continue;
        }

        _throwIfError(response);
      } catch (e) {
        debugPrint(
            '[AssignmentsAPI] Erreur lors de la récupération des enrollments: $e');
      }
    }

    return const <int>[];
  }

  Future<int?> _resolveCurrentUserId() async {
    final cachedUserId = _authService.currentUserId;
    if (cachedUserId != null && cachedUserId > 0) {
      return cachedUserId;
    }

    try {
      await _authService.syncCurrentUserProfile(force: true);
    } catch (_) {}

    final refreshedUserId = _authService.currentUserId;
    if (refreshedUserId != null && refreshedUserId > 0) {
      return refreshedUserId;
    }

    return null;
  }
}

class _AssignmentsPagination {
  final int page;
  final int pageCount;
  final int? pageSize;

  const _AssignmentsPagination({
    required this.page,
    required this.pageCount,
    this.pageSize,
  });
}
