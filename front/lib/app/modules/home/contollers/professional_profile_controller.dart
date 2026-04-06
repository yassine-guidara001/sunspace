import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:get/get.dart';

class ProfessionalProfileController extends GetxController {
  final AuthService _authService = Get.find<AuthService>();
  final StorageService _storage = Get.find<StorageService>();

  final isLoading = false.obs;
  final isEditing = false.obs;
  final isSaving = false.obs;
  final profile = <String, dynamic>{}.obs;

  final phoneController = TextEditingController();
  final organizationController = TextEditingController();
  final specializationController = TextEditingController();
  final biographyController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      isLoading.value = true;

      final cached = _storage.getUserData();
      if (cached != null && cached.isNotEmpty) {
        profile.assignAll(cached);
      }

      final synced = await _authService.syncCurrentUserProfile(force: true);
      if (synced != null && synced.isNotEmpty) {
        profile.assignAll(synced);
      }

      _fillControllersFromProfile();
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    organizationController.dispose();
    specializationController.dispose();
    biographyController.dispose();
    super.onClose();
  }

  String get username => _firstText([
        profile['username'],
        profile['fullName'],
        profile['name'],
      ], fallback: 'intern');

  String get email => _firstText([
        profile['email'],
      ], fallback: 'intern@sunevit.tn');

  String get roleLabel {
    final roleRaw = profile['role'];

    if (roleRaw is Map) {
      return _firstText([
        roleRaw['name'],
        roleRaw['type'],
      ], fallback: 'Professionnel');
    }

    final asText = _firstText([roleRaw]);
    if (asText.isNotEmpty) {
      return asText;
    }

    return 'Professionnel';
  }

  String get joinedSince {
    final joinedRaw = _firstText([
      profile['createdAt'],
      profile['created_at'],
      profile['registeredAt'],
    ]);

    if (joinedRaw.length >= 7) {
      final yearMonth = joinedRaw.substring(0, 7).split('-');
      if (yearMonth.length == 2) {
        final year = yearMonth[0];
        final month = int.tryParse(yearMonth[1]) ?? 1;
        const months = [
          'janvier',
          'fevrier',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'aout',
          'septembre',
          'octobre',
          'novembre',
          'decembre',
        ];
        final index = month < 1 ? 0 : (month > 12 ? 11 : month - 1);
        return '${months[index]} $year';
      }
    }

    return 'fevrier 2026';
  }

  String get phone => _firstText([
        profile['phone'],
        profile['telephone'],
        profile['phoneNumber'],
        profile['phone_number'],
      ], fallback: '+216 --- ---');

  String get organization => _firstText([
        profile['organization'],
        profile['organisation'],
        profile['company'],
        profile['enterprise'],
      ], fallback: 'Nom de votre entreprise');

  String get specialization => _firstText([
        profile['specialization'],
        profile['specialisation'],
        profile['professionalSpecialization'],
        profile['professional_specialization'],
      ], fallback: 'Ex: Consultant RH, Developpeur Senior, Freelance...');

  String get biography => _firstText([
        profile['biography'],
        profile['biographie'],
        profile['bio'],
        profile['resume'],
      ], fallback: 'Decrivez brievement votre parcours et vos expertises...');

  Future<void> onProfileActionPressed() async {
    if (isSaving.value) return;

    if (!isEditing.value) {
      isEditing.value = true;
      return;
    }

    await saveProfile();
  }

  Future<void> saveProfile() async {
    try {
      isSaving.value = true;

      final userId = await _resolveCurrentUserId();
      if (userId == null) {
        throw Exception('ID utilisateur introuvable');
      }

      final payload = <String, dynamic>{
        'phone': phoneController.text.trim(),
        'telephone': phoneController.text.trim(),
        'organization': organizationController.text.trim(),
        'organisation': organizationController.text.trim(),
        'specialization': specializationController.text.trim(),
        'specialisation': specializationController.text.trim(),
        'biography': biographyController.text.trim(),
        'biographie': biographyController.text.trim(),
      };

      final updated = await _authService.updateUserById(
        userId: userId,
        payload: payload,
      );

      profile.assignAll(updated);
      _fillControllersFromProfile();
      isEditing.value = false;

      Get.snackbar(
        'Succes',
        'Profil mis a jour',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre a jour le profil: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<int?> _resolveCurrentUserId() async {
    final fromStorage = _authService.currentUserId;
    if (fromStorage != null) {
      return fromStorage;
    }

    final synced = await _authService.syncCurrentUserProfile(force: true);
    final rawId = synced?['id'];
    if (rawId is int) return rawId;
    if (rawId is num) return rawId.toInt();
    return int.tryParse(rawId?.toString() ?? '');
  }

  void _fillControllersFromProfile() {
    phoneController.text = phone;
    organizationController.text = organization;
    specializationController.text = specialization;
    biographyController.text = _firstText([
      profile['biography'],
      profile['biographie'],
      profile['bio'],
      profile['resume'],
    ]);
  }

  String _firstText(List<dynamic> values, {String fallback = ''}) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }
}
