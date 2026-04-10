import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/association_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AssociationsService {
  static const String _baseApiUrl = 'http://localhost:3001/api';

  final AuthService _authService;

  AssociationsService({AuthService? authService})
      : _authService = authService ?? Get.find<AuthService>();

  /// Charge les associations dont l'utilisateur est admin OU membre.
  /// Correspond aux deux requêtes visibles dans les DevTools :
  ///   GET /associations?filters[admin][id][$eq]={userId}&populate=*
  ///   GET /associations?filters[members][id][$in]={userId}&populate=*
  Future<List<AssociationModel>> loadAssociationsByUserId(int userId) async {
    final headers = _authService.authHeaders;

    final adminUri = Uri.parse(
      '$_baseApiUrl/associations?filters[admin][id][\$eq]=$userId&populate=*',
    );
    final memberUri = Uri.parse(
      '$_baseApiUrl/associations?filters[members][id][\$in]=$userId&populate=*',
    );

    final responses = await Future.wait([
      http.get(adminUri, headers: headers),
      http.get(memberUri, headers: headers),
    ]);

    // Fusionne et déduplique par documentId.
    final seen = <String, AssociationModel>{};
    for (final response in responses) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (final model in _parseAssociations(response.body)) {
          seen.putIfAbsent(model.documentId, () => model);
        }
      }
    }

    return seen.values.toList();
  }

  Future<AssociationsLoadResult> loadAssociationsAndUsers() async {
    final associationsUri =
        Uri.parse('$_baseApiUrl/associations?populate=*&sort=name:asc');
    final usersUri = Uri.parse('$_baseApiUrl/users?populate=*');
    final headers = _authService.authHeaders;

    final responses = await Future.wait([
      http.get(associationsUri, headers: headers),
      http.get(usersUri, headers: headers),
    ]);

    final associationsResponse = responses[0];
    final usersResponse = responses[1];

    if (associationsResponse.statusCode < 200 ||
        associationsResponse.statusCode >= 300) {
      throw Exception(_extractErrorMessage(associationsResponse));
    }

    if (usersResponse.statusCode < 200 || usersResponse.statusCode >= 300) {
      throw Exception(_extractErrorMessage(usersResponse));
    }

    final associations = _parseAssociations(associationsResponse.body).toList();
    final users = _parseUsers(usersResponse.body).toList();

    return AssociationsLoadResult(
      associations: associations,
      users: users,
    );
  }

  Future<void> createAssociation(AssociationFormPayload payload) async {
    final response = await http.post(
      Uri.parse('$_baseApiUrl/associations'),
      headers: _authService.authHeaders,
      body: jsonEncode({'data': payload.toStrapiData()}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> updateAssociation(
    String documentId,
    AssociationFormPayload payload,
  ) async {
    final docId = documentId.trim();
    if (docId.isEmpty) {
      throw Exception('documentId manquant pour la modification');
    }

    final response = await http.put(
      Uri.parse('$_baseApiUrl/associations/${Uri.encodeComponent(docId)}'),
      headers: _authService.authHeaders,
      body: jsonEncode({'data': payload.toStrapiData()}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<List<UserOption>> getAssociationMembers(String documentId) async {
    final docId = documentId.trim();
    if (docId.isEmpty) {
      throw Exception('documentId manquant pour charger les membres');
    }

    final response = await http.get(
      Uri.parse(
          '$_baseApiUrl/associations/${Uri.encodeComponent(docId)}?populate=*'),
      headers: _authService.authHeaders,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response));
    }

    final decoded = _decodeJson(response.body);
    final raw = _extractDataMap(decoded);
    final attrs = _extractAttributes(raw);
    final rawMembers = attrs['members'] ?? raw['members'];

    if (rawMembers is! List) return const <UserOption>[];

    final members = <UserOption>[];
    for (final item in rawMembers) {
      final user = _asMap(item);
      final userAttrs = _extractAttributes(user);
      final id = _toInt(user['id'] ?? userAttrs['id']);
      if (id <= 0) continue;

      final name = _firstNonEmpty([
        userAttrs['username'],
        userAttrs['name'],
        userAttrs['fullName'],
      ], fallback: 'Utilisateur');

      final email = _firstNonEmpty([userAttrs['email']]);
      members.add(UserOption(id: id, name: name, email: email));
    }

    return members;
  }

  Future<void> updateAssociationMembers(
    String documentId,
    List<int> memberIds,
  ) async {
    final docId = documentId.trim();
    if (docId.isEmpty) {
      throw Exception('documentId manquant pour modifier les membres');
    }

    final response = await http.put(
      Uri.parse('$_baseApiUrl/associations/${Uri.encodeComponent(docId)}'),
      headers: _authService.authHeaders,
      body: jsonEncode({
        'data': {
          'members': memberIds,
        }
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Future<void> deleteAssociation(String documentId) async {
    final docId = documentId.trim();
    if (docId.isEmpty) {
      throw Exception('documentId manquant pour la suppression');
    }

    final response = await http.delete(
      Uri.parse('$_baseApiUrl/associations/${Uri.encodeComponent(docId)}'),
      headers: _authService.authHeaders,
    );

    if (response.statusCode != 200 &&
        response.statusCode != 202 &&
        response.statusCode != 204) {
      throw Exception(_extractErrorMessage(response));
    }
  }

  Iterable<AssociationModel> _parseAssociations(String body) {
    final decoded = _decodeJson(body);
    final items = _extractDataList(decoded);

    return items.map((item) {
      final raw = _asMap(item);
      final attrs = _extractAttributes(raw);

      final id = _toInt(raw['id'] ?? attrs['id']);
      final documentId = _firstNonEmpty([
        raw['documentId'],
        raw['document_id'],
        attrs['documentId'],
        attrs['document_id'],
      ], fallback: '$id');

      final name = _firstNonEmpty([
        attrs['name'],
        attrs['title'],
        attrs['label'],
      ], fallback: 'association');

      final description = _firstNonEmpty([attrs['description']]);
      final email = _firstNonEmpty([attrs['email'], attrs['contact_email']]);
      final phone = _firstNonEmpty([attrs['phone'], attrs['telephone']]);
      final website = _firstNonEmpty([
        attrs['website'],
        attrs['site'],
        attrs['site_web'],
      ]);

      final adminPrimary = _extractRelationMap(attrs['admin']);
      final adminRelation = adminPrimary.isNotEmpty
          ? adminPrimary
          : _extractRelationMap(attrs['administrator']);
      final adminAttrs = _extractAttributes(adminRelation);
      final adminName = _firstNonEmpty([
        adminAttrs['username'],
        adminAttrs['name'],
        adminAttrs['fullName'],
      ], fallback: 'Pas d\'admin');
      final adminEmail = _firstNonEmpty([adminAttrs['email']]);
      final adminId = _toInt(adminRelation['id'] ?? adminAttrs['id']);

      final budgetRaw =
          attrs['budget'] ?? attrs['budget_initial'] ?? attrs['initial_budget'];
      final budget = _toDouble(budgetRaw);
      final currency = _firstNonEmpty([attrs['currency']], fallback: 'TND');
      final budgetLabel =
          '${budget.toStringAsFixed(budget % 1 == 0 ? 0 : 2)} $currency';

      final verified = _toBool(
        attrs['verified'] ??
            attrs['is_verified'] ??
            attrs['isVerified'] ??
            attrs['status'] == 'verified',
      );

      final membersCount = _extractMembersCount(attrs);

      return AssociationModel(
        id: id,
        documentId: documentId,
        name: name,
        description: description,
        email: email,
        phone: phone,
        website: website,
        adminName: adminName,
        adminEmail: adminEmail,
        adminId: adminId > 0 ? adminId : null,
        budgetValue: budget,
        currency: currency,
        budgetLabel: budgetLabel,
        verified: verified,
        membersCount: membersCount,
      );
    });
  }

  Iterable<UserOption> _parseUsers(String body) {
    final decoded = _decodeJson(body);
    final items = _extractDataList(decoded);

    return items.map((item) {
      final raw = _asMap(item);
      final attrs = _extractAttributes(raw);

      final id = _toInt(raw['id'] ?? attrs['id']);
      final username = _firstNonEmpty([
        attrs['username'],
        attrs['name'],
        attrs['fullName'],
      ], fallback: 'Utilisateur');
      final email = _firstNonEmpty([attrs['email']]);

      return UserOption(id: id, name: username, email: email);
    });
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

  Map<String, dynamic> _extractDataMap(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return decoded;
    }
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return <String, dynamic>{};
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

  int _extractMembersCount(Map<String, dynamic> attrs) {
    final candidates = [
      attrs['members'],
      attrs['users'],
      attrs['member_users'],
    ];

    for (final candidate in candidates) {
      if (candidate is int) return candidate;
      if (candidate is List) return candidate.length;
      if (candidate is Map) {
        final data = candidate['data'];
        if (data is List) return data.length;
      }
    }

    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) return value;
    final normalized = ('$value').trim().toLowerCase();
    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'verified';
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
