import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:flutter_getx_app/controllers/assignments_controller.dart';
import 'package:flutter_getx_app/models/assignment_model.dart';
import 'package:flutter_getx_app/views/assignments/assignment_form_page.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class AssignmentDetailsPage extends GetView<AssignmentsController> {
  static const int _studentAssignmentsMenuIndex = 14;

  final Assignment assignment;

  const AssignmentDetailsPage({super.key, required this.assignment});

  static const Color _pageBg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _primary = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
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
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 18),
                              _buildSummaryRow(),
                              const SizedBox(height: 18),
                              _buildInstructionsCard(),
                              if (_hasAttachment) ...[
                                const SizedBox(height: 14),
                                _buildAttachmentCard(),
                              ],
                              const SizedBox(height: 14),
                              _buildSubmissionsCard(),
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
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isStudentMode = Get.isRegistered<HomeController>() &&
        Get.find<HomeController>().selectedMenu.value ==
            _studentAssignmentsMenuIndex;

    return Row(
      children: [
        IconButton(
          onPressed: () => Get.back(),
          splashRadius: 18,
          icon: const Icon(Icons.arrow_back, size: 18),
          color: const Color(0xFF111827),
        ),
        const Icon(Icons.description_outlined, color: _primary, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Détails du devoir',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        if (!isStudentMode) ...[
          _iconAction(
            icon: Icons.edit_outlined,
            color: const Color(0xFF334155),
            onTap: () =>
                Get.to(() => AssignmentFormPage(assignment: assignment)),
          ),
          const SizedBox(width: 8),
          _iconAction(
            icon: Icons.delete_outline,
            color: const Color(0xFFF87171),
            onTap: () {
              Get.defaultDialog(
                title: 'Confirmer',
                middleText: 'Supprimer ce devoir ?',
                textCancel: 'Annuler',
                textConfirm: 'Supprimer',
                confirmTextColor: Colors.white,
                buttonColor: const Color(0xFFD32F2F),
                onConfirm: () async {
                  Get.back();
                  await controller.removeAssignment(assignment.id);
                  if (controller.errorMessage.value.isEmpty) {
                    Get.offNamed(Routes.DEVOIRS);
                  }
                },
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.calendar_today_outlined,
            label: 'Échéance',
            value: _formatDate(assignment.dueDate),
            footer: _formatTime(assignment.dueDate),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.military_tech_outlined,
            label: 'Points',
            value: assignment.maxPoints.toString(),
            footer: 'Maximum',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _summaryCard(
            icon: Icons.menu_book_outlined,
            label: 'Cours',
            value: assignment.courseName,
            footer: '',
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required String footer,
  }) {
    return Container(
      height: 118,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: const Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              height: 1,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            footer,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFEAF2FF),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Instructions',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Text(
              assignment.instructions.trim().isEmpty
                  ? 'Aucune instruction fournie'
                  : assignment.instructions,
              style: const TextStyle(
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsCard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: controller.fetchSubmittedStudentsForAssignment(assignment.id),
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final hasError = snapshot.hasError;
        final submissions = snapshot.data ?? const <Map<String, dynamic>>[];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border, style: BorderStyle.solid),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Soumissions',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isLoading)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF2FF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${submissions.length}',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (hasError)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Impossible de charger les soumissions.',
                    style: TextStyle(color: Color(0xFFB91C1C)),
                  ),
                )
              else if (submissions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border),
                  ),
                  child: const Text(
                    'Aucun étudiant n\'a encore soumis ce devoir',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: submissions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final item = submissions[index];
                    final studentName = _extractSubmissionStudentName(item);
                    final submittedAt = _extractSubmissionDate(item);
                    final status = _extractSubmissionStatus(item);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFEAF2FF),
                            child: Text(
                              _initialsFromName(studentName),
                              style: const TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  studentName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  submittedAt,
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                if (_extractSubmissionFileName(item) != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: InkWell(
                                      onTap: () =>
                                          _openSubmissionFileFromContent(item),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Text(
                                        _extractSubmissionFileName(item)!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _primary,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentCard() {
    final fileName = assignment.attachmentName ??
        _extractFileNameFromUrl(assignment.attachmentUrl) ??
        'Document joint';

    final sizeText = assignment.attachmentSizeKb != null
        ? '${assignment.attachmentSizeKb!.toStringAsFixed(2)} KB'
        : 'Fichier joint';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description_outlined, color: _primary, size: 18),
              SizedBox(width: 8),
              Text(
                'Pièce jointe',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                const Icon(Icons.insert_drive_file_outlined,
                    color: _primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sizeText,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: _downloadAttachment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Télécharger'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: IconButton(
          onPressed: onTap,
          splashRadius: 18,
          iconSize: 18,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  String _formatTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool get _hasAttachment {
    final url = assignment.attachmentUrl?.trim() ?? '';
    return url.isNotEmpty;
  }

  String? _extractFileNameFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url.trim());
    final segments = uri?.pathSegments;
    if (segments == null || segments.isEmpty) return null;
    return Uri.decodeComponent(segments.last);
  }

  String? _resolveAttachmentUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final normalized = rawUrl.trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    return 'http://localhost:3001$normalized';
  }

  Future<void> _downloadAttachment() async {
    final resolved = _resolveAttachmentUrl(assignment.attachmentUrl);
    if (resolved == null) {
      Get.snackbar('Erreur', 'Aucun document à télécharger');
      return;
    }

    final uri = Uri.tryParse(resolved);
    if (uri == null) {
      Get.snackbar('Erreur', 'Lien de téléchargement invalide');
      return;
    }

    var launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!launched) {
      Get.snackbar('Erreur', 'Impossible d’ouvrir le document');
    }
  }

  Map<String, dynamic> _extractNode(Map<String, dynamic> raw) {
    if (raw.containsKey('data')) {
      final nested = raw['data'];
      if (nested is Map<String, dynamic>) {
        return _extractNode(nested);
      }
    }

    final attributes = raw['attributes'];
    if (attributes is Map<String, dynamic>) {
      return {
        'id': raw['id'] ?? attributes['id'],
        ...attributes,
      };
    }

    return raw;
  }

  Map<String, dynamic>? _extractNodeIfMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return _extractNode(raw);
    }
    return null;
  }

  String _extractSubmissionStudentName(Map<String, dynamic> submission) {
    final node = _extractNode(submission);
    final studentNode = _extractNodeIfMap(node['student']);

    final firstName =
        (studentNode?['firstname'] ?? studentNode?['firstName'] ?? '')
            .toString()
            .trim();
    final lastName =
        (studentNode?['lastname'] ?? studentNode?['lastName'] ?? '')
            .toString()
            .trim();
    final username = (studentNode?['username'] ?? '').toString().trim();
    final email = (studentNode?['email'] ?? '').toString().trim();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email;
    return 'Étudiant';
  }

  String _extractSubmissionDate(Map<String, dynamic> submission) {
    final node = _extractNode(submission);
    final raw = (node['submittedAt'] ?? node['createdAt'] ?? '').toString();
    final parsed = DateTime.tryParse(raw)?.toLocal();
    if (parsed == null) {
      return 'Date inconnue';
    }
    return '${_formatDate(parsed)} à ${_formatTime(parsed)}';
  }

  String _extractSubmissionStatus(Map<String, dynamic> submission) {
    final node = _extractNode(submission);
    final raw = (node['status'] ?? '').toString().trim();
    if (raw.isEmpty) {
      return 'Soumis';
    }
    return raw;
  }

  String? _extractSubmissionFileUrl(Map<String, dynamic> submission) {
    final node = _extractNode(submission);
    final content = (node['content'] ?? '').toString();
    if (content.trim().isEmpty) return null;

    final match =
        RegExp(r'https?://[^\s)]+', caseSensitive: false).firstMatch(content);
    if (match == null) return null;

    final url = content.substring(match.start, match.end).trim();
    return url.isEmpty ? null : url;
  }

  String? _extractSubmissionFileName(Map<String, dynamic> submission) {
    final node = _extractNode(submission);
    final content = (node['content'] ?? '').toString();
    if (content.trim().isEmpty) return null;

    final nameMatch = RegExp(r'Fichier:\s*([^\n(]+)', caseSensitive: false)
        .firstMatch(content);
    if (nameMatch != null) {
      final name = nameMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    final url = _extractSubmissionFileUrl(submission);
    if (url == null) return null;

    final uri = Uri.tryParse(url);
    final segments = uri?.pathSegments;
    if (segments == null || segments.isEmpty) return null;
    return Uri.decodeComponent(segments.last);
  }

  Future<void> _openSubmissionFileFromContent(
      Map<String, dynamic> submission) async {
    final url = _extractSubmissionFileUrl(submission);
    if (url == null || url.trim().isEmpty) {
      Get.snackbar(
          'Erreur', 'Aucun fichier joint trouvé pour cette soumission');
      return;
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      Get.snackbar('Erreur', 'Lien de fichier invalide');
      return;
    }

    var launched = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!launched) {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    if (!launched) {
      Get.snackbar('Erreur', 'Impossible d\'ouvrir le fichier');
    }
  }

  String _initialsFromName(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    return '$first$last';
  }
}
