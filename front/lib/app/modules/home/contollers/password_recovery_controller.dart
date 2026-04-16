import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';

class PasswordRecoveryController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();

  final emailController = TextEditingController();
  final tokenController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final isSendingResetLink = false.obs;
  final isResettingPassword = false.obs;
  final obscureNewPassword = true.obs;
  final obscureConfirmPassword = true.obs;
  final infoMessage = ''.obs;
  final errorMessage = ''.obs;
  final debugResetUrl = ''.obs;

  String? _extractTokenFromFragment(String fragment) {
    final cleaned = fragment.trim();
    if (cleaned.isEmpty || !cleaned.contains('?')) {
      return null;
    }

    final parts = cleaned.split('?');
    if (parts.length < 2) {
      return null;
    }

    final query = parts.sublist(1).join('?');
    final queryParams = Uri.splitQueryString(query);
    final token = (queryParams['token'] ?? '').trim();
    return token.isEmpty ? null : token;
  }

  String? get initialToken {
    final args = Get.arguments;
    if (args is Map && args['token'] != null) {
      final token = args['token'].toString().trim();
      if (token.isNotEmpty) {
        return token;
      }
    }

    final fromGetParams = (Get.parameters['token'] ?? '').trim();
    if (fromGetParams.isNotEmpty) {
      return fromGetParams;
    }

    final fromQuery = (Uri.base.queryParameters['token'] ?? '').trim();
    if (fromQuery.isNotEmpty) {
      return fromQuery;
    }

    final fromFragment = _extractTokenFromFragment(Uri.base.fragment);
    if (fromFragment != null && fromFragment.isNotEmpty) {
      return fromFragment;
    }

    return null;
  }

  @override
  void onInit() {
    super.onInit();
    final token = initialToken;
    if (token != null && token.isNotEmpty) {
      tokenController.text = token;
    }
  }

  Future<void> sendResetLink() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      errorMessage.value = 'Veuillez saisir une adresse email valide.';
      return;
    }

    isSendingResetLink.value = true;
    errorMessage.value = '';
    infoMessage.value = '';
    debugResetUrl.value = '';

    try {
      final result = await _authService.requestPasswordReset(email: email);
      final resetUrl = (result['resetUrl'] ?? '').toString().trim();
      final delivery = (result['delivery'] ?? '').toString().trim();
      final message = (result['message'] ??
              'Si un compte existe avec cet email, un lien a été envoyé.')
          .toString();

      infoMessage.value = delivery == 'simulated'
          ? '$message\nMode local: configurez SMTP pour envoyer un email réel.'
          : message;
      if (resetUrl.isNotEmpty) {
        debugResetUrl.value = resetUrl;
        final token = Uri.tryParse(resetUrl)?.queryParameters['token'];
        if (token != null && token.isNotEmpty) {
          Get.toNamed(
            Routes.RESET_PASSWORD,
            arguments: {'token': token},
          );
        }
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isSendingResetLink.value = false;
    }
  }

  Future<void> resetPassword() async {
    final token = tokenController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (token.isEmpty) {
      errorMessage.value = 'Le token de réinitialisation est requis.';
      return;
    }

    if (newPassword.length < 6) {
      errorMessage.value =
          'Le mot de passe doit contenir au moins 6 caractères.';
      return;
    }

    if (newPassword != confirmPassword) {
      errorMessage.value = 'Les mots de passe ne correspondent pas.';
      return;
    }

    isResettingPassword.value = true;
    errorMessage.value = '';
    infoMessage.value = '';

    try {
      await _authService.resetPassword(
        token: token,
        password: newPassword,
        confirmPassword: confirmPassword,
      );

      infoMessage.value = 'Mot de passe réinitialisé avec succès.';
      Get.snackbar(
        'Succès',
        'Mot de passe réinitialisé avec succès.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      Get.offAllNamed(Routes.LOGIN);
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isResettingPassword.value = false;
    }
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  @override
  void onClose() {
    emailController.dispose();
    tokenController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
