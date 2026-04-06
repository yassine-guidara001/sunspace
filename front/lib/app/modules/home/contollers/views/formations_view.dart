import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:get/get.dart';
import 'custom_sidebar.dart';

class FormationsView extends GetView<HomeController> {
  const FormationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 18),
                        _buildSearchBar(),
                        const SizedBox(height: 16),
                        _buildEmptyTable(),
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

  Widget _buildTopBar() {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                isDense: true,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF475569), size: 20),
          ),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, size: 16, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          const Text(
            'intern',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    color: Color(0xFF2563EB), size: 28),
                SizedBox(width: 10),
                Text(
                  'Mes Formations',
                  style: TextStyle(
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Gérez vos cours, modules et leçons',
              style: TextStyle(color: Color(0xFF6B7280), ),
            ),
          ],
        ),
        SizedBox(
          height: 42,
          child: ElevatedButton.icon(
            onPressed: () => _showCreateCourseDialog(context),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text('Nouveau Cours'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066D9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateCourseDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    String selectedLevel = 'Débutant';
    String selectedStatus = 'Brouillon';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: StatefulBuilder(
            builder: (context, setState) {
              return Container(
                width: 430,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Créer un nouveau cours',
                          style: TextStyle(
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close,
                              size: 16, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Remplissez les détails ci-dessous pour créer un nouveau cours.',
                      style: TextStyle(color: Color(0xFF6B7280), ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Titre du cours',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: _dialogInputDecoration('Introduction au...'),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Description',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: _dialogInputDecoration(
                          'Une brève description du cours...'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Niveau',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: selectedLevel,
                                isDense: true,
                                icon: const Icon(Icons.keyboard_arrow_down,
                                    size: 16, color: Color(0xFF9CA3AF)),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Débutant',
                                      child: Text('Débutant')),
                                  DropdownMenuItem(
                                      value: 'Intermédiaire',
                                      child: Text('Intermédiaire')),
                                  DropdownMenuItem(
                                      value: 'Avancé', child: Text('Avancé')),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => selectedLevel = value);
                                  }
                                },
                                decoration: _dialogInputDecoration(null),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Prix (TND)',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827)),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: priceController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                decoration: _dialogInputDecoration('0'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Statut',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 155,
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            size: 16, color: Color(0xFF9CA3AF)),
                        items: const [
                          DropdownMenuItem(
                              value: 'Brouillon', child: Text('Brouillon')),
                          DropdownMenuItem(
                              value: 'Publié', child: Text('Publié')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => selectedStatus = value);
                          }
                        },
                        decoration: _dialogInputDecoration(null),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        height: 34,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066D9),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text(
                            'Créer le cours',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _dialogInputDecoration(String? hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Rechercher un cours...',
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), ),
          prefixIcon: const Icon(Icons.search, size: 18, color: Colors.grey),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: const [
                Expanded(flex: 3, child: _HeaderCell('Titre')),
                Expanded(flex: 2, child: _HeaderCell('Niveau')),
                Expanded(flex: 2, child: _HeaderCell('Prix')),
                Expanded(flex: 2, child: _HeaderCell('Statut')),
                Expanded(flex: 2, child: _HeaderCell('Créé le')),
                Expanded(flex: 1, child: _HeaderCell('Actions')),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Text(
              'Aucun cours trouvé',
              style: TextStyle(color: Color(0xFF64748B), ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  const _HeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
        ),
    );
  }
}
