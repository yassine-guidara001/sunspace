import 'dart:convert';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ReservationsService {
  static const String baseUrl = 'http://localhost:3001/api';

  Map<String, String> get _headers {
    try {
      final auth = Get.find<AuthService>();
      return auth.authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  // ─── GET reservations ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getReservations() async {
    final uri = Uri.parse(
      '$baseUrl/reservations'
      '?populate[space][populate]=*'
      '&populate[user][fields]=username,email'
      '&sort=createdAt:desc'
      '&pagination[pageSize]=100',
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Failed to load reservations: ${response.statusCode}');
  }

  // ─── PUT — update status par documentId ──────────────────────────────────
  Future<void> updateReservationStatus(String documentId, String status) async {
    final uri = Uri.parse('$baseUrl/reservations/$documentId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'data': {'mystatus': _toApiStatus(status)}
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update reservation: ${response.statusCode}');
    }
  }

  // ─── DELETE par documentId ────────────────────────────────────────────────
  Future<void> deleteReservation(String documentId) async {
    final uri = Uri.parse('$baseUrl/reservations/$documentId');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reservation: ${response.statusCode}');
    }
  }

  String _toApiStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s.contains('attente')) return 'En_attente';
    if (s.contains('confirm')) return 'Confirmée';
    if (s.contains('annul')) return 'Annulée';
    return status;
  }
}
