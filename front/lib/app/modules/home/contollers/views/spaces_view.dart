import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/space_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'custom_sidebar.dart';

class SpacesView extends StatelessWidget {
  final SpaceController controller = Get.put(SpaceController());

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
                        _buildFilterBar(),
                        const SizedBox(height: 24),
                        _buildSpacesTable(),
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
          Container(
            width: 320,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    onChanged: controller.searchSpaces,
                    decoration: const InputDecoration(
                      hintText: "Rechercher...",
                      hintStyle: TextStyle(color: Colors.grey, ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: Colors.grey, size: 20),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.business_outlined,
                      size: 24, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                const Text("Gestion des espaces",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
              ],
            ),
            const SizedBox(height: 4),
            const Text("Gérez vos espaces de coworking",
                style: TextStyle(color: Colors.grey, )),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(Routes.CREATE_SPACE),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text("Nouvel espace"),
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

  Widget _buildFilterBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: controller.searchSpaces,
                    decoration: const InputDecoration(
                        hintText: "Rechercher un espace...",
                        hintStyle: TextStyle(color: Colors.grey, ),
                        border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: "Tous les statuts",
              style: const TextStyle(color: Colors.black, ),
              items: [
                "Tous les statuts",
                "Disponible",
                "Occupé",
                "En maintenance"
              ]
                  .map((String value) => DropdownMenuItem<String>(
                      value: value, child: Text(value)))
                  .toList(),
              onChanged: (val) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpacesTable() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
              padding: EdgeInsets.all(100.0),
              child: Center(child: CircularProgressIndicator()));
        }

        final items = controller.spaces;
        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  _buildHeaderCell("Espace", flex: 3),
                  _buildHeaderCell("Type", flex: 2),
                  _buildHeaderCell("Localisation", flex: 3),
                  _buildHeaderCell("Capacité",
                      flex: 1, align: TextAlign.center),
                  _buildHeaderCell("Tarif/h", flex: 1, align: TextAlign.center),
                  _buildHeaderCell("Réservations",
                      flex: 2, align: TextAlign.center),
                  _buildHeaderCell("Statut", flex: 2),
                  _buildHeaderCell("Actions", flex: 2),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.withOpacity(0.05)),
              itemBuilder: (context, index) => _buildSpaceRow(items[index]),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildHeaderCell(String label,
      {int flex = 1, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
            fontWeight: FontWeight.bold, color: Colors.black, ),
      ),
    );
  }

  Widget _buildSpaceRow(Space space) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(space.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, ))),
          Expanded(
              flex: 2,
              child: Text(space.type,
                  style:
                      const TextStyle(color: Color(0xFF64748B), ))),
          Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_outlined,
                      size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(space.location,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF64748B), )),
                  ),
                ],
              )),
          Expanded(
              flex: 1,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline,
                        size: 14, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text("${space.capacity}",
                        style: const TextStyle(
                            color: Color(0xFF64748B), )),
                  ],
                ),
              )),
          Expanded(
              flex: 1,
              child: Center(
                child: Text("\$${space.hourlyRate}",
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        )),
              )),
          Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${space.reservations}",
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )),
          Expanded(flex: 2, child: _buildStatusBadge(space.status)),
          Expanded(
              flex: 2,
              child: Row(
                children: [
                  const Icon(Icons.visibility_outlined,
                      size: 18, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () =>
                        Get.toNamed(Routes.CREATE_SPACE, arguments: space),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFF94A3B8)),
                    onPressed: () => controller.deleteSpace(space.id),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Disponible':
        bgColor = const Color(0xFFF0FDF4);
        textColor = const Color(0xFF166534);
        break;
      case 'Occupé':
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFF92400E);
        break;
      case 'En maintenance':
        bgColor = const Color(0xFFFEF2F2);
        textColor = const Color(0xFF991B1B);
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(6)),
        child: Text(status,
            style: TextStyle(
                color: textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
