import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/association_model.dart';
import 'package:flutter_getx_app/app/data/services/associations_service.dart';
import 'package:get/get.dart';

class AssociationBudgetController extends GetxController {
  AssociationBudgetController({AssociationsService? service})
      : _service = service ?? Get.find<AssociationsService>();

  final AssociationsService _service;
  final AuthService _auth = Get.find<AuthService>();

  final userAssociations = <AssociationModel>[].obs;
  final isLoading        = false.obs;
  final errorMessage     = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  // ── Recharge à chaque fois que la page devient visible ───────────────────
  @override
  void onReady() {
    super.onReady();
    loadData();
  }

  Future<void> loadData() async {
    isLoading.value    = true;
    errorMessage.value = '';

    final userId = _auth.currentUserId;
    if (userId == null) {
      errorMessage.value = 'Utilisateur non connecté';
      isLoading.value    = false;
      return;
    }

    try {
      // GET /associations?filters[admin][id][$eq]={userId}&populate=*
      final associations = await _service.loadAssociationsByUserId(userId);
      userAssociations.assignAll(associations);
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  double get totalBalance =>
      userAssociations.fold(0, (sum, a) => sum + a.budgetValue);

  String get currency {
    if (userAssociations.isEmpty) return 'TND';
    final c = userAssociations.first.currency.trim();
    return c.isNotEmpty ? c : 'TND';
  }

  String get firstDocumentId {
    if (userAssociations.isEmpty) return '';
    return userAssociations.first.documentId;
  }
}