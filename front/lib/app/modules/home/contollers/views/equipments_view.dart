import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/equipment_controller.dart';
import 'package:flutter_getx_app/app/data/models/equipment_model.dart';
import 'custom_sidebar.dart';

class EquipmentsView extends StatelessWidget {
  final EquipmentController controller = Get.find<EquipmentController>();

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 920;

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
                    padding: EdgeInsets.all(isCompact ? 16 : 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildFilterBar(),
                        const SizedBox(height: 24),
                        _buildEquipmentsTable(isCompact),
                        const SizedBox(height: 20),
                        _buildEquipmentStatsSection(),
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
                    onChanged: (val) {},
                    decoration: const InputDecoration(
                      hintText: "Rechercher...",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Gestion des Équipements",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            Text(
              "Gérez tous les équipements de vos espaces",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showEquipmentFormDialog(Get.context!),
          icon: const Icon(Icons.add, size: 18, color: Colors.white),
          label: const Text("Ajouter un équipement"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BF9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.grey, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: controller.searchEquipments,
                    decoration: const InputDecoration(
                      hintText: "Rechercher un équipement...",
                      hintStyle: TextStyle(
                        color: Colors.grey,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: "Tous les statuts",
              style: const TextStyle(
                color: Colors.black,
              ),
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: ["Tous les statuts", "Disponible", "Maintenance", "Occupé"]
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

  Widget _buildEquipmentsTable(bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
              padding: EdgeInsets.all(100.0),
              child: Center(child: CircularProgressIndicator()));
        }

        final items = controller.equipments;

        if (isCompact) {
          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final equipment = items[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipment.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text('Type: ${equipment.type}'),
                        Text('S/N: ${equipment.serialNumber}'),
                        Text(
                          'Prix/jour: ${equipment.pricePerDay.toStringAsFixed(2)}',
                        ),
                        Text('Espace: ${equipment.spaceLabel}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStatusBadge(equipment.status),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.edit_outlined,
                              size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () => _showEquipmentFormDialog(
                            Get.context!,
                            equipment: equipment,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () =>
                              controller.deleteEquipment(equipment.documentId),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        }

        return Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                children: [
                  _buildHeaderCell("Nom", flex: 3),
                  _buildHeaderCell("Type", flex: 2),
                  _buildHeaderCell("Numéro de série",
                      flex: 2, align: TextAlign.center),
                  _buildHeaderCell("Status", flex: 2, align: TextAlign.center),
                  _buildHeaderCell("Prix/jour",
                      flex: 2, align: TextAlign.center),
                  _buildHeaderCell("Espaces", flex: 2, align: TextAlign.center),
                  _buildHeaderCell("Actions", flex: 2, align: TextAlign.end),
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
              itemBuilder: (context, index) => _buildEquipmentRow(items[index]),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEquipmentStatsSection() {
    return Obx(() {
      final items = controller.equipments;
      final total = items.length;
      final disponible = items
          .where((e) => _normalizeEquipmentStatus(e.status) == 'disponible')
          .length;
      final enPanne = items
          .where((e) => _normalizeEquipmentStatus(e.status) == 'en panne')
          .length;
      final enMaintenance = items
          .where((e) => _normalizeEquipmentStatus(e.status) == 'en maintenance')
          .length;

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _buildStatsCard('Total', total, const Color(0xFF0F172A)),
          _buildStatsCard('Disponible', disponible, const Color(0xFF16A34A)),
          _buildStatsCard('En panne', enPanne, const Color(0xFFDC2626)),
          _buildStatsCard(
            'En maintenance',
            enMaintenance,
            const Color(0xFFF59E0B),
          ),
        ],
      );
    });
  }

  Widget _buildStatsCard(String label, int value, Color valueColor) {
    return Container(
      width: 370,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              color: valueColor,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              height: 0.95,
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeEquipmentStatus(String raw) {
    final value = raw.trim().toLowerCase().replaceAll('_', ' ');
    if (value.contains('disponible')) return 'disponible';
    if (value.contains('panne') || value.contains('occup')) return 'en panne';
    if (value.contains('maitenance') || value.contains('maintenance')) {
      return 'en maintenance';
    }
    return value;
  }

  Widget _buildHeaderCell(String label,
      {int flex = 1, TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEquipmentRow(Equipment equipment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              equipment.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              equipment.type,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                equipment.serialNumber,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(child: _buildStatusBadge(equipment.status)),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                equipment.pricePerDay.toStringAsFixed(2),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                equipment.spaceLabel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.edit_outlined,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () => _showEquipmentFormDialog(Get.context!,
                      equipment: equipment),
                ),
                const SizedBox(width: 8),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () =>
                      controller.deleteEquipment(equipment.documentId),
                ),
              ],
            ),
          ),
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
      case 'Maintenance':
      case 'En maitenance':
      case 'En maintenance':
        bgColor = const Color(0xFFFFFBEB);
        textColor = const Color(0xFF92400E);
        break;
      case 'Occupé':
      case 'En panne':
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
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showEquipmentFormDialog(BuildContext context, {Equipment? equipment}) {
    const statusItems = ["Disponible", "En panne", "En maitenance"];
    final spaceItems = controller.spacesList;

    String normalizeStatusForDropdown(String raw) {
      final v = raw.trim().toLowerCase().replaceAll('_', ' ');
      if (v == 'en maitenance' || v == 'en maintenance' || v == 'maintenance') {
        return 'En maitenance';
      }
      if (v == 'en panne' || v == 'panne' || v == 'occupé') return 'En panne';
      return 'Disponible';
    }

    String normalizeSpaceForDropdown(String raw) {
      final value = raw.trim();
      if (value.isEmpty) return 'Aucun';
      // Ensure the value exists in our dynamic list
      if (spaceItems.contains(value)) return value;
      return 'Aucun';
    }

    final isEditing = equipment != null;
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final typeController = TextEditingController(text: equipment?.type ?? '');
    final serialController =
        TextEditingController(text: equipment?.serialNumber ?? '');
    final priceController =
        TextEditingController(text: equipment?.purchasePrice.toString() ?? '');
    final dayPriceController =
        TextEditingController(text: equipment?.pricePerDay.toString() ?? '');
    final dateController =
        TextEditingController(text: equipment?.purchaseDate ?? '');
    final warrantyController =
        TextEditingController(text: equipment?.warrantyExpiration ?? '');
    final descriptionController =
        TextEditingController(text: equipment?.description ?? '');
    final notesController = TextEditingController(text: equipment?.notes ?? '');
    final rxStatus =
        normalizeStatusForDropdown(equipment?.status ?? "Disponible").obs;
    final rxSpace =
        normalizeSpaceForDropdown(equipment?.spaceLabel ?? "Aucun").obs;

    Future<void> pickDate(TextEditingController target) async {
      DateTime initialDate = DateTime.now();

      // Supporte dd/MM/yyyy
      final raw = target.text.trim();
      final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(raw);
      if (m != null) {
        final dd = int.tryParse(m.group(1) ?? '');
        final mm = int.tryParse(m.group(2) ?? '');
        final yyyy = int.tryParse(m.group(3) ?? '');
        if (dd != null && mm != null && yyyy != null) {
          initialDate = DateTime(yyyy, mm, dd);
        }
      }

      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );

      if (picked == null) return;
      final dd = picked.day.toString().padLeft(2, '0');
      final mm2 = picked.month.toString().padLeft(2, '0');
      final yyyy2 = picked.year.toString();
      target.text = '$dd/$mm2/$yyyy2';
    }

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            isEditing
                                ? "Modifier l'équipement"
                                : "Ajouter un équipement",
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            isEditing
                                ? "Modifiez les informations de l'équipement."
                                : "Ajoutez un nouvel équipement à votre inventaire.",
                            style: const TextStyle(
                              color: Colors.grey,
                            )),
                      ],
                    ),
                    IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Get.back()),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                        child: _buildDialogField(
                            "Nom", "Nom de l'équipement", nameController)),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildDialogField(
                            "Type", "Type d'équipement", typeController)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildDialogField("Numéro de série",
                            "Numéro de série", serialController)),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildDialogDropdown(
                            "Statut", rxStatus, statusItems)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildDialogField(
                            "Date d'achat", "jj/mm/aaaa", dateController,
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () => pickDate(dateController))),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildDialogField(
                            "Prix d'achat", "0", priceController,
                            isNumber: true)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: _buildDialogField(
                            "Prix par jour", "0", dayPriceController,
                            isNumber: true)),
                    const SizedBox(width: 24),
                    Expanded(
                        child: _buildDialogField("Expiration de la garantie",
                            "jj/mm/aaaa", warrantyController,
                            icon: Icons.calendar_today_outlined,
                            readOnly: true,
                            onTap: () => pickDate(warrantyController))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: 200,
                    child: _buildDialogDropdown(
                        "Espaces (Optionnel)", rxSpace, spaceItems)),
                const SizedBox(height: 16),
                _buildDialogField("Description", "Description détaillée...",
                    descriptionController,
                    maxLines: 3),
                const SizedBox(height: 16),
                _buildDialogField(
                    "Notes", "Notes additionnelles...", notesController,
                    maxLines: 3),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text("Annuler",
                          style: TextStyle(color: Colors.black)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final selectedSpaceLabel = rxSpace.value;
                        final selectedSpaceId =
                            controller.spaceIdForLabel(selectedSpaceLabel);
                        final selectedSpaceIds = selectedSpaceId == null
                            ? <int>[]
                            : <int>[selectedSpaceId];

                        final newEquipment = Equipment(
                          id: isEditing
                              ? equipment.id
                              : DateTime.now().millisecondsSinceEpoch,
                          documentId: isEditing ? equipment.documentId : '',
                          name: nameController.text,
                          type: typeController.text,
                          serialNumber: serialController.text,
                          status: rxStatus.value,
                          purchaseDate: dateController.text,
                          purchasePrice:
                              double.tryParse(priceController.text) ?? 0,
                          pricePerDay:
                              double.tryParse(dayPriceController.text) ?? 0,
                          warrantyExpiration: warrantyController.text,
                          spaceIds: selectedSpaceIds,
                          spaceLabel: selectedSpaceLabel,
                          description: descriptionController.text,
                          notes: notesController.text,
                        );
                        if (isEditing) {
                          controller.updateEquipment(newEquipment);
                        } else {
                          controller.addEquipment(newEquipment);
                        }
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007BF9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(isEditing ? "Enregistrer" : "Ajouter"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogField(
      String label, String hint, TextEditingController controller,
      {bool isNumber = false,
      int maxLines = 1,
      IconData? icon,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLines: maxLines,
          readOnly: readOnly,
          showCursor: !readOnly,
          onTap: onTap,
          style: const TextStyle(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Colors.grey,
            ),
            suffixIcon: icon != null
                ? IconButton(
                    onPressed: onTap,
                    icon: Icon(icon, size: 18, color: Colors.black54),
                    splashRadius: 18,
                    tooltip: 'Choisir une date',
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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

  Widget _buildDialogDropdown(
      String label, RxString rxValue, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        const SizedBox(height: 8),
        Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
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
                        child: Text(value, style: const TextStyle()));
                  }).toList(),
                  onChanged: (val) => rxValue.value = val!,
                ),
              ),
            )),
      ],
    );
  }
}
