import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../models/space_model.dart';

class SpaceApi {
  // ✅ Nouveau backend Node.js
  static const String baseUrl = 'http://localhost:3001/api';

  final StorageService _storageService;

  // Singleton instance
  static SpaceApi? _instance;

  SpaceApi._({StorageService? storageService})
      : _storageService = storageService ?? Get.find<StorageService>();

  // Obtain singleton instance
  factory SpaceApi() {
    _instance ??= SpaceApi._(storageService: Get.find<StorageService>());
    return _instance!;
  }

  Map<String, String> _headersJson() {
    final token = _readToken();
    if (token == null || token.isEmpty) {
      throw Exception('Auth Error: token JWT manquant');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
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

    return normalized;
  }

  bool _isSuccess(int statusCode) => statusCode >= 200 && statusCode < 300;

  /// GET /api/spaces - Récupérer tous les espaces
  Future<List<Space>> _getSpaces() async {
    final response = await http.get(
      Uri.parse('$baseUrl/spaces'),
      headers: _headersJson(),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      // Format Node.js: {statusCode, message, success, data: [...]}
      if (decoded is Map && decoded['data'] is List) {
        final spacesList = (decoded['data'] as List)
            .whereType<Map>()
            .map((e) => _normalizeSpaceMap(Map<String, dynamic>.from(e)))
            .map(Space.fromJson)
            .toList();
        return spacesList;
      }

      // Format Strapi ancien: directement une liste
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => _normalizeSpaceMap(Map<String, dynamic>.from(e)))
            .map(Space.fromJson)
            .toList();
      }

      return <Space>[];
    }

    throw Exception(
        'Erreur lors de la récupération des espaces: ${response.statusCode}');
  }

  /// GET /api/spaces/:id - Récupérer un espace par ID
  Future<Space> _getSpace(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/spaces/$id'),
      headers: _headersJson(),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      // Format Node.js: {statusCode, message, success, data: space}
      if (decoded is Map && decoded['data'] is Map) {
        return Space.fromJson(
          _normalizeSpaceMap(Map<String, dynamic>.from(decoded['data'])),
        );
      }

      // Format ancien
      return Space.fromJson(_normalizeSpaceMap(decoded));
    }

    throw Exception('Espace non trouvé');
  }

  /// POST /api/spaces - Créer un espace
  Future<Space> _createSpace(Space space) async {
    final payload = _buildSpacePayload(space);

    print('📤 [CREATE_SPACE] Payload: $payload');

    final response = await http.post(
      Uri.parse('$baseUrl/spaces'),
      headers: _headersJson(),
      body: jsonEncode(payload),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      // Format Node.js: {statusCode, message, success, data: space}
      if (decoded is Map && decoded['data'] is Map) {
        return Space.fromJson(
          _normalizeSpaceMap(Map<String, dynamic>.from(decoded['data'])),
        );
      }

      // Format ancien: directement l'espace
      return Space.fromJson(_normalizeSpaceMap(decoded));
    }

    throw Exception('Erreur création espace: ${response.statusCode}');
  }

  /// PUT /api/spaces/:id - Mettre à jour un espace
  Future<Space> _updateSpace(Space space) async {
    if (space.id == 0) {
      throw Exception('ID espace manquant');
    }

    final payload = _buildSpacePayload(space);

    print('📤 [UPDATE_SPACE] Payload: $payload');

    final response = await http.put(
      Uri.parse('$baseUrl/spaces/${space.id}'),
      headers: _headersJson(),
      body: jsonEncode(payload),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      // Format Node.js: {statusCode, message, success, data: space}
      if (decoded is Map && decoded['data'] is Map) {
        return Space.fromJson(
          _normalizeSpaceMap(Map<String, dynamic>.from(decoded['data'])),
        );
      }

      // Format ancien
      return Space.fromJson(_normalizeSpaceMap(decoded));
    }

    throw Exception('Erreur mise à jour espace: ${response.statusCode}');
  }

  /// DELETE /api/spaces/:id - Supprimer un espace
  Future<void> _deleteSpace(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/spaces/$id'),
      headers: _headersJson(),
    );

    if (!_isSuccess(response.statusCode)) {
      throw Exception('Erreur suppression espace: ${response.statusCode}');
    }
  }

  /// Construire le payload pour créer/mettre à jour un espace
  Map<String, dynamic> _buildSpacePayload(Space space) {
    return {
      'name': space.name.trim(),
      'type': space.type,
      'description': space.description,
      'location': space.location,
      'floor': space.floor,
      'capacity': space.capacity,
      'surface': space.surface ?? space.area,
      'width': space.width ?? space.svgWidth,
      'height': space.height ?? space.svgHeight,
      'status': space.status,
      'hourlyRate': space.hourlyRate,
      'dailyRate': space.dailyRate,
      'monthlyRate': space.monthlyRate,
      'overtimeRate': space.overtimeRate,
      'currency': space.currency,
      'isCoworkingSpace': space.isCoworkingSpace || space.isCoworking,
      'allowLimitedReservations':
          space.allowLimitedReservations || space.allowGuestReservations,
      'available24h': space.available24h,
      'features': space.features,
      'imageUrl': space.imageUrl,
    };
  }

  /// Normaliser les données d'espace du backend
  Map<String, dynamic> _normalizeSpaceMap(Map<String, dynamic> spaceMap) {
    return spaceMap;
  }

  // ==================== STATIC WRAPPERS ====================

  /// Static wrapper: GET /api/spaces
  static Future<List<Space>> getSpaces({
    bool forceRefresh = false,
    bool populate = false,
  }) async {
    return SpaceApi()._getSpaces();
  }

  /// Static wrapper: GET /api/spaces/:id
  static Future<Space> getSpace(int id) async {
    return SpaceApi()._getSpace(id);
  }

  /// Static wrapper: POST /api/spaces
  /// Accepte soit une Space, soit un Map<String, dynamic>
  static Future<Space> createSpace(dynamic data) async {
    late Space space;
    if (data is Space) {
      space = data;
    } else if (data is Map<String, dynamic>) {
      space = Space.fromJson(data);
    } else {
      throw Exception(
          'Type non supporté pour createSpace: ${data.runtimeType}');
    }
    return SpaceApi()._createSpace(space);
  }

  /// Static wrapper: PUT /api/spaces/:id
  /// Accepte documentId (String ou int) et data (Map ou Space)
  static Future<Space> updateSpace(dynamic documentId, dynamic data) async {
    late Space space;
    if (data is Space) {
      space = data;
    } else if (data is Map<String, dynamic>) {
      space = Space.fromJson(data);
    } else {
      throw Exception(
          'Type non supporté pour updateSpace data: ${data.runtimeType}');
    }

    // Convertir documentId en int si besoin
    late int id;
    if (documentId is int) {
      id = documentId;
    } else if (documentId is String) {
      id = int.tryParse(documentId) ?? 0;
    } else {
      throw Exception('DocumentId doit être int ou String');
    }

    // Si l'id parsed est 0, utiliser space.id
    if (id == 0 && space.id != 0) {
      id = space.id;
    }

    space = Space(
      id: id,
      documentId: space.documentId,
      name: space.name,
      slug: space.slug,
      type: space.type,
      location: space.location,
      floor: space.floor,
      capacity: space.capacity,
      area: space.area,
      svgWidth: space.svgWidth,
      svgHeight: space.svgHeight,
      status: space.status,
      isCoworking: space.isCoworking,
      allowGuestReservations: space.allowGuestReservations,
      hourlyRate: space.hourlyRate,
      dailyRate: space.dailyRate,
      monthlyRate: space.monthlyRate,
      overtimeRate: space.overtimeRate,
      currency: space.currency,
      description: space.description,
      available24h: space.available24h,
      isCoworkingSpace: space.isCoworkingSpace,
      allowLimitedReservations: space.allowLimitedReservations,
      surface: space.surface,
      width: space.width,
      height: space.height,
      features: space.features,
      imageUrl: space.imageUrl,
      createdAt: space.createdAt,
      updatedAt: space.updatedAt,
    );

    return SpaceApi()._updateSpace(space);
  }

  /// Static wrapper: DELETE /api/spaces/:id
  static Future<void> deleteSpace(String docId) async {
    final id = int.tryParse(docId) ?? 0;
    return SpaceApi()._deleteSpace(id);
  }
}
