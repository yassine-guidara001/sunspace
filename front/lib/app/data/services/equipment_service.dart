import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment_model.dart';

class EquipmentService {
  final String baseUrl = "http://localhost:3001/api/equipment-assets";

  final String? token;

  EquipmentService(this.token);

  String? get _normalizedToken {
    final raw = token?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.toLowerCase().startsWith('bearer ')) {
      return raw.substring(7).trim();
    }
    return raw;
  }

  Map<String, String> get headersGet => {
        "Accept": "application/json",
        if (_normalizedToken != null)
          "Authorization": "Bearer $_normalizedToken",
      };

  Map<String, String> get headersJson => {
        "Content-Type": "application/json",
        "Accept": "application/json",
        if (_normalizedToken != null)
          "Authorization": "Bearer $_normalizedToken",
      };

  Map<String, String> get headersJsonWithoutAuth => {
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

  Uri _collectionUri({Map<String, String>? queryParameters}) {
    return Uri.parse(baseUrl).replace(queryParameters: queryParameters);
  }

  Uri _itemUri(String documentId) {
    final encoded = Uri.encodeComponent(documentId.trim());
    return Uri.parse("$baseUrl/$encoded");
  }

  Uri _itemUriById(int id) {
    return Uri.parse("$baseUrl/$id");
  }

  bool _isSuccess(int statusCode) {
    return statusCode == 200 || statusCode == 201 || statusCode == 204;
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final err = decoded['error'];
        if (err is Map<String, dynamic>) {
          final msg = err['message'];
          if (msg != null) return msg.toString();
        }
        final msg = decoded['message'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {}

    return response.body;
  }

  Map<String, dynamic> _extractData(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is Map<String, dynamic>) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  /// ===============================
  /// GET ALL
  /// ===============================
  Future<List<Equipment>> fetchEquipments() async {
    final uri = Uri.parse(
        '$baseUrl?pagination[page]=1&pagination[pageSize]=100&populate=*&sort=createdAt:desc');
    http.Response response = await http.get(uri, headers: headersGet);

    if (response.statusCode != 200 && headersGet.containsKey('Authorization')) {
      final retryWithoutAuth = await http.get(uri, headers: const {
        'Accept': 'application/json',
      });

      if (retryWithoutAuth.statusCode == 200) {
        response = retryWithoutAuth;
      }
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body is Map<String, dynamic> ? body['data'] as List? : null;

      if (data == null) return <Equipment>[];
      return data
          .whereType<Map<String, dynamic>>()
          .map(Equipment.fromJson)
          .toList();
    }

    throw Exception(
      "GET Error: ${response.statusCode} ${_errorMessage(response)}",
    );
  }

  /// ===============================
  /// ADD
  /// ===============================
  Future<void> addEquipment(Equipment equipment) async {
    final basePayload = equipment.toJson();
    final fullData = _extractData(basePayload);

    final payload = jsonEncode({'data': fullData});

    final response = await http.post(
      _collectionUri(),
      headers: headersJson,
      body: payload,
    );

    if (_isSuccess(response.statusCode)) {
      return;
    }

    throw Exception(
      "POST Error: ${response.statusCode} ${_errorMessage(response)}",
    );
  }

  /// ===============================
  /// UPDATE (Strapi v5 => documentId)
  /// ===============================
  Future<void> updateEquipment(Equipment equipment) async {
    final raw = equipment.toJson();
    final rawData = raw['data'];
    final payloadData = rawData is Map<String, dynamic>
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    payloadData.remove('technical_issues');
    payloadData.remove('reservations');
    payloadData.remove('localizations');
    payloadData.remove('locale');

    final payload = jsonEncode({'data': payloadData});

    final candidateUris = <Uri>[
      if (equipment.documentId.trim().isNotEmpty)
        _itemUri(equipment.documentId),
      if (equipment.id > 0) _itemUriById(equipment.id),
    ];

    if (candidateUris.isEmpty) {
      throw Exception("PUT Error: identifiant équipement manquant");
    }

    http.Response? lastResponse;

    for (final uri in candidateUris) {
      final response = await http.put(uri, headers: headersJson, body: payload);
      lastResponse = response;

      if (_isSuccess(response.statusCode)) {
        return;
      }
    }

    if (lastResponse != null) {
      throw Exception(
        "PUT Error: ${lastResponse.statusCode} ${_errorMessage(lastResponse)}",
      );
    }

    throw Exception("PUT Error: aucune réponse serveur");
  }

  /// ===============================
  /// DELETE
  /// ===============================
  Future<void> deleteEquipment(String documentId) async {
    final trimmedDocumentId = documentId.trim();
    if (trimmedDocumentId.isEmpty) {
      throw Exception(
        "DELETE Error: identifiant équipement manquant",
      );
    }

    final response = await http.delete(
      _itemUri(trimmedDocumentId),
      headers: headersGet,
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception(
          "DELETE Error: ${response.statusCode} ${_errorMessage(response)}");
    }
  }
}
