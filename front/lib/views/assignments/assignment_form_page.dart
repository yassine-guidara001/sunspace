import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_getx_app/controllers/assignments_controller.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

class AssignmentFormPage extends StatefulWidget {
  final Assignment? assignment;

  const AssignmentFormPage({super.key, this.assignment});

  @override
  State<AssignmentFormPage> createState() => _AssignmentFormPageState();
}

class _AssignmentFormPageState extends State<AssignmentFormPage> {
  static const Color _pageBg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFF757575);
  static const Color _primary = Color(0xFF1565C0);
  static const Color _cardBg = Colors.white;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _dueDateCtrl;
  late final TextEditingController _maxPointsCtrl;
  late final TextEditingController _passingGradeCtrl;

  final RxnInt _selectedCourseId = RxnInt();
  final RxBool _allowLateSubmission = false.obs;

  DateTime? _dueDateValue;
  Map<String, dynamic>? _selectedAttachment;
  String? _selectedAttachmentName;
  bool _clearExistingAttachment = false;

  bool get _isEditMode => widget.assignment != null;

  @override
  void initState() {
    super.initState();

    final assignment = widget.assignment;

    _titleCtrl = TextEditingController(text: assignment?.title ?? '');
    _instructionsCtrl =
        TextEditingController(text: assignment?.instructions ?? '');
    _maxPointsCtrl =
        TextEditingController(text: '${assignment?.maxPoints ?? 100}');
    _passingGradeCtrl =
        TextEditingController(text: '${assignment?.passingGrade ?? 0}');

    _dueDateValue = assignment?.dueDate;
    _dueDateCtrl = TextEditingController(
      text: assignment != null ? _formatDateTime(assignment.dueDate) : '',
    );

    _selectedCourseId.value = assignment?.courseId;
    _allowLateSubmission.value = assignment?.allowLateSubmission ?? false;
    _selectedAttachmentName = assignment?.attachmentName ??
        _extractFileNameFromUrl(assignment?.attachmentUrl);

    Get.find<AssignmentsController>().fetchCourses();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _dueDateCtrl.dispose();
    _maxPointsCtrl.dispose();
    _passingGradeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AssignmentsController>();

    return Scaffold(
      backgroundColor: _pageBg,
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                const DashboardTopBar(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back, size: 18),
                              splashRadius: 18,
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.description_outlined,
                                color: _primary, size: 24),
                            const SizedBox(width: 6),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditMode
                                      ? 'Modifier le Devoir'
                                      : 'Nouveau Devoir',
                                  style: const TextStyle(
                                    height: 1.02,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isEditMode
                                      ? 'Modifiez les détails du devoir'
                                      : 'Créez un nouveau devoir pour vos étudiants',
                                  style: const TextStyle(
                                    color: _muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: SingleChildScrollView(
                              child: Container(
                                width: 780,
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: _cardBg,
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 14,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFEAF2FF),
                                          border: Border(
                                            bottom: BorderSide(color: _border),
                                          ),
                                          borderRadius: BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          _isEditMode
                                              ? 'Informations du devoir'
                                              : 'Créer un devoir',
                                          style: const TextStyle(
                                            height: 1,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          12,
                                          18,
                                          12,
                                        ),
                                        child: Obx(
                                          () => Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const _FormLabel(
                                                  'Titre du devoir *'),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _titleCtrl,
                                                decoration: _fieldDecoration(
                                                  'Ex: TP1 - Introduction à React',
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Titre requis';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 12),
                                              const _FormLabel(
                                                  'Cours associé *'),
                                              const SizedBox(height: 6),
                                              DropdownButtonFormField<int?>(
                                                initialValue:
                                                    _selectedCourseId.value,
                                                items: [
                                                  const DropdownMenuItem<int?>(
                                                    value: null,
                                                    child: Text(
                                                      'Sélectionner un cours',
                                                    ),
                                                  ),
                                                  ...controller.courses.map(
                                                    (course) =>
                                                        DropdownMenuItem<int?>(
                                                      value: course.id,
                                                      child: Text(course.title),
                                                    ),
                                                  ),
                                                ],
                                                onChanged: (value) =>
                                                    _selectedCourseId.value =
                                                        value,
                                                decoration: _fieldDecoration(
                                                  'Sélectionner un cours',
                                                ),
                                                validator: (value) {
                                                  if (value == null) {
                                                    return 'Cours requis';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Choisissez le cours auquel ce devoir appartient',
                                                style: TextStyle(
                                                  color: _muted,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const _FormLabel(
                                                  'Instructions *'),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _instructionsCtrl,
                                                minLines: 6,
                                                maxLines: 6,
                                                decoration: _fieldDecoration(
                                                  'Décrivez les objectifs, les consignes et les critères d\'évaluation du devoir...',
                                                ),
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.trim().isEmpty) {
                                                    return 'Instructions requises';
                                                  }
                                                  return null;
                                                },
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Fournissez des instructions claires pour les étudiants',
                                                style: TextStyle(
                                                  color: _muted,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const _FormLabel(
                                                          'Date d\'échéance *',
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        TextFormField(
                                                          controller:
                                                              _dueDateCtrl,
                                                          readOnly: true,
                                                          onTap: _pickDueDate,
                                                          decoration:
                                                              _fieldDecoration(
                                                            'jj / mm / aaaa --:--',
                                                          ).copyWith(
                                                            suffixIcon:
                                                                const Icon(
                                                              Icons
                                                                  .calendar_today,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          validator: (_) {
                                                            if (_dueDateValue ==
                                                                null) {
                                                              return 'Date requise';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        const Text(
                                                          'Date limite de soumission',
                                                          style: TextStyle(
                                                            color: _muted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const _FormLabel(
                                                          'Points maximum *',
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        TextFormField(
                                                          controller:
                                                              _maxPointsCtrl,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          decoration:
                                                              _fieldDecoration(
                                                            '100',
                                                          ),
                                                          validator: (value) {
                                                            if (value == null ||
                                                                value
                                                                    .trim()
                                                                    .isEmpty) {
                                                              return 'Valeur requise';
                                                            }
                                                            if (int.tryParse(
                                                                    value) ==
                                                                null) {
                                                              return 'Nombre invalide';
                                                            }
                                                            return null;
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        const Text(
                                                          'Note maximale possible',
                                                          style: TextStyle(
                                                            color: _muted,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              const _FormLabel(
                                                'Note de passage (optionnel)',
                                              ),
                                              const SizedBox(height: 6),
                                              TextFormField(
                                                controller: _passingGradeCtrl,
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration:
                                                    _fieldDecoration('0'),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Note minimale requise pour réussir le devoir',
                                                style: TextStyle(
                                                  color: _muted,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(
                                                    color: _border,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Checkbox(
                                                      value:
                                                          _allowLateSubmission
                                                              .value,
                                                      onChanged: (v) =>
                                                          _allowLateSubmission
                                                                  .value =
                                                              v ?? false,
                                                      visualDensity:
                                                          VisualDensity.compact,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            'Autoriser les soumissions en retard',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
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
                                              const _FormLabel(
                                                'Pièce jointe (Optionnel)',
                                              ),
                                              const SizedBox(height: 6),
                                              InkWell(
                                                onTap: _pickAttachment,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  height: 64,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFEAF2FF),
                                                    border: Border.all(
                                                        color: _border),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10),
                                                  child:
                                                      _selectedAttachmentName ==
                                                              null
                                                          ? const Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Icon(
                                                                    Icons
                                                                        .upload_file,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .black54),
                                                                SizedBox(
                                                                    height: 2),
                                                                Text(
                                                                  'Télécharger un document',
                                                                ),
                                                              ],
                                                            )
                                                          : Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .attach_file_rounded,
                                                                  size: 18,
                                                                  color: Color(
                                                                      0xFF334155),
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Expanded(
                                                                  child: Text(
                                                                    _selectedAttachmentName!,
                                                                    maxLines: 1,
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                    style:
                                                                        const TextStyle(
                                                                      color: Color(
                                                                          0xFF1E293B),
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                    ),
                                                                  ),
                                                                ),
                                                                IconButton(
                                                                  onPressed:
                                                                      _removeAttachment,
                                                                  icon:
                                                                      const Icon(
                                                                    Icons.close,
                                                                    size: 16,
                                                                    color: Color(
                                                                        0xFF64748B),
                                                                  ),
                                                                  splashRadius:
                                                                      16,
                                                                  tooltip:
                                                                      'Retirer la pièce jointe',
                                                                ),
                                                              ],
                                                            ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Formats acceptés : PDF, Word, PowerPoint, TXT, ZIP',
                                                style: TextStyle(
                                                  color: _muted,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, color: _border),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 32,
                                              child: OutlinedButton(
                                                onPressed: () => Get.back(),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor:
                                                      const Color(0xFF334155),
                                                  side: const BorderSide(
                                                      color: _border),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            7),
                                                  ),
                                                ),
                                                child: const Text('Annuler'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: SizedBox(
                                                height: 32,
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _submit(controller),
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                    size: 16,
                                                  ),
                                                  label: Text(
                                                    _isEditMode
                                                        ? 'Enregistrer les modifications'
                                                        : 'Créer le devoir',
                                                  ),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: _primary,
                                                    foregroundColor:
                                                        Colors.white,
                                                    elevation: 0,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              7),
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

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDateValue ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 5),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    final value = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      _dueDateValue = value;
      _dueDateCtrl.text = _formatDateTime(value);
    });
  }

  Future<void> _submit(AssignmentsController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final selectedCourse = controller.courses
        .firstWhereOrNull((course) => course.id == _selectedCourseId.value);
    final selectedCourseDocumentId = selectedCourse?.documentId.trim() ?? '';
    final selectedCourseReference = selectedCourseDocumentId.isNotEmpty
        ? selectedCourseDocumentId
        : _selectedCourseId.value;

    int? attachmentId;
    String? attachmentUrl;

    if (_selectedAttachment != null) {
      final uploadResult =
          await controller.uploadAttachment(_selectedAttachment!);
      if (uploadResult == null) {
        return;
      }
      attachmentId = uploadResult['id'] as int?;
      attachmentUrl = uploadResult['url']?.toString();
    } else if (_isEditMode && !_clearExistingAttachment) {
      attachmentId = widget.assignment?.attachmentId;
      attachmentUrl = widget.assignment?.attachmentUrl;
    }

    final payload = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'course': selectedCourseReference,
      'courseId': _selectedCourseId.value,
      'description': _instructionsCtrl.text.trim(),
      'dueDate': _dueDateValue?.toIso8601String(),
      'maxPoints': int.tryParse(_maxPointsCtrl.text.trim()) ?? 100,
      'passingGrade': int.tryParse(_passingGradeCtrl.text.trim()) ?? 0,
      'allowLateSubmission': _allowLateSubmission.value,
      if (_selectedAttachment != null || _isEditMode)
        'attachmentId': attachmentId,
      'attachmentUrl': attachmentUrl,
    };

    final success = _isEditMode
        ? await controller.editAssignment(
            widget.assignment!.id,
            payload,
            documentId: widget.assignment!.documentId,
          )
        : await controller.addAssignment(payload);

    if (mounted && success) {
      Get.offNamed(Routes.DEVOIRS);
    }
  }

  static InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFFBFDFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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

  String _formatDateTime(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year;
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }

  Future<void> _pickAttachment() async {
    try {
      final result = await _pickAttachmentFile();

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.single;
      final rawBytes = picked.bytes;
      final streamBytes = (rawBytes == null || rawBytes.isEmpty)
          ? await _readBytesFromStream(picked.readStream)
          : null;
      final resolvedBytes =
          (rawBytes != null && rawBytes.isNotEmpty) ? rawBytes : streamBytes;

      final path = _safePath(picked);

      final hasBytes = resolvedBytes != null && resolvedBytes.isNotEmpty;
      final hasPath = path != null && path.isNotEmpty;

      if (!hasBytes && !hasPath) {
        Get.snackbar('Erreur', 'Impossible de lire le fichier sélectionné');
        return;
      }

      if (!mounted) return;
      setState(() {
        _selectedAttachment = {
          'name': picked.name,
          if (hasBytes) 'bytes': resolvedBytes,
          if (hasPath) 'path': path,
        };
        _selectedAttachmentName = picked.name;
        _clearExistingAttachment = false;
      });
    } catch (e) {
      debugPrint('[AssignmentForm] file pick error: $e');
      Get.snackbar('Erreur', 'Sélection du fichier échouée');
    }
  }

  Future<FilePickerResult?> _pickAttachmentFile() async {
    const allowedExtensions = <String>[
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'txt',
      'zip',
    ];

    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowedExtensions: allowedExtensions,
      );
    } catch (firstError) {
      debugPrint('[AssignmentForm] pickFiles(withData) failed: $firstError');
      return FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
    }
  }

  Future<Uint8List?> _readBytesFromStream(Stream<List<int>>? stream) async {
    if (stream == null) return null;

    try {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(chunk);
      }

      if (chunks.isEmpty) return null;
      return Uint8List.fromList(chunks);
    } catch (e) {
      debugPrint('[AssignmentForm] readStream failed: $e');
      return null;
    }
  }

  String? _safePath(PlatformFile file) {
    try {
      final path = file.path?.trim();
      if (path == null || path.isEmpty) return null;
      return path;
    } catch (_) {
      return null;
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedAttachment = null;
      _selectedAttachmentName = null;
      _clearExistingAttachment = true;
    });
  }

  String? _extractFileNameFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    final segments = uri?.pathSegments;
    if (segments == null || segments.isEmpty) return null;
    return segments.last;
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
