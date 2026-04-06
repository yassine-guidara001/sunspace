import 'package:flutter_getx_app/app/core/service/http_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';

class AuthController extends GetxController {
  static AuthController get to => Get.find<AuthController>();

  final isLoading = false.obs;
  final HttpService httpService = Get.find<HttpService>();
  final StorageService storageService = Get.find<StorageService>();

  String get token =>
      storageService.getToken() ??
      storageService.read<String>('token') ??
      storageService.read<String>('jwt') ??
      '';

  /// Extraire le token de la réponse (nouveau format Node.js + ancien format Strapi)
  String? _extractToken(Map<String, dynamic> body) {
    // Format Node.js: data.jwt ou data.token
    if (body['data'] is Map) {
      final data = body['data'] as Map<String, dynamic>;
      final token = data['jwt'] ??
          data['token'] ??
          data['accessToken'] ??
          data['access_token'];
      if (token != null && token.toString().isNotEmpty) {
        print(
            '✅ Token trouvé (Node.js format): ${token.toString().substring(0, 20)}...');
        return token.toString();
      }
    }

    // Format Strapi ancien: jwt, token, accessToken, access_token
    final token = body['jwt'] ??
        body['token'] ??
        body['accessToken'] ??
        body['access_token'];
    if (token != null && token.toString().isNotEmpty) {
      print(
          '✅ Token trouvé (Strapi format): ${token.toString().substring(0, 20)}...');
      return token.toString();
    }
    return null;
  }

  /// Extraire l'utilisateur de la réponse (supporté ancien + nouveau format)
  Map<String, dynamic>? _extractUser(Map<String, dynamic> body) {
    // Format Node.js: data.user
    if (body['data'] is Map) {
      final data = body['data'] as Map<String, dynamic>;
      if (data['user'] is Map) {
        return data['user'] as Map<String, dynamic>;
      }
    }

    // Format Strapi ancien: user
    if (body['user'] is Map) {
      return body['user'] as Map<String, dynamic>;
    }

    return null;
  }

  /// Extraire le message d'erreur de la réponse
  String _extractErrorMessage(dynamic bodyData) {
    if (bodyData is! Map) return 'Une erreur est survenue';

    // Format Node.js: error.message ou message
    if (bodyData['error'] is Map) {
      final errorObj = bodyData['error'] as Map<dynamic, dynamic>;
      if (errorObj['message'] != null) {
        return errorObj['message'].toString();
      }
    }

    // Essayer message directement
    if (bodyData['message'] != null) {
      return bodyData['message'].toString();
    }

    return 'Une erreur est survenue';
  }

  // 🔐 LOGIN
  Future<void> loginUser(String identifier, String password) async {
    final normalizedIdentifier = identifier.trim();
    final normalizedPassword = password.trim();

    if (normalizedIdentifier.isEmpty || normalizedPassword.isEmpty) {
      Get.snackbar('Erreur', 'Remplir tous les champs');
      return;
    }

    isLoading.value = true;

    try {
      print('🔐 Tentative de connexion...');
      final payload = <String, dynamic>{
        'identifier': normalizedIdentifier,
        'password': normalizedPassword,
      };

      final response = await httpService.postAuth(
        '/api/auth/local',
        payload,
      );

      print(
          '📥 Response: statusCode=${response.statusCode}, body=${response.body}');

      // Vérifier si statusCode est null (erreur réseau)
      if (response.statusCode == null || response.statusCode == 0) {
        Get.snackbar('Erreur', response.statusText ?? 'Erreur réseau');
        return;
      }

      if (response.statusCode == 200) {
        if (response.body == null || response.body is! Map) {
          Get.snackbar('Erreur', 'Réponse serveur invalide');
          return;
        }

        final body = response.body as Map<String, dynamic>;
        final token = _extractToken(body);

        if (token == null) {
          print('❌ Token NOT found in response');
          print('📋 Response body: $body');
          Get.snackbar('Erreur', 'Pas de token reçu du serveur');
          return;
        }

        // Sauvegarder le token
        await storageService.saveToken(token);
        if (normalizedIdentifier.contains('@')) {
          await storageService.write('last_login_email', normalizedIdentifier);
        }

        final user = _extractUser(body);
        if (user != null) {
          await storageService.saveUserData(user);
          final username = user['username'] ?? 'Utilisateur';
          Get.snackbar('Succès', 'Bienvenue $username');
        } else {
          Get.snackbar('Succès', 'Connexion réussie');
        }

        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().refreshCurrentUserIdentity(
            force: true,
          );
        }

        Get.offAllNamed(Routes.HOME);
      } else {
        // Erreur du serveur
        final body =
            response.body is Map ? response.body as Map<String, dynamic> : {};
        final errorMsg = _extractErrorMessage(body);

        final statusCode = response.statusCode;
        final failureMessage =
            statusCode == null ? errorMsg : '[$statusCode] $errorMsg';

        print('⚠️ Login failed: $failureMessage');
        Get.snackbar('Erreur', failureMessage);
      }
    } catch (e) {
      print('❌ Login exception: $e');
      Get.snackbar('Erreur', 'Erreur: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    await storageService.logout();
    Get.offAllNamed(Routes.LOGIN);
  }

  // 🔐 REGISTER
  Future<void> registerUser(
      String username, String email, String password) async {
    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      Get.snackbar('Erreur', 'Remplir tous les champs');
      return;
    }

    isLoading.value = true;

    try {
      print('🔐 Tentative inscription...');
      final payload = {
        'username': username.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'confirmPassword':
            password.trim(), // Backend Node.js valide la confirmation
      };

      final response = await httpService.postAuth(
        '/api/auth/local/register',
        payload,
      );

      print(
          '📥 Response: statusCode=${response.statusCode}, body=${response.body}');

      // Vérifier si statusCode est null (erreur réseau)
      if (response.statusCode == null || response.statusCode == 0) {
        Get.snackbar('Erreur', response.statusText ?? 'Erreur réseau');
        return;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body == null || response.body is! Map) {
          Get.snackbar('Succès', 'Inscription réussie - Connectez-vous');
          Get.offAllNamed(Routes.LOGIN);
          return;
        }

        final body = response.body as Map<String, dynamic>;
        final token = _extractToken(body);

        if (token == null) {
          print('❌ Token NOT found after register');
          Get.snackbar('Succès', 'Inscription réussie - Connectez-vous');
          Get.offAllNamed(Routes.LOGIN);
          return;
        }

        // Auto-login: sauvegarder le token
        await storageService.saveToken(token);
        await storageService.write('last_login_email', email.trim());

        final user = _extractUser(body);
        if (user != null) {
          await storageService.saveUserData(user);
        }

        if (Get.isRegistered<HomeController>()) {
          await Get.find<HomeController>().refreshCurrentUserIdentity(
            force: true,
          );
        }

        Get.snackbar('Succès', 'Inscription et connexion réussies');
        Get.offAllNamed(Routes.HOME);
      } else {
        // Erreur du serveur
        final body =
            response.body is Map ? response.body as Map<String, dynamic> : {};
        final errorMsg = _extractErrorMessage(body);

        print('⚠️ Register failed: $errorMsg');
        Get.snackbar('Erreur', errorMsg);
      }
    } catch (e) {
      print('❌ Register exception: $e');
      Get.snackbar('Erreur', 'Erreur: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
