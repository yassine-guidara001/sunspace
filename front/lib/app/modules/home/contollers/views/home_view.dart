import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';
import 'custom_sidebar.dart';
import 'notifications_page.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildUsersTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Text("Dashboard",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              )),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey, size: 20),
            onPressed: controller.refreshUsers,
          ),
          const SizedBox(width: 8),
          const NotificationBell(),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 8),
          const Text("intern",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
              )),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people_outline, size: 28, color: Colors.blue),
                SizedBox(width: 12),
                Text("Gestion des utilisateurs",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              ],
            ),
            SizedBox(height: 4),
            Text("Gérez les utilisateurs et leurs permissions",
                style: TextStyle(
                  color: Colors.grey,
                )),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text("Nouvel utilisateur"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: TextField(
        onChanged: controller.searchUsers,
        decoration: InputDecoration(
          hintText: "Rechercher un utilisateur...",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
              padding: EdgeInsets.all(100.0),
              child: Center(child: CircularProgressIndicator()));
        }

        final users = controller.users;
        if (users.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(100.0),
              child: Center(
                  child: Text("Aucun utilisateur trouvé",
                      style: TextStyle(color: Colors.grey))));
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  _buildHeaderCell("Utilisateur", flex: 3),
                  _buildHeaderCell("Email", flex: 3),
                  _buildHeaderCell("Rôle", flex: 2),
                  _buildHeaderCell("Statut", flex: 2),
                  _buildHeaderCell("Inscrit le", flex: 2),
                  _buildHeaderCell("Actions", flex: 1),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) => _buildUserRow(users[index]),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildUserRow(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Row(
        children: [
          /// Utilisateur
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text("ID: ${user.id}",
                        style: const TextStyle(
                          color: Colors.grey,
                        )),
                    const SizedBox(width: 4),
                    const Icon(Icons.copy, size: 12, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          /// Email
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.mail_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(user.email,
                    style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),

          /// Rôle
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.hexagon_outlined,
                    size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(user.role,
                    style: const TextStyle(color: Color(0xFF475569))),
              ],
            ),
          ),

          /// Statut
          Expanded(
            flex: 2,
            child: _buildStatusBadge(user.status),
          ),

          /// Inscrit le
          Expanded(
            flex: 2,
            child: Text(
              "${user.registeredAt.day.toString().padLeft(2, '0')}/${user.registeredAt.month.toString().padLeft(2, '0')}/${user.registeredAt.year}",
              style: const TextStyle(color: Color(0xFF475569)),
            ),
          ),

          /// Actions
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_outlined,
                      size: 20, color: Colors.grey),
                  onPressed: () {},
                ),
                const SizedBox(width: 12),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: Colors.grey),
                  onPressed: () => controller.deleteUser(user.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Color(0xFF166534),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    final rxRole = "Sélectionner un rôle".obs;
    final rxConfirmed = true.obs;
    final rxBlocked = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Nouvel utilisateur",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text("Ajoutez un nouvel utilisateur au système.",
                          style: TextStyle(
                            color: Colors.grey,
                          )),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              /// Nom d'utilisateur
              const Text("Nom d'utilisateur",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: name,
                decoration: InputDecoration(
                  hintText: "johndoe",
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 16),

              /// Email
              const Text("Email",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: email,
                decoration: InputDecoration(
                  hintText: "john@example.com",
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 16),

              /// Rôle
              const Text("Rôle",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: rxRole.value == "Sélectionner un rôle"
                            ? null
                            : rxRole.value,
                        hint: Text(rxRole.value,
                            style: const TextStyle(
                              color: Colors.grey,
                            )),
                        isExpanded: true,
                        items: ["Admin", "Authenticated", "Staff"]
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) => rxRole.value = val!,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),

              /// Mot de passe
              const Text("Mot de passe",
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 8),
              TextField(
                controller: password,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "******",
                  hintStyle: const TextStyle(
                    color: Colors.grey,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                ),
              ),
              const SizedBox(height: 16),

              /// Switches
              Row(
                children: [
                  Obx(() => Switch(
                        value: rxConfirmed.value,
                        onChanged: (val) => rxConfirmed.value = val,
                        activeColor: Colors.blue,
                      )),
                  const Text("Confirmé", style: TextStyle()),
                  const SizedBox(width: 24),
                  Obx(() => Switch(
                        value: rxBlocked.value,
                        onChanged: (val) => rxBlocked.value = val,
                        activeColor: Colors.blue,
                      )),
                  const Text("Bloqué", style: TextStyle()),
                ],
              ),
              const SizedBox(height: 24),

              /// Action Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007BFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    controller.createUser(
                      name.text,
                      email.text,
                      role: rxRole.value == "Sélectionner un rôle"
                          ? "Authenticated"
                          : rxRole.value,
                    );
                    Get.back();
                  },
                  child: const Text("Enregistrer",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
