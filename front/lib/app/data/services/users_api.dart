import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/models/user_model.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class UsersApi {
  // ✅ Nouveau backend Node.js
  static const String baseUrl = 'http://localhost:3001/api';

  final StorageService _storageService;

  UsersApi({StorageService? storageService})
      : _storageService = storageService ?? Get.find<StorageService>();

  Future<String> login({
    required String identifier,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/local');
    final response = await http.post(
      uri,
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
      final decoded = _decodeMap(response.body);
      final token = (decoded['jwt'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Auth Error: token JWT manquant dans la réponse');
      }

      await _storageService.saveToken(token);
      await _storageService.write('jwt', token);
      await _storageService.write('token', token);

      return token;
    }

    throw _buildHttpException('LOGIN', response);
  }

  Future<List<User>> getUsers() async {
    // 🔗 Appel au nouveau backend Node.js
    http.Response response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headersJson(),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = jsonDecode(response.body);

      // Format Node.js: {statusCode, message, success, data: [...]}
      if (decoded is Map && decoded['data'] is List) {
        final usersList = (decoded['data'] as List)
            .whereType<Map>()
            .map((e) => _normalizeUserMap(Map<String, dynamic>.from(e)))
            .map(User.fromJson)
            .toList();
        return usersList;
      }

      // Format Strapi ancien: directement une liste
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => _normalizeUserMap(Map<String, dynamic>.from(e)))
            .map(User.fromJson)
            .toList();
      }

      return <User>[];
    }

    throw _buildHttpException('GET_USERS', response);
  }

  Future<User> createUser(User user, {String? password}) async {
    final payload = await _buildUserPayload(
      user: user,
      password: password,
      includeRole: true,
    );

    print('📤 [CREATE_USER] Payload: ${_maskSensitivePayload(payload)}');

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headersJson(),
      body: jsonEncode(payload),
    );

    if (_isSuccess(response.statusCode)) {
      final decoded = _decodeMap(response.body);

      // Format Node.js: {statusCode, message, success, data: user}
      if (decoded['data'] is Map) {
        return User.fromJson(
            _normalizeUserMap(Map<String, dynamic>.from(decoded['data'])));
      }

      // Format Strapi ancien: directement l'utilisateur
      return User.fromJson(_normalizeUserMap(decoded));
    }

    throw _buildHttpException('CREATE_USER', response);
  }

  Future<User> updateUser(User user, {String? password}) async {
    final payload = await _buildUserPayload(
      user: user,
      password: password,
      includeRole: true,
    );

    print('📤 [UPDATE_USER] Payload: ${_maskSensitivePayload(payload)}');

    http.Response response = await http.put(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: _headersJson(),
      body: jsonEncode(payload),
    );

    if (!_isSuccess(response.statusCode) &&
        response.statusCode >= 500 &&
        payload.containsKey('role')) {
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('role');

      print(
        '⚠️ [UPDATE_USER] Retry sans role après ${response.statusCode}: '
        '${_maskSensitivePayload(fallbackPayload)}',
      );

      response = await http.put(
        Uri.parse('$baseUrl/users/${user.id}'),
        headers: _headersJson(),
        body: jsonEncode(fallbackPayload),
      );
    }

    if (_isSuccess(response.statusCode)) {
      if (response.body.trim().isEmpty) {
        return user;
      }

      final decoded = _decodeMap(response.body);

      // Format Node.js: {statusCode, message, success, data: user}
      if (decoded['data'] is Map) {
        return User.fromJson(
            _normalizeUserMap(Map<String, dynamic>.from(decoded['data'])));
      }

      // Format Strapi ancien: directement l'utilisateur
      return User.fromJson(_normalizeUserMap(decoded));
    }

    throw _buildHttpException('UPDATE_USER', response);
  }

  Future<void> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: _headersJson(),
    );

    if (_isSuccess(response.statusCode)) {
      return;
    }

    throw _buildHttpException('DELETE_USER', response);
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

  Future<Map<String, dynamic>> _buildUserPayload({
    required User user,
    String? password,
    required bool includeRole,
  }) async {
    final payload = <String, dynamic>{
      'username': user.username.trim(),
      'email': user.email.trim(),
      'confirmed': user.confirmed,
      'blocked': user.blocked,
    };

    final cleanPassword = password?.trim();
    if (cleanPassword != null && cleanPassword.isNotEmpty) {
      payload['password'] = cleanPassword;
    }

    if (includeRole) {
      // ✅ Accepter anciens rôles Strapi (Authenticated, Admin, Etudiant, etc.)
      final roleName = user.role.trim();
      const validRoles = [
        'Authenticated',
        'Public',
        'SUPER_ADMIN',
        'Etudiant',
        'Enseignant',
        "Gestionnaire d'espace",
        'Admin',
        'Professionnel',
        'Association',
        'USER'
      ];

      // Seulement envoyer le rôle s'il est valide et non vide
      if (roleName.isNotEmpty && validRoles.contains(roleName)) {
        payload['role'] = roleName;
      }
      // Sinon ne pas envoyer - Joi appliquera le default 'USER'
    }

    return payload;
  }

  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> userMap) {
    final normalized = Map<String, dynamic>.from(userMap);
    final role = normalized['role'];

    if (role is Map) {
      final roleMap = Map<String, dynamic>.from(role);

      final directName = roleMap['name'] ?? roleMap['type'];
      if (directName != null && directName.toString().trim().isNotEmpty) {
        normalized['role'] = directName.toString().trim();
        return normalized;
      }

      final directAttributes = roleMap['attributes'];
      if (directAttributes is Map) {
        final attrMap = Map<String, dynamic>.from(directAttributes);
        final attrName = attrMap['name'] ?? attrMap['type'];
        if (attrName != null && attrName.toString().trim().isNotEmpty) {
          normalized['role'] = attrName.toString().trim();
          return normalized;
        }
      }

      // final directId = roleMap['id'];
      // if (directId is num) {
      //   final roleName = _rolesByIdCache?[directId.toInt()];
      //   if (roleName != null && roleName.trim().isNotEmpty) {
      //     normalized['role'] = roleName;
      //     return normalized;
      //   }
      // }
    }

    if (role is Map) {
      final roleMap = Map<String, dynamic>.from(role);
      final data = roleMap['data'];
      if (data is Map) {
        final dataMap = Map<String, dynamic>.from(data);
        final attributes = dataMap['attributes'];

        if (attributes is Map) {
          final attrMap = Map<String, dynamic>.from(attributes);
          final roleName = attrMap['name'] ?? attrMap['type'];
          if (roleName != null && roleName.toString().trim().isNotEmpty) {
            normalized['role'] = roleName.toString().trim();
            return normalized;
          }
        }

        final roleName = dataMap['name'] ?? dataMap['type'];
        if (roleName != null && roleName.toString().trim().isNotEmpty) {
          normalized['role'] = roleName.toString().trim();
          return normalized;
        }
      }
    }

    // if (role is num) {
    //   final roleName = _rolesByIdCache?[role.toInt()];
    //   if (roleName != null && roleName.trim().isNotEmpty) {
    //     normalized['role'] = roleName;
    //   } else {
    //     normalized['role'] = 'Role ${role.toInt()}';
    //   }
    // }

    return normalized;
  }

  Map<String, dynamic> _maskSensitivePayload(Map<String, dynamic> payload) {
    final copy = Map<String, dynamic>.from(payload);
    if (copy.containsKey('password')) {
      copy['password'] = '***';
    }
    return copy;
  }

  Exception _buildHttpException(String action, http.Response response) {
    final statusCode = response.statusCode;
    final serverMessage = _extractErrorMessage(response.body);

    if (statusCode == 401) {
      print('❌ [$action] 401 Unauthorized: $serverMessage');
      return Exception('401 Unauthorized: $serverMessage');
    }

    if (statusCode == 403) {
      print('❌ [$action] 403 Forbidden: $serverMessage');
      return Exception('403 Forbidden: $serverMessage');
    }

    if (statusCode >= 500) {
      print('❌ [$action] 500 Server Error: $serverMessage');
      return Exception('500 Server Error: $serverMessage');
    }

    print('❌ [$action] HTTP $statusCode: $serverMessage');
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
}
