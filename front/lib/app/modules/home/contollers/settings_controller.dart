import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final username = ''.obs;
  final email = ''.obs;
  final isLoading = false.obs;

  // Préférences notifications (état local)
  final notifEmail = true.obs;
  final notifSms = false.obs;
  final notifPush = true.obs;

  final isPasswordFormOpen = false.obs;
  final isSavingPassword = false.obs;
  final obscureNewPassword = true.obs;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    isLoading.value = true;
    try {
      // Requête GET /users/me?populate=*
      final profile = await _auth.syncCurrentUserProfile(force: true);
      if (profile != null) {
        username.value = _extract(profile, ['username', 'name', 'fullName']);
        email.value = _extract(profile, ['email']);
      }
    } catch (_) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  void saveNotifPreferences() {
    Get.snackbar(
      'Paramètres',
      'Préférences enregistrées.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void changePassword() {
    isPasswordFormOpen.value = true;
  }

  void cancelPasswordChange() {
    currentPasswordController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
    obscureNewPassword.value = true;
    isPasswordFormOpen.value = false;
  }

  Future<void> savePasswordChange() async {
    final current = currentPasswordController.text.trim();
    final next = newPasswordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      Get.snackbar(
        'Sécurité',
        'Veuillez remplir tous les champs.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (next.length < 6) {
      Get.snackbar(
        'Sécurité',
        'Le nouveau mot de passe doit contenir au moins 6 caractères.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (next != confirm) {
      Get.snackbar(
        'Sécurité',
        'La confirmation du mot de passe ne correspond pas.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isSavingPassword.value = true;

    try {
      // Placeholder API call for future password update endpoint.
      await Future<void>.delayed(const Duration(milliseconds: 350));

      Get.snackbar(
        'Sécurité',
        'Mot de passe mis à jour avec succès.',
        snackPosition: SnackPosition.BOTTOM,
      );
      cancelPasswordChange();
    } finally {
      isSavingPassword.value = false;
    }
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  String _extract(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = (map[k] ?? '').toString().trim();
      if (v.isNotEmpty && v != 'null') return v;
    }
    return '';
  }
}
