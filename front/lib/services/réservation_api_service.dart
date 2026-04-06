import 'dart:convert';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/models/space_model%20plan.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ReservationApiService {
  static const String _baseUrl = 'http://localhost:3001/api';

  AuthService get _auth => Get.find<AuthService>();
  StorageService get _storage => Get.find<StorageService>();

  Map<String, String> get _headers => _auth.authHeaders;

  // ── Nom de l'utilisateur connecté ────────────────────────────────────────
  String get _organizerName {
    try {
      final user = _storage.getUserData();
      if (user != null) {
        final firstName =
            (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
        final lastName =
            (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
        final username =
            (user['username'] ?? user['name'] ?? '').toString().trim();
        final full = '$firstName $lastName'.trim();
        return full.isNotEmpty
            ? full
            : (username.isNotEmpty ? username : 'Utilisateur');
      }
    } catch (_) {}
    return 'Utilisateur';
  }

  // ── Téléphone de l'utilisateur connecté ──────────────────────────────────
  String get _organizerPhone {
    try {
      final user = _storage.getUserData();
      if (user != null) {
        return (user['phone'] ??
                user['phoneNumber'] ??
                user['phone_number'] ??
                user['mobile'] ??
                user['telephone'] ??
                '00000000')
            .toString();
      }
    } catch (_) {}
    return '00000000';
  }

  // ─── Fetch espace par ID ─────────────────────────────────────────────────
  Future<SpaceModel> fetchSpaceById(String id) async {
    final uri = Uri.parse('$_baseUrl/spaces/$id');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final data = body['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Espace "$id" introuvable');
      }
      return SpaceModel.fromJson(data);
    }
    throw Exception('Failed to load space: ${response.statusCode}');
  }

  // ─── Fetch equipment-assets disponibles ──────────────────────────────────
  Future<List<EquipmentModel>> fetchAvailableEquipments() async {
    final uri = Uri.parse(
      '$_baseUrl/equipment-assets'
      '?pagination%5Bpage%5D=1'
      '&pagination%5BpageSize%5D=100'
      '&filters%5Bmystatus%5D%5B%24eq%5D=Disponible'
      '&populate=*'
      '&sort=createdAt%3Adesc',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'] ?? [];
      return data
          .map((e) => EquipmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('Failed to load equipment assets: ${response.statusCode}');
  }

  // ─── Fetch réservations pour une date ────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchReservationsForDate({
    required String spaceId,
    required DateTime date,
  }) async {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '$_baseUrl/reservations'
      '?filters%5Bspace%5D%5Bid%5D%5B%24eq%5D=$spaceId'
      '&filters%5Bstart_datetime%5D%5B%24contains%5D=$dateStr'
      '&populate=*',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'] ?? [];
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  // ─── Créer réservation avec infos utilisateur connecté ───────────────────
  Future<Map<String, dynamic>> createReservationRaw(
      Map<String, dynamic> payload) async {
    // Injecte automatiquement les infos organisateur depuis le user connecté
    final data = payload['data'] as Map<String, dynamic>;
    data['organizer_name'] = _organizerName;
    data['organizer_phone'] = _organizerPhone;

    final uri = Uri.parse('$_baseUrl/reservations');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'data': data}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final body = jsonDecode(response.body);
    throw Exception(
        body['error']?['message'] ?? 'Failed to create reservation');
  }

  // ─── Fetch tous les espaces ───────────────────────────────────────────────
  Future<List<SpaceModel>> fetchSpaces() async {
    final uri = Uri.parse(
      '$_baseUrl/spaces?sort=createdAt%3Adesc&populate=*',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List data = body['data'] ?? [];
      return data.map((e) => SpaceModel.fromJson(e)).toList();
    }
    throw Exception('Failed to load spaces: ${response.statusCode}');
  }
}
