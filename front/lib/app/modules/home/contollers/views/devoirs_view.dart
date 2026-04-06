import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/course_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';

class DevoirsView extends StatelessWidget {
  const DevoirsView({super.key});

  static const _pageBg = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(),
                Expanded(child: _DevoirsPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DevoirsPage extends StatefulWidget {
  const _DevoirsPage();

  @override
  State<_DevoirsPage> createState() => _DevoirsPageState();
}

class _DevoirsPageState extends State<_DevoirsPage> {
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF64748B);
  static const Color _primary = Color(0xFF1D6FF2);

  final TextEditingController _searchCtrl = TextEditingController();

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _instructionsCtrl = TextEditingController();
  final TextEditingController _dueDateCtrl = TextEditingController();
  final TextEditingController _maxPointsCtrl =
      TextEditingController(text: '100');
  final TextEditingController _passScoreCtrl = TextEditingController(text: '0');

  final RxnInt _selectedCourseId = RxnInt();
  final RxBool _allowLate = false.obs;

  bool _isCreateMode = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _dueDateCtrl.dispose();
    _maxPointsCtrl.dispose();
    _passScoreCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _isCreateMode ? _buildCreateSheet() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_outlined, color: _primary, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Devoirs',
                      style: TextStyle(
                        height: 1.02,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Gérez les devoirs et les évaluations',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton.icon(
                onPressed: _startCreateMode,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau Devoir'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Rechercher un devoir...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _border),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _border)),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: _HeadCell('Titre')),
                      Expanded(flex: 2, child: _HeadCell('Cours')),
                      Expanded(flex: 2, child: _HeadCell('Échéance')),
                      Expanded(flex: 2, child: _HeadCell('Points')),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _HeadCell('Actions'),
                        ),
                      ),
                    ],
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Aucun devoir trouvé',
                      style: TextStyle(color: Color(0xFF94A3B8), ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateSheet() {
    final courseController = Get.find<CourseController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _exitCreateMode,
              icon: const Icon(Icons.arrow_back, size: 20),
              splashRadius: 18,
            ),
            const SizedBox(width: 4),
            const Icon(Icons.description_outlined, color: _primary, size: 30),
            const SizedBox(width: 8),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nouveau Devoir',
                  style: TextStyle(
                    height: 1.02,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Créez un nouveau devoir pour vos étudiants',
                  style: TextStyle(color: _muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              child: Container(
                width: 760,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF2FF),
                        border: Border(bottom: BorderSide(color: _border)),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Créer un devoir',
                        style: TextStyle(
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                      child: Obx(
                        () => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FormLabel('Titre du devoir *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _titleCtrl,
                              decoration: _fieldDecoration(
                                'Ex: TP1 - Introduction à React',
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _FormLabel('Cours associé *'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int?>(
                              value: _selectedCourseId.value,
                              items: [
                                const DropdownMenuItem<int?>(
                                  value: null,
                                  child: Text('Sélectionner un cours'),
                                ),
                                ...courseController.courses.map(
                                  (course) => DropdownMenuItem<int?>(
                                    value: course.id,
                                    child: Text(course.title),
                                  ),
                                ),
                              ],
                              onChanged: (value) =>
                                  _selectedCourseId.value = value,
                              decoration:
                                  _fieldDecoration('Sélectionner un cours'),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Choisissez le cours auquel ce devoir appartient',
                              style: TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 12),
                            const _FormLabel('Instructions *'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _instructionsCtrl,
                              minLines: 5,
                              maxLines: 5,
                              decoration: _fieldDecoration(
                                'Décrivez les objectifs, les consignes et les critères d\'évaluation du devoir...',
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Fournissez des instructions claires pour les étudiants',
                              style: TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FormLabel('Date d\'échéance *'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _dueDateCtrl,
                                        decoration: _fieldDecoration(
                                          'jj / mm / aaaa --:--',
                                        ).copyWith(
                                          suffixIcon: const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Date limite de soumission',
                                        style: TextStyle(
                                            color: _muted),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const _FormLabel('Points maximum *'),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _maxPointsCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: _fieldDecoration('100'),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Note maximale possible',
                                        style: TextStyle(
                                            color: _muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const _FormLabel('Note de passage (optionnel)'),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: _fieldDecoration('0'),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Note minimale requise pour réussir le devoir',
                              style: TextStyle(color: _muted),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _allowLate.value,
                                    onChanged: (v) =>
                                        _allowLate.value = v ?? false,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Autoriser les soumissions en retard',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Les étudiants pourront soumettre après la date d\'échéance',
                                          style: TextStyle(
                                            color: _muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const _FormLabel('Pièce jointe (Optionnel)'),
                            const SizedBox(height: 6),
                            Container(
                              height: 64,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file,
                                      size: 16, color: Colors.black54),
                                  SizedBox(height: 2),
                                  Text(
                                    'Télécharger un document',
                                    style: TextStyle(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Formats acceptés: PDF, Word, PowerPoint, TXT, ZIP',
                              style: TextStyle(color: _muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: _border),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 34,
                            child: OutlinedButton(
                              onPressed: _exitCreateMode,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF334155),
                                side: const BorderSide(color: _border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: const Text('Annuler'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 34,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Get.snackbar(
                                    'Succès',
                                    'Devoir créé (maquette UI)',
                                    snackPosition: SnackPosition.BOTTOM,
                                  );
                                  _exitCreateMode();
                                },
                                icon: const Icon(Icons.add_circle_outline,
                                    size: 16),
                                label: const Text('Créer le devoir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startCreateMode() async {
    final courseController = Get.find<CourseController>();
    await courseController.fetchCourses();

    setState(() {
      _isCreateMode = true;
    });
  }

  void _exitCreateMode() {
    setState(() {
      _isCreateMode = false;
    });
  }

  static InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(7),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1),
      ),
    );
  }
}

class _HeadCell extends StatelessWidget {
  final String text;

  const _HeadCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String text;

  const _FormLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }
}
