import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AuthService extends GetxService {
  // ✅ Nouveau backend Node.js
  static const String _baseApiUrl = 'http://localhost:3001/api';
  static const Duration _profileSyncTtl = Duration(seconds: 20);

  DateTime? _lastProfileSyncAt;
  Map<String, dynamic>? _cachedProfile;
  Future<Map<String, dynamic>>? _profileSyncFuture;

  final StorageService _storage = Get.find<StorageService>();

  String? get token {
    final raw = _storage.getToken() ??
        _storage.read<String>('jwt') ??
        _storage.read<String>('token');

    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  bool get isLoggedIn => (token ?? '').isNotEmpty;

  Map<String, String> get authHeaders {
    final currentToken = token;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (currentToken != null && currentToken.isNotEmpty)
        'Authorization': 'Bearer $currentToken',
    };
  }

  int? get currentUserId {
    final user = _extractUserMap(_storage.getUserData());
    if (user == null) return null;

    final rawId = user['id'] ?? user['userId'] ?? user['user_id'];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '');
  }

  Future<Map<String, dynamic>?> syncCurrentUserProfile({
    bool force = false,
  }) async {
    if (!isLoggedIn) {
      return null;
    }

    final now = DateTime.now();
    if (!force &&
        _cachedProfile != null &&
        _lastProfileSyncAt != null &&
        now.difference(_lastProfileSyncAt!) < _profileSyncTtl) {
      return Map<String, dynamic>.from(_cachedProfile!);
    }

    if (!force && _profileSyncFuture != null) {
      return Map<String, dynamic>.from(await _profileSyncFuture!);
    }

    final syncFuture = _fetchCurrentUserProfile();
    _profileSyncFuture = syncFuture;

    try {
      final profile = await syncFuture;
      _cachedProfile = Map<String, dynamic>.from(profile);
      _lastProfileSyncAt = DateTime.now();
      return Map<String, dynamic>.from(profile);
    } finally {
      if (identical(_profileSyncFuture, syncFuture)) {
        _profileSyncFuture = null;
      }
    }
  }

  Future<Map<String, dynamic>> _fetchCurrentUserProfile() async {
    final response = await http.get(
      Uri.parse('$_baseApiUrl/users/me?populate=role'),
      headers: authHeaders,
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_statusMessage(response.statusCode, decoded));
    }

    final profile = _extractUserMap(decoded);
    if (profile == null) {
      throw Exception('Profil utilisateur invalide');
    }

    await _storage.saveUserData(profile);
    await _storage.write('user_data', profile);
    await _storage.write('user', profile);
    return profile;
  }

  Map<String, dynamic>? _extractUserMap(dynamic source) {
    if (source == null) return null;

    if (source is Map) {
      final map = Map<String, dynamic>.from(source);

      final directId = map['id'] ?? map['userId'] ?? map['user_id'];
      if (directId != null && directId.toString().trim().isNotEmpty) {
        return map;
      }

      final nestedData = map['data'];
      final fromData = _extractUserMap(nestedData);
      if (fromData != null) return fromData;

      final nestedUser = map['user'];
      final fromUser = _extractUserMap(nestedUser);
      if (fromUser != null) return fromUser;
    }

    if (source is List) {
      for (final item in source) {
        final found = _extractUserMap(item);
        if (found != null) return found;
      }
    }

    return null;
  }

  Future<Map<String, dynamic>> updateUserById({
    required int userId,
    required Map<String, dynamic> payload,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseApiUrl/users/$userId'),
      headers: authHeaders,
      body: jsonEncode(payload),
    );

    final decoded = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_statusMessage(response.statusCode, decoded));
    }

    Map<String, dynamic> updated;
    final cached = _storage.getUserData() ?? <String, dynamic>{};
    final raw = decoded['data'] ?? decoded;
    if (raw is Map) {
      updated = Map<String, dynamic>.from(cached)
        ..addAll(Map<String, dynamic>.from(raw));
    } else {
      updated = Map<String, dynamic>.from(cached)..addAll(payload);
    }

    await _storage.saveUserData(updated);
    await _storage.write('user_data', updated);
    await _storage.write('user', updated);

    _cachedProfile = Map<String, dynamic>.from(updated);
    _lastProfileSyncAt = DateTime.now();

    return updated;
  }

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final normalized = identifier.trim();
    final payload = {
      'identifier': normalized,
      'password': password,
      if (normalized.contains('@')) 'email': normalized,
      if (!normalized.contains('@')) 'username': normalized,
    };

    print('📡 POST /auth/local');

    final response = await http.post(
      Uri.parse('$_baseApiUrl/auth/local'),
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(payload),
    );

    print('✅ Réponse /auth/local: ${response.statusCode}');

    final decoded = _decodeBody(response.body);
    if (response.statusCode == 200) {
      final jwt = ((decoded['jwt'] ??
                  (decoded['data'] is Map
                      ? (decoded['data'] as Map)['jwt']
                      : null)) ??
              '')
          .toString()
          .trim();
      if (jwt.isEmpty) {
        throw Exception('JWT manquant dans la réponse de connexion');
      }

      await _storage.saveToken(jwt);
      await _storage.write('jwt', jwt);
      await _storage.write('token', jwt);

      final user = _extractUserMap(decoded);
      if (user != null) {
        await _storage.saveUserData(user);
      }

      return jwt;
    }

    throw Exception(_statusMessage(response.statusCode, decoded));
  }

  Future<void> logout() async {
    await _storage.logout();
    if (Get.currentRoute != Routes.LOGIN) {
      Get.offAllNamed(Routes.LOGIN);
    }
  }

  void handleUnauthorized() {
    print('❌ 401 Unauthorized → redirection /login');
    logout();
  }

  Map<String, dynamic> _decodeBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _statusMessage(int statusCode, Map<String, dynamic> body) {
    final strapiMsg = body['error']?['message']?.toString() ??
        body['message']?.toString() ??
        'Erreur inconnue';

    if (statusCode == 401) return 'Identifiants invalides';
    if (statusCode == 403) return 'Accès interdit';
    if (statusCode == 404) return 'Ressource introuvable';
    if (statusCode == 422) return strapiMsg;
    if (statusCode >= 500) return 'Erreur serveur';
    return strapiMsg;
  }
}
