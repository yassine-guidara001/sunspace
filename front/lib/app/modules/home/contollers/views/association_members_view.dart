import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AssociationMembersView extends StatefulWidget {
  const AssociationMembersView({super.key});

  @override
  State<AssociationMembersView> createState() => _AssociationMembersViewState();
}

class _AssociationMembersViewState extends State<AssociationMembersView> {
  static const String _baseUrl = 'http://localhost:3001/api';

  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _allUsers = [];
  String? _assocDocId;
  String? _assocName;
  String _search = '';
  int _selectedFilter = 0; // 0=tous 1=admins 2=membres

  Map<String, String> get _headers {
    try {
      return Get.find<AuthService>().authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  int get _userId {
    try {
      final u = Get.find<StorageService>().getUserData();
      final raw = u?['id'];
      if (raw is int) return raw;
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String get _currentUserEmail {
    try {
      final u = Get.find<StorageService>().getUserData();
      return u?['email']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      // 1. GET /associations?filters[admin][id][$eq]=userId&populate=*
      final assocRes = await http.get(
        Uri.parse(
            '$_baseUrl/associations?filters%5Badmin%5D%5Bid%5D%5B%24eq%5D=$_userId&populate=*'),
        headers: _headers,
      );
      if (assocRes.statusCode == 200) {
        final List assocData = jsonDecode(assocRes.body)['data'] ?? [];
        if (assocData.isNotEmpty) {
          final assoc = assocData.first as Map<String, dynamic>;
          _assocDocId =
              assoc['documentId']?.toString() ?? assoc['id']?.toString();
          _assocName = assoc['name']?.toString() ?? 'Association';

          // 2. GET /associations/{documentId}?populate[members][populate]=*
          if (_assocDocId != null) {
            final membersRes = await http.get(
              Uri.parse(
                  '$_baseUrl/associations/$_assocDocId?populate%5Bmembers%5D%5Bpopulate%5D=*'),
              headers: _headers,
            );
            if (membersRes.statusCode == 200) {
              final mBody = jsonDecode(membersRes.body);
              final mData = mBody['data'] ?? mBody;
              final raw = mData['members'];
              if (raw is List) _members = raw.cast<Map<String, dynamic>>();
            }
          }
        }
      }

      // 3. GET /users?populate=*
      final usersRes = await http.get(Uri.parse('$_baseUrl/users?populate=*'),
          headers: _headers);
      if (usersRes.statusCode == 200) {
        final uBody = jsonDecode(usersRes.body);
        final List uList = uBody is List ? uBody : (uBody['data'] ?? []);
        _allUsers = uList.cast<Map<String, dynamic>>();
      }

      _applyFilter();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> base = List.from(_members);
    if (_selectedFilter == 1) base = base.where(_isAdmin).toList();
    if (_selectedFilter == 2) base = base.where((m) => !_isAdmin(m)).toList();
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      base = base
          .where((m) =>
              _name(m).toLowerCase().contains(q) ||
              _email(m).toLowerCase().contains(q))
          .toList();
    }
    setState(() => _filtered = base);
  }

  bool _isAdmin(Map<String, dynamic> m) {
    final role = m['role']?['name']?.toString().toLowerCase() ?? '';
    return role.contains('admin');
  }

  bool _isMe(Map<String, dynamic> m) => _email(m) == _currentUserEmail;

  String _name(Map<String, dynamic> m) {
    final un = m['username']?.toString() ?? '';
    final fn = '${m['firstName'] ?? ''} ${m['lastName'] ?? ''}'.trim();
    return fn.isNotEmpty ? fn : (un.isNotEmpty ? un : 'Inconnu');
  }

  String _email(Map<String, dynamic> m) => m['email']?.toString() ?? '';

  String _joinDate(Map<String, dynamic> m) {
    final raw = m['createdAt']?.toString() ?? '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return 'Depuis ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Color _avatarBg(Map<String, dynamic> m) {
    final isAdm = _isAdmin(m);
    if (_isMe(m)) return const Color(0xFF7C3AED);
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];
    return isAdm
        ? const Color(0xFF7C3AED)
        : colors[_name(m).hashCode.abs() % colors.length];
  }

  int get _adminCount => _members.where(_isAdmin).length;
  int get _memberCount => _members.where((m) => !_isAdmin(m)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FC),
      body: Row(children: [
        const CustomSidebar(),
        Expanded(
          child: Column(children: [
            const DashboardTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('MEMBRES',
                                  style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 28,
                                      letterSpacing: -0.3)),
                              Text('Association : ${_assocName ?? '...'}',
                                  style: const TextStyle(
                                      color: Color(0xFF64748B), fontSize: 13)),
                            ]),
                        Row(children: [
                          // Bouton Invitation
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await showDialog<Map<String, dynamic>>(
                                context: context,
                                builder: (_) => _InvitationDialog(
                                  allUsers: _allUsers,
                                  currentMembers: _members,
                                  assocDocId: _assocDocId,
                                  headers: _headers,
                                ),
                              );
                              if (result != null) {
                                setState(() {
                                  _members.add(result);
                                  _applyFilter();
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invitation envoyée !'),
                                    backgroundColor: Color(0xFF22C55E),
                                  ),
                                );
                              }
                            },
                            icon:
                                const Icon(Icons.person_add_outlined, size: 15),
                            label: const Text('INVITATION',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B6BFF),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Refresh
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: const Color(0xFFE2E8F0))),
                            child: IconButton(
                              onPressed: _loadAll,
                              icon: const Icon(Icons.refresh,
                                  color: Color(0xFF64748B), size: 16),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Stats ──────────────────────────────────────────
                    Row(children: [
                      Expanded(
                          child: _statCard('TOTAL', '${_members.length}',
                              const Color(0xFF0F172A))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('ADMINS', '$_adminCount',
                              const Color(0xFFA855F7))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _statCard('MEMBRES', '$_memberCount',
                              const Color(0xFF3B82F6))),
                    ]),
                    const SizedBox(height: 20),

                    // ── Search + Filtres ───────────────────────────────
                    Row(children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            onChanged: (v) {
                              _search = v;
                              _applyFilter();
                            },
                            decoration: const InputDecoration(
                              hintText: 'Rechercher par nom ou email...',
                              hintStyle: TextStyle(
                                  color: Color(0xFF94A3B8), fontSize: 13),
                              prefixIcon: Icon(Icons.search,
                                  size: 18, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _filterBtn('TOUS', 0),
                      const SizedBox(width: 6),
                      _filterBtn('ADMINS', 1),
                      const SizedBox(width: 6),
                      _filterBtn('MEMBRES', 2),
                    ]),
                    const SizedBox(height: 20),

                    // ── Content ────────────────────────────────────────
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFF0B6BFF))));
    }
    if (_assocDocId == null) {
      return _emptyState(
        icon: Icons.error_outline_rounded,
        iconColor: const Color(0xFFF59E0B),
        title: 'Association non configurée',
        subtitle: 'Créez d\'abord une association depuis la page Budget.',
      );
    }
    if (_filtered.isEmpty) {
      return _emptyState(
        icon: Icons.people_outline,
        iconColor: const Color(0xFF94A3B8),
        title: 'Aucun membre',
        subtitle: 'Aucun membre ne correspond à votre recherche.',
      );
    }

    // Grille 3 colonnes comme la capture
    return LayoutBuilder(builder: (ctx, constraints) {
      final cols = constraints.maxWidth > 900
          ? 3
          : constraints.maxWidth > 600
              ? 2
              : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
        ),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _memberCard(_filtered[i]),
      );
    });
  }

  Widget _memberCard(Map<String, dynamic> m) {
    final name = _name(m);
    final email = _email(m);
    final isAdm = _isAdmin(m);
    final isMe = _isMe(m);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bg = _avatarBg(m);
    final join = _joinDate(m);
    final blocked = m['blocked'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F0FA)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row ───────────────────────────────────────────────
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(initial,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            // Nom + email
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF0F172A))),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('vous',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.email_outlined,
                          size: 11, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(email,
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  ]),
            ),
            // Role badge
            _roleBadge(isAdm),
          ]),

          const SizedBox(height: 10),

          // ── Status + date ─────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                  color: blocked
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle,
                    size: 7,
                    color: blocked
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A)),
                const SizedBox(width: 4),
                Text(blocked ? 'Bloqué' : 'Actif',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: blocked
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A))),
              ]),
            ),
            const Spacer(),
            Text(join,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ]),

          // ── Bouton Retirer (seulement si pas moi) ─────────────────
          if (!isMe) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 30,
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8)),
              child: TextButton.icon(
                onPressed: () => _removeMember(m),
                icon: const Icon(Icons.delete_outline,
                    size: 13, color: Color(0xFFEF4444)),
                label: const Text('RETIRER',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEF4444))),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roleBadge(bool isAdmin) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isAdmin ? const Color(0xFFF3E8FF) : const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(
              isAdmin
                  ? Icons.admin_panel_settings_outlined
                  : Icons.person_outline,
              size: 11,
              color:
                  isAdmin ? const Color(0xFF9333EA) : const Color(0xFF0B6BFF)),
          const SizedBox(width: 4),
          Text(isAdmin ? 'ADMIN' : 'MEMBRE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isAdmin
                      ? const Color(0xFF9333EA)
                      : const Color(0xFF0B6BFF))),
        ]),
      );

  Widget _filterBtn(String label, int index) {
    final selected = _selectedFilter == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = index);
        _applyFilter();
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B6BFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color:
                  selected ? const Color(0xFF0B6BFF) : const Color(0xFFE2E8F0)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8F0FA)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1)),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 38,
                height: 0.9,
                fontWeight: FontWeight.w800)),
      ]),
    );
  }

  Future<void> _removeMember(Map<String, dynamic> m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Retirer le membre',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text('Voulez-vous retirer ${_name(m)} de l\'association ?',
            style: const TextStyle(color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler',
                style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Retirer',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true || _assocDocId == null) return;

    setState(() => _isLoading = true);
    try {
      // Nouvelle liste sans le membre retiré
      final updatedIds = _members
          .where((x) => x['id'] != m['id'])
          .map((x) => x['id'])
          .toList();

      // 1. PUT /associations/{documentId}
      final putUri = Uri.parse('$_baseUrl/associations/$_assocDocId');
      await http.put(
        putUri,
        headers: _headers,
        body: jsonEncode({
          'data': {'members': updatedIds}
        }),
      );

      // 2. GET /associations/{documentId}?populate=members
      final getUri =
          Uri.parse('$_baseUrl/associations/$_assocDocId?populate=members');
      final getRes = await http.get(getUri, headers: _headers);
      if (getRes.statusCode == 200) {
        final body = jsonDecode(getRes.body);
        final data = body['data'] ?? body;
        final raw = data['members'];
        if (raw is List) {
          setState(() => _members = raw.cast<Map<String, dynamic>>());
        }
      }

      _applyFilter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Membre retiré avec succès'),
          backgroundColor: Color(0xFF22C55E),
        ));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _emptyState({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: iconColor, size: 42),
          const SizedBox(height: 14),
          Text(title,
              style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Text(subtitle,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        ]),
      ),
    );
  }
}

// ─── Dialog Invitation ────────────────────────────────────────────────────────
// ignore: depend_on_referenced_packages
// (http already imported at top of file)
class _InvitationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> allUsers;
  final List<Map<String, dynamic>> currentMembers;
  final String? assocDocId;
  final Map<String, String> headers;

  const _InvitationDialog({
    required this.allUsers,
    required this.currentMembers,
    required this.assocDocId,
    required this.headers,
  });

  @override
  State<_InvitationDialog> createState() => _InvitationDialogState();
}

class _InvitationDialogState extends State<_InvitationDialog> {
  Map<String, dynamic>? _selectedUser;
  bool _isSending = false;

  List<Map<String, dynamic>> get _availableUsers => widget.allUsers;

  String _userName(Map<String, dynamic> u) {
    final username = u['username']?.toString() ?? '';
    final email = u['email']?.toString() ?? '';
    if (username.isNotEmpty && email.isNotEmpty) return '$username ($email)';
    return email.isNotEmpty ? email : username;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Row(children: [
              const Icon(Icons.person_add_outlined,
                  color: Color(0xFF0B6BFF), size: 18),
              const SizedBox(width: 8),
              const Text('Envoyer une invitation',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A))),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child:
                    const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
              ),
            ]),
            const SizedBox(height: 6),
            const Text(
              'Saisissez l\'email de l\'utilisateur à inviter dans l\'association.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // ── Select utilisateur ─────────────────────────────────
            const Text('UTILISATEUR (EMAIL)',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButton<Map<String, dynamic>>(
                value: _selectedUser,
                hint: const Text('Sélectionner un utilisateur',
                    style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF64748B)),
                items: _availableUsers.map((u) {
                  return DropdownMenuItem(
                    value: u,
                    child: Text(_userName(u),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF0F172A))),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedUser = v),
              ),
            ),
            const SizedBox(height: 24),

            // ── Buttons ────────────────────────────────────────────
            Row(children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B)),
                child: const Text('Annuler',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _selectedUser == null || _isSending
                    ? null
                    : _sendInvitation,
                icon: _isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Icon(Icons.send_outlined, size: 14),
                label: const Text('ENVOYER',
                    style:
                        TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInvitation() async {
    if (_selectedUser == null || widget.assocDocId == null) return;
    setState(() => _isSending = true);
    try {
      final email = _selectedUser!['email']?.toString() ?? '';
      final baseUrl = 'http://193.111.250.244:3046/api';

      // 1. GET /users?filters[email][$eq]=email&populate=*
      final userRes = await http.get(
        Uri.parse(
            '$baseUrl/users?filters%5Bemail%5D%5B%24eq%5D=${Uri.encodeComponent(email)}&populate=*'),
        headers: widget.headers,
      );
      if (userRes.statusCode != 200) throw Exception('Utilisateur introuvable');
      final userBody = jsonDecode(userRes.body);
      final List userList =
          userBody is List ? userBody : (userBody['data'] ?? []);
      if (userList.isEmpty) throw Exception('Utilisateur introuvable');
      final userId = userList.first['id'];

      // 2. GET /{assocDocId}?populate=members
      final assocRes = await http.get(
        Uri.parse(
            '$baseUrl/associations/${widget.assocDocId}?populate=members'),
        headers: widget.headers,
      );
      if (assocRes.statusCode != 200)
        throw Exception('Association introuvable');
      final assocBody = jsonDecode(assocRes.body);
      final assocData = assocBody['data'] ?? assocBody;
      final List currentMembers = assocData['members'] ?? [];
      final List<int> memberIds = currentMembers
          .map<int>((m) => (m['id'] is int)
              ? m['id'] as int
              : int.tryParse(m['id'].toString()) ?? 0)
          .toList();

      // 3. GET /{assocDocId} puis PUT pour ajouter le membre
      final getRes = await http.get(
        Uri.parse('$baseUrl/associations/${widget.assocDocId}'),
        headers: widget.headers,
      );
      if (getRes.statusCode != 200) throw Exception('Erreur association');

      // PUT /associations/{documentId} avec les membres mis à jour
      final newMemberIds = [...memberIds, userId];
      final putRes = await http.put(
        Uri.parse('$baseUrl/associations/${widget.assocDocId}'),
        headers: widget.headers,
        body: jsonEncode({
          'data': {
            'members': newMemberIds,
          }
        }),
      );

      if (putRes.statusCode == 200 || putRes.statusCode == 201) {
        if (mounted) Navigator.of(context).pop(_selectedUser);
      } else {
        final errBody = jsonDecode(putRes.body);
        throw Exception(errBody['error']?['message'] ?? '${putRes.statusCode}');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444)));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
