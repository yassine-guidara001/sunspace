import 'package:flutter_getx_app/app/data/models/user_model.dart';
import 'package:flutter_getx_app/app/data/services/users_api.dart';
import 'package:get/get.dart';

class UserController extends GetxController {
  final UsersApi _api = UsersApi();

  final RxList<User> users = <User>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  final List<User> _allUsers = <User>[];

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final result = await _api.getUsers();
      _allUsers
        ..clear()
        ..addAll(result);
      _applySearch();
    } catch (e) {
      _handleError('Chargement utilisateurs', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addUser(User user, {String? password}) async {
    isLoading.value = true;
    try {
      await _api.createUser(user, password: password);
      await fetchUsers();
      Get.snackbar('Succès', 'Utilisateur ajouté avec succès');
    } catch (e) {
      _handleError('Ajout utilisateur', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> editUser(User user, {String? password}) async {
    isLoading.value = true;
    try {
      await _api.updateUser(user, password: password);
      await fetchUsers();
      Get.snackbar('Succès', 'Utilisateur mis à jour avec succès');
    } catch (e) {
      _handleError('Mise à jour utilisateur', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> removeUser(int id) async {
    isLoading.value = true;
    try {
      await _api.deleteUser(id);
      _allUsers.removeWhere((u) => u.id == id);
      _applySearch();
      Get.snackbar('Succès', 'Utilisateur supprimé avec succès');
    } catch (e) {
      _handleError('Suppression utilisateur', e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUser(User user, {String? password}) {
    return editUser(user, password: password);
  }

  Future<void> deleteUser(int id) {
    return removeUser(id);
  }

  List<User> get filteredUsers => users;

  void setSearch(String query) {
    searchQuery.value = query;
    _applySearch();
  }

  void _applySearch() {
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      users.assignAll(_allUsers);
      return;
    }

    users.assignAll(
      _allUsers.where(
        (u) =>
            u.username.toLowerCase().contains(q) ||
            u.email.toLowerCase().contains(q) ||
            u.role.toLowerCase().contains(q),
      ),
    );
  }

  void _handleError(String context, Object error) {
    final msg = error.toString();
    print('❌ [UserController][$context] $msg');

    if (msg.contains('401')) {
      Get.snackbar('Erreur 401', 'Non autorisé. Veuillez vous reconnecter.');
      return;
    }

    if (msg.contains('403')) {
      Get.snackbar('Erreur 403', 'Accès refusé pour cette opération.');
      return;
    }

    if (msg.contains('500')) {
      Get.snackbar('Erreur 500', 'Erreur serveur. Réessayez plus tard.');
      return;
    }

    Get.snackbar('Erreur', msg.replaceFirst('Exception: ', ''));
  }
}
