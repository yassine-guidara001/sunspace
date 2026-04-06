import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/association_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/associations_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';

class AssociationsView extends StatefulWidget {
  const AssociationsView({super.key});

  @override
  State<AssociationsView> createState() => _AssociationsViewState();
}

class _AssociationsViewState extends State<AssociationsView> {
  late final AssociationsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AssociationsController>();
  }

  Future<void> _openCreateDialog() async {
    final payload = await showDialog<AssociationFormPayload>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _CreateAssociationDialog(
        adminOptions: controller.adminOptions.toList(),
      ),
    );

    if (payload == null) return;

    final error = await controller.createAssociation(payload);
    if (error != null) {
      Get.snackbar(
        'Associations',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Associations',
      'Association creee avec succes',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _openEditDialog(AssociationModel row) async {
    final payload = await showDialog<AssociationFormPayload>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => _CreateAssociationDialog(
        adminOptions: controller.adminOptions.toList(),
        initialData: row,
        title: 'Modifier association',
        subtitle: 'Mettez a jour les informations de cette association.',
        submitLabel: 'Mettre a jour',
      ),
    );

    if (payload == null) return;

    final error = await controller.updateAssociation(row.documentId, payload);
    if (error != null) {
      Get.snackbar(
        'Associations',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Associations',
      'Association mise a jour',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> _confirmDelete(AssociationModel row) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer association'),
        content: Text('Supprimer "${row.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await controller.deleteAssociation(row.documentId);
    if (error != null) {
      Get.snackbar(
        'Associations',
        error,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.snackbar(
      'Associations',
      'Association supprimee',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                const DashboardTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Associations',
                                    style: TextStyle(
                                      fontSize: 36,
                                      height: 1.0,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Gerez les associations, leurs administrateurs et membres.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Obx(
                              () => ElevatedButton.icon(
                                onPressed: controller.isMutating.value
                                    ? null
                                    : _openCreateDialog,
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Nouvelle Association'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1664FF),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              const _AssociationsTableHeader(),
                              const Divider(
                                  height: 1, color: Color(0xFFE2E8F0)),
                              Obx(() => _buildTableBody()),
                            ],
                          ),
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

  Widget _buildTableBody() {
    if (controller.isLoading.value) {
      return const SizedBox(
        height: 190,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return SizedBox(
        height: 190,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 28),
              const SizedBox(height: 8),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB91C1C),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: controller.loadData,
                child: const Text('Reessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.associations.isEmpty) {
      return SizedBox(
        height: 190,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.groups_outlined,
                color: Color(0xFF94A3B8),
                size: 30,
              ),
              SizedBox(height: 10),
              Text(
                'Tableau vide pour le moment',
                style: TextStyle(
                  color: Color(0xFF334155),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Aucune association retournee par la requete.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: controller.associations.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
      itemBuilder: (context, index) => _AssociationRow(
        data: controller.associations[index],
        onEdit: _openEditDialog,
        onDelete: _confirmDelete,
      ),
    );
  }
}

class _AssociationsTableHeader extends StatelessWidget {
  const _AssociationsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: const [
          Expanded(flex: 28, child: _HeadText('Nom')),
          Expanded(flex: 17, child: _HeadText('Admin')),
          Expanded(flex: 10, child: _HeadText('Budget')),
          Expanded(flex: 14, child: _HeadText('Statut')),
          Expanded(flex: 15, child: _HeadText('Membres')),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerRight,
              child: _HeadText('Actions'),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadText extends StatelessWidget {
  const _HeadText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF334155),
      ),
    );
  }
}

class _AssociationRow extends StatelessWidget {
  const _AssociationRow({
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  final AssociationModel data;
  final ValueChanged<AssociationModel> onEdit;
  final ValueChanged<AssociationModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data.email.isNotEmpty)
                  Text(
                    data.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 17,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.adminName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.adminName == 'Pas d\'admin'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (data.adminEmail.isNotEmpty)
                  Text(
                    data.adminEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 10,
            child: Text(
              data.budgetLabel,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: data.verified
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  data.verified ? 'Verifiee' : 'En attente',
                  style: TextStyle(
                    color:
                        data.verified ? Colors.white : const Color(0xFF334155),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 14, color: Color(0xFF475569)),
                const SizedBox(width: 6),
                Text(
                  '${data.membersCount} membres',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () {
                    Get.snackbar(
                      'Associations',
                      'documentId: ${data.documentId}',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.open_in_new,
                      size: 16, color: Color(0xFF334155)),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onEdit(data),
                  icon: const Icon(Icons.edit_outlined,
                      size: 16, color: Color(0xFF334155)),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onDelete(data),
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: Color(0xFFEF4444)),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateAssociationDialog extends StatefulWidget {
  const _CreateAssociationDialog({
    required this.adminOptions,
    this.initialData,
    this.title = 'Nouvelle association',
    this.subtitle = 'Ajoutez une nouvelle association au systeme.',
    this.submitLabel = 'Enregistrer',
  });

  final List<UserOption> adminOptions;
  final AssociationModel? initialData;
  final String title;
  final String subtitle;
  final String submitLabel;

  @override
  State<_CreateAssociationDialog> createState() =>
      _CreateAssociationDialogState();
}

class _CreateAssociationDialogState extends State<_CreateAssociationDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _webController;
  late final TextEditingController _budgetController;

  String? _admin;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialData;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _descController = TextEditingController(text: initial?.description ?? '');
    _emailController = TextEditingController(text: initial?.email ?? '');
    _phoneController = TextEditingController(text: initial?.phone ?? '');
    _webController = TextEditingController(text: initial?.website ?? '');
    _budgetController = TextEditingController(
      text: initial != null
          ? (initial.budgetValue % 1 == 0
              ? initial.budgetValue.toStringAsFixed(0)
              : initial.budgetValue.toStringAsFixed(2))
          : '0',
    );

    _admin = initial?.adminId != null ? '${initial!.adminId}' : null;

    if (_admin != null &&
        !widget.adminOptions.any((u) => '${u.id}' == _admin)) {
      _admin = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _webController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFD6DFEA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                InkWell(
                  onTap: Get.back,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child:
                        Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            _fieldLabel("Nom de l'association"),
            const SizedBox(height: 4),
            _input(controller: _nameController, hint: 'ASBL Dev'),
            const SizedBox(height: 10),
            _fieldLabel('Description'),
            const SizedBox(height: 4),
            _input(
              controller: _descController,
              hint: "Description de l'association...",
              maxLines: 2,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Email'),
                      const SizedBox(height: 4),
                      _input(
                        controller: _emailController,
                        hint: 'contact@assoc.com',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Telephone'),
                      const SizedBox(height: 4),
                      _input(controller: _phoneController, hint: '+212...'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _fieldLabel('Site Web'),
            const SizedBox(height: 4),
            _input(controller: _webController, hint: 'https://...'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Budget initial'),
                      const SizedBox(height: 4),
                      _input(controller: _budgetController, hint: '0'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Administrateur principal'),
                      const SizedBox(height: 4),
                      _adminDropdown(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1664FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.submitLabel,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar(
        'Associations',
        'Le nom est obligatoire',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final payload = AssociationFormPayload(
      name: name,
      description: _descController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      website: _webController.text.trim(),
      budget: double.tryParse(_budgetController.text.trim()) ?? 0,
      adminId: int.tryParse(_admin ?? ''),
    );

    Get.back(result: payload);
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF334155),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE4EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF93C5FD)),
        ),
      ),
    );
  }

  Widget _adminDropdown() {
    return DropdownButtonFormField<String>(
      value: _admin,
      isExpanded: true,
      decoration: InputDecoration(
        hintText: 'Choisir un admin',
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE4EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF93C5FD)),
        ),
      ),
      items: widget.adminOptions
          .map(
            (u) => DropdownMenuItem(
              value: '${u.id}',
              child: Text(
                u.email.isEmpty ? u.name : '${u.name} (${u.email})',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _admin = v),
    );
  }
}
