import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/data/services/space_service.dart';
import 'package:get/get.dart';

class SpaceController extends GetxController {
  // ================= STATE =================

  final spaces = <Space>[].obs;
  final loading = false.obs;
  final errorMessage = ''.obs;
  final deletingDocumentIds = <String>{}.obs;
  Future<void>? _inFlightLoad;

  // ================= INIT =================

  @override
  void onInit() {
    loadSpaces(forceRefresh: true);
    super.onInit();
  }

  // ================= LOAD =================

  Future<void> loadSpaces({bool forceRefresh = false}) async {
    if (_inFlightLoad != null && !forceRefresh) {
      return _inFlightLoad!;
    }

    loading.value = true;
    errorMessage.value = '';

    final task = () async {
      try {
        final result = await SpaceApi.getSpaces(forceRefresh: forceRefresh);
        spaces.assignAll(result);

        print('✅ ${spaces.length} espaces chargés');
      } catch (e) {
        errorMessage.value = e.toString();
        print('❌ loadSpaces error: $e');

        Get.snackbar(
          "Erreur",
          e.toString(),
          snackPosition: SnackPosition.BOTTOM,
          mainButton: TextButton(
            onPressed: () => loadSpaces(forceRefresh: true),
            child:
                const Text("Réessayer", style: TextStyle(color: Colors.white)),
          ),
        );
      } finally {
        loading.value = false;
        _inFlightLoad = null;
      }
    }();

    _inFlightLoad = task;
    return task;
  }

  // ================= CREATE =================

  Future<Space?> create(Map<String, dynamic> data) async {
    try {
      loading.value = true;

      final newSpace = await SpaceApi.createSpace(data);
      // Affichage immédiat dans le tableau
      spaces.insert(0, newSpace);

      Get.snackbar(
        "Succès",
        "Espace créé avec succès",
        snackPosition: SnackPosition.BOTTOM,
      );

      return newSpace;
    } catch (e) {
      Get.snackbar(
        "Erreur création",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );

      return null;
    } finally {
      loading.value = false;
    }
  }

  // ================= UPDATE =================

  Future<bool> updateSpace(String documentId, Map<String, dynamic> data) async {
    try {
      loading.value = true;

      final updated = await SpaceApi.updateSpace(documentId, data);

      final index = spaces.indexWhere((e) => e.documentId == documentId);
      if (index != -1) {
        spaces[index] = updated;
        spaces.refresh();
      }

      return true;
    } catch (e) {
      Get.snackbar(
        "Erreur modification",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );

      return false;
    } finally {
      loading.value = false;
    }
  }

  // ================= DELETE =================

  bool isDeleting(String documentId) {
    return deletingDocumentIds.contains(documentId.trim());
  }

  Future<void> delete(Space space) async {
    final docId = space.documentId.trim();
    if (docId.isEmpty) {
      Get.snackbar(
        "Erreur suppression",
        "documentId manquant",
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (deletingDocumentIds.contains(docId)) {
      return;
    }

    deletingDocumentIds.add(docId);

    try {
      loading.value = true;

      await SpaceApi.deleteSpace(docId);
      spaces.removeWhere(
        (e) => e.documentId == docId || e.id == space.id,
      );

      Get.snackbar(
        "Succès",
        "Espace supprimé",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Erreur suppression",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      loading.value = false;
      deletingDocumentIds.remove(docId);
    }
  }

  // ================= FIND =================

  Space? findById(int id) {
    try {
      return spaces.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Space? findByDocumentId(String documentId) {
    try {
      return spaces.firstWhere((e) => e.documentId == documentId);
    } catch (_) {
      return null;
    }
  }

  // ================= REFRESH =================

  Future<void> refreshSpaces() async {
    await loadSpaces();
  }
}
