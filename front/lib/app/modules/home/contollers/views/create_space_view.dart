import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/space_controller.dart';
import 'custom_sidebar.dart';

class CreateSpaceView extends StatelessWidget {
  final SpaceController controller = Get.find<SpaceController>();

  @override
  Widget build(BuildContext context) {
    final Space? spaceToEdit = Get.arguments as Space?;
    final isEditing = spaceToEdit != null;

    final nameController = TextEditingController(text: spaceToEdit?.name ?? '');
    final locationController =
        TextEditingController(text: spaceToEdit?.location ?? '');
    final capacityController =
        TextEditingController(text: spaceToEdit?.capacity.toString() ?? '');
    final hourlyRateController =
        TextEditingController(text: spaceToEdit?.hourlyRate.toString() ?? '');
    final dailyRateController =
        TextEditingController(text: spaceToEdit?.dailyRate.toString() ?? '');
    final monthlyRateController =
        TextEditingController(text: spaceToEdit?.monthlyRate.toString() ?? '');
    final descriptionController =
        TextEditingController(text: spaceToEdit?.description ?? '');

    final rxType = (spaceToEdit?.type ?? "Bureau").obs;
    final rxStatus = (spaceToEdit?.status ?? "Disponible").obs;

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
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(isEditing),
                        const SizedBox(height: 32),
                        _buildForm(
                          isEditing,
                          spaceToEdit,
                          nameController,
                          locationController,
                          capacityController,
                          hourlyRateController,
                          dailyRateController,
                          monthlyRateController,
                          descriptionController,
                          rxType,
                          rxStatus,
                        ),
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
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.grey, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
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

  Widget _buildHeader(bool isEditing) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
          onPressed: () => Get.back(),
        ),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? "Modifier l'espace" : "Créer un nouvel espace",
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            Text(
              isEditing
                  ? "Modifiez les informations de l'espace sélectionné"
                  : "Ajoutez un nouvel espace de coworking à votre inventaire",
              style: const TextStyle(color: Colors.grey, ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildForm(
    bool isEditing,
    Space? spaceToEdit,
    TextEditingController nameController,
    TextEditingController locationController,
    TextEditingController capacityController,
    TextEditingController hourlyRateController,
    TextEditingController dailyRateController,
    TextEditingController monthlyRateController,
    TextEditingController descriptionController,
    RxString rxType,
    RxString rxStatus,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildField(
                      "Nom de l'espace", "Espace Alpha", nameController)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildDropdown("Type", rxType,
                      ["Bureau", "Salle de réunion", "Café", "Open Space"])),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildField("Localisation", "Étage 2, Aile Nord",
                      locationController)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildField(
                      "Capacité (personnes)", "1", capacityController,
                      isNumber: true)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: _buildDropdown(
                "Statut", rxStatus, ["Disponible", "Occupé", "En maintenance"]),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: _buildField("Tarif horaire", "0", hourlyRateController,
                      isNumber: true)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildField(
                      "Tarif journalier", "0", dailyRateController,
                      isNumber: true)),
              const SizedBox(width: 24),
              Expanded(
                  child: _buildField(
                      "Tarif mensuel", "0", monthlyRateController,
                      isNumber: true)),
            ],
          ),
          const SizedBox(height: 24),
          _buildField("Description", "Description détaillée de l'espace...",
              descriptionController,
              maxLines: 4),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              final newSpace = Space(
                id: isEditing
                    ? spaceToEdit!.id
                    : DateTime.now().millisecondsSinceEpoch,
                name: nameController.text,
                type: rxType.value,
                location: locationController.text,
                capacity: int.tryParse(capacityController.text) ?? 0,
                hourlyRate: double.tryParse(hourlyRateController.text) ?? 0,
                dailyRate: double.tryParse(dailyRateController.text) ?? 0,
                monthlyRate: double.tryParse(monthlyRateController.text) ?? 0,
                status: rxStatus.value,
                description: descriptionController.text,
                reservations: spaceToEdit?.reservations ?? 0,
              );

              if (isEditing) {
                controller.updateSpace(newSpace);
              } else {
                controller.addSpace(newSpace);
              }

              Get.back();
              Get.snackbar(
                  "Succès",
                  isEditing
                      ? "L'espace a été mis à jour."
                      : "L'espace a été ajouté.",
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.white);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BF9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(isEditing ? "Enregistrer" : "Créer l'espace",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, )),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      String label, String hint, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          style: const TextStyle(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey, ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.blue)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, RxString rxValue, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: rxValue.value,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                  items: items.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle()),
                    );
                  }).toList(),
                  onChanged: (val) => rxValue.value = val!,
                ),
              ),
            )),
      ],
    );
  }
}
