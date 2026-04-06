import 'package:flutter_getx_app/app/data/models/association_model.dart';
import 'package:flutter_getx_app/app/data/services/associations_service.dart';
import 'package:get/get.dart';

class AssociationsController extends GetxController {
  AssociationsController({AssociationsService? service})
      : _service = service ?? Get.find<AssociationsService>();

  final AssociationsService _service;

  final associations = <AssociationModel>[].obs;
  final adminOptions = <UserOption>[].obs;

  final isLoading = false.obs;
  final isMutating = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await _service.loadAssociationsAndUsers();
      associations.assignAll(result.associations);
      adminOptions.assignAll(result.users);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> createAssociation(AssociationFormPayload payload) async {
    return _runMutation(
      action: () => _service.createAssociation(payload),
    );
  }

  Future<String?> updateAssociation(
    String documentId,
    AssociationFormPayload payload,
  ) async {
    return _runMutation(
      action: () => _service.updateAssociation(documentId, payload),
    );
  }

  Future<String?> deleteAssociation(String documentId) async {
    return _runMutation(
      action: () => _service.deleteAssociation(documentId),
    );
  }

  Future<String?> _runMutation({
    required Future<void> Function() action,
  }) async {
    if (isMutating.value) return 'Operation deja en cours';
    isMutating.value = true;

    try {
      await action();
      await loadData();
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      isMutating.value = false;
    }
  }
}
