import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CommunicationApi {
  static const String _baseUrl = 'http://localhost:3001/api/communication';

  final AuthService _auth = Get.find<AuthService>();

  Future<List<Map<String, dynamic>>> getRecipients({String type = ''}) async {
    final uri = Uri.parse('$_baseUrl/recipients')
        .replace(queryParameters: type.trim().isEmpty ? null : {'type': type});
    final response = await http.get(uri, headers: _auth.authHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible de charger les destinataires'));
  }

  Future<List<Map<String, dynamic>>> getMessages({String box = 'inbox'}) async {
    final uri = Uri.parse('$_baseUrl/messages').replace(queryParameters: {
      'box': box,
      'take': '50',
    });
    final response = await http.get(uri, headers: _auth.authHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible de charger les messages'));
  }

  Future<void> sendMessage({
    required int recipientId,
    required String body,
    String? subject,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: _auth.authHeaders,
      body: jsonEncode({
        'recipientId': recipientId,
        if (subject != null && subject.trim().isNotEmpty)
          'subject': subject.trim(),
        'body': body.trim(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          _extractErrorMessage(response.body, 'Échec de l’envoi du message'));
    }
  }

  Future<List<Map<String, dynamic>>> getThreads() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/forum/threads?take=50'),
      headers: _auth.authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible de charger les discussions'));
  }

  Future<void> createThread({
    required String title,
    required String body,
    required List<String> tags,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forum/threads'),
      headers: _auth.authHeaders,
      body: jsonEncode({
        'title': title.trim(),
        'body': body.trim(),
        'tags': tags,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(
          response.body, 'Impossible de publier la discussion'));
    }
  }

  Future<void> replyToThread(
      {required int threadId, required String body}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forum/threads/$threadId/replies'),
      headers: _auth.authHeaders,
      body: jsonEncode({'body': body.trim()}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(
          response.body, 'Impossible de répondre à la discussion'));
    }
  }

  Future<List<Map<String, dynamic>>> getSimilarThreads(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return const <Map<String, dynamic>>[];

    final uri = Uri.parse('$_baseUrl/forum/threads/similar')
        .replace(queryParameters: {'q': normalized});
    final response = await http.get(uri, headers: _auth.authHeaders);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible de rechercher les discussions similaires'));
  }

  Future<Map<String, dynamic>> improvePostDraft({
    required String title,
    required String body,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forum/assistant/improve'),
      headers: _auth.authHeaders,
      body: jsonEncode({
        'title': title,
        'body': body,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['data'] is Map) {
        return Map<String, dynamic>.from(decoded['data'] as Map);
      }
      return const <String, dynamic>{};
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible d’améliorer le brouillon'));
  }

  Future<void> updateThreadStatus({
    required int threadId,
    required String status,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/forum/threads/$threadId/status'),
      headers: _auth.authHeaders,
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Impossible de changer le statut'),
      );
    }
  }

  Future<void> validateReply({required int replyId}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forum/replies/validate'),
      headers: _auth.authHeaders,
      body: jsonEncode({'replyId': replyId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Impossible de valider la réponse'),
      );
    }
  }

  Future<void> reactToReply({
    required int replyId,
    required String reactionType,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forum/replies/reaction'),
      headers: _auth.authHeaders,
      body: jsonEncode({
        'replyId': replyId,
        'reactionType': reactionType,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        _extractErrorMessage(response.body, 'Impossible d’ajouter la réaction'),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getForumNotifications() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/forum/notifications?take=20'),
      headers: _auth.authHeaders,
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final decoded = jsonDecode(response.body);
      final items = decoded is Map<String, dynamic> && decoded['data'] is List
          ? decoded['data'] as List<dynamic>
          : <dynamic>[];
      return items
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(_extractErrorMessage(
        response.body, 'Impossible de charger les notifications forum'));
  }

  String _extractErrorMessage(String rawBody, String fallback) {
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map) {
        return (decoded['message'] ?? decoded['error']?.toString() ?? fallback)
            .toString();
      }
    } catch (_) {}
    return fallback;
  }
}
