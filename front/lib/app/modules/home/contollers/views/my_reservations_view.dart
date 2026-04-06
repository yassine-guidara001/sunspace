import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'custom_sidebar.dart';
import 'dashboard_topbar.dart';

class MyReservationsView extends StatefulWidget {
  const MyReservationsView({super.key});

  @override
  State<MyReservationsView> createState() => _MyReservationsViewState();
}

class _MyReservationsViewState extends State<MyReservationsView> {
  static const String _baseUrl = 'http://localhost:3001/api';

  final _isLoading = true.obs;
  final _all = <Map<String, dynamic>>[].obs;
  final _filtered = <Map<String, dynamic>>[].obs;
  String _search = '';

  Map<String, dynamic>? get _userData {
    try {
      return Get.find<StorageService>().getUserData();
    } catch (_) {
      return null;
    }
  }

  String get _userName {
    final u = _userData;
    if (u == null) return 'intern';
    final fn = u['firstName'] ?? u['first_name'] ?? '';
    final ln = u['lastName'] ?? u['last_name'] ?? '';
    final un = u['username'] ?? '';
    final full = '$fn $ln'.trim();
    return full.isNotEmpty ? full : (un.isNotEmpty ? un : 'intern');
  }

  String get _userDocumentId {
    final u = _userData;
    return u?['documentId']?.toString() ?? u?['id']?.toString() ?? '';
  }

  Map<String, String> get _headers {
    try {
      return Get.find<AuthService>().authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  int get _total => _all.length;
  int get _confirmed =>
      _all.where((r) => _statusOf(r).toLowerCase().contains('confirm')).length;
  int get _pending =>
      _all.where((r) => _statusOf(r).toLowerCase().contains('attente')).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── Requête unique comme la capture ───────────────────────────────────────
  Future<void> _load() async {
    _isLoading.value = true;
    try {
      final docId = _userDocumentId;
      final uri = Uri.parse(
        '$_baseUrl/reservations'
        '?populate%5Bspace%5D%5Bpopulate%5D=*'
        '&populate%5Buser%5D%5Bfields%5D=username,email'
        '&filters%5Buser%5D%5BdocumentId%5D%5B%24eq%5D=$docId',
      );
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body['data'] ?? [];
        _all.assignAll(data.cast<Map<String, dynamic>>());
        _applyFilter();
      } else {
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger vos réservations: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isLoading.value = false;
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered.assignAll(q.isEmpty
        ? _all
        : _all
            .where((r) => _spaceNameOf(r).toLowerCase().contains(q))
            .toList());
  }

  String _spaceNameOf(Map<String, dynamic> r) {
    final s = r['space'];
    if (s is Map) return s['name']?.toString() ?? '';
    return '';
  }

  String _statusOf(Map<String, dynamic> r) =>
      r['mystatus']?.toString() ?? r['status']?.toString() ?? 'En_attente';

  String _startDateOf(Map<String, dynamic> r) {
    final raw = r['start_datetime'] ?? '';
    final dt = DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    return DateFormat('d MMMM yyyy', 'fr').format(dt.toLocal());
  }

  String _timeRangeOf(Map<String, dynamic> r) {
    final start = r['start_datetime'] ?? '';
    final end = r['end_datetime'] ?? '';
    final ds = DateTime.tryParse(start.toString());
    final de = DateTime.tryParse(end.toString());
    if (ds == null) return '';
    final fmt = DateFormat('HH:mm');
    if (de == null) return fmt.format(ds.toLocal());
    return '${fmt.format(ds.toLocal())} - ${fmt.format(de.toLocal())}';
  }

  double _amountOf(Map<String, dynamic> r) =>
      (r['total_amount'] ?? 0).toDouble();

  // ── Annuler réservation ───────────────────────────────────────────────────
  Future<void> _cancel(String documentId) async {
    try {
      final uri = Uri.parse('$_baseUrl/reservations/$documentId');
      await http.put(uri,
          headers: _headers,
          body: jsonEncode({
            'data': {'mystatus': 'Annulée'}
          }));
      _load();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'annuler: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: LayoutBuilder(builder: (ctx, constraints) {
        return Row(children: [
          if (constraints.maxWidth >= 1080) const CustomSidebar(),
          Expanded(
            child: Column(children: [
              const DashboardTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHero(context),
                          const SizedBox(height: 28),
                          _buildSectionHeader(),
                          const SizedBox(height: 16),
                          _buildList(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      }),
    );
  }

  Widget _buildHero(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final compact = w < 1200;

    return Obx(() => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5FF),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD2E3FF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: const Color(0xFFDCEAFE),
                          borderRadius: BorderRadius.circular(999)),
                      child:
                          const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, size: 7, color: Color(0xFF0B6BFF)),
                        SizedBox(width: 5),
                        Text('ESPACE PERSONNEL',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFF0B6BFF))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                            fontSize: w < 720 ? 28 : 38,
                            fontWeight: FontWeight.w800,
                            height: 1.1),
                        children: [
                          const TextSpan(
                              text: 'Bienvenue, ',
                              style: TextStyle(color: Color(0xFF0F172A))),
                          TextSpan(
                              text: _userName,
                              style: const TextStyle(color: Color(0xFF0B6BFF))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Retrouvez ici toutes vos réservations et gérez votre planning en toute simplicité.',
                      style: TextStyle(
                          color: Color(0xFF64748B), fontSize: 14, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      OutlinedButton.icon(
                        onPressed: _load,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Actualiser'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFC8D9F3)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => Get.toNamed(Routes.PLAN),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Nouvelle Réservation →'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),
                    // Stats
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      _statCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'TOTAL',
                          value: _total),
                      _statCard(
                          icon: Icons.check_circle_outline,
                          label: 'CONFIRMÉES',
                          value: _confirmed,
                          cardColor: const Color(0xFFE6F7EF),
                          iconColor: const Color(0xFF10B981),
                          valueColor: const Color(0xFF059669)),
                      _statCard(
                          icon: Icons.timelapse_outlined,
                          label: 'EN ATTENTE',
                          value: _pending,
                          cardColor: const Color(0xFFFFF4E8),
                          iconColor: const Color(0xFFF59E0B),
                          valueColor: const Color(0xFFEA580C)),
                    ]),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 24),
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                      color: const Color(0xFFDCEAFE),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.calendar_month_rounded,
                      size: 80, color: Color(0xFF9ABDEB)),
                ),
              ],
            ],
          ),
        ));
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
    Color cardColor = Colors.white,
    Color iconColor = const Color(0xFF64748B),
    Color valueColor = const Color(0xFF0F172A),
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7E3F7)),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value',
              style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 22)),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.8)),
        ]),
      ]),
    );
  }

  Widget _buildSectionHeader() {
    return Row(children: [
      const Row(children: [
        SizedBox(
            width: 4,
            height: 28,
            child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Color(0xFF0B6BFF),
                    borderRadius: BorderRadius.all(Radius.circular(4))))),
        SizedBox(width: 10),
        Text('MES RÉSERVATIONS',
            style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 22,
                fontWeight: FontWeight.w800)),
      ]),
      const SizedBox(width: 24),
      Expanded(
        child: TextField(
          onChanged: (v) {
            _search = v;
            _applyFilter();
          },
          decoration: InputDecoration(
            hintText: 'Rechercher un espace...',
            prefixIcon:
                const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDEE8F7))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFDEE8F7))),
          ),
        ),
      ),
    ]);
  }

  Widget _buildList() {
    return Obx(() {
      if (_isLoading.value) {
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF0B6BFF))));
      }
      if (_filtered.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5FC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6F6))),
          child: const Text(
            'Aucune réservation trouvée.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 15,
                fontStyle: FontStyle.italic),
          ),
        );
      }
      return Column(children: _filtered.map((r) => _buildCard(r)).toList());
    });
  }

  Widget _buildCard(Map<String, dynamic> r) {
    final status = _statusOf(r);
    final isConf = status.toLowerCase().contains('confirm');
    final isPend = status.toLowerCase().contains('attente');
    final isCancel = status.toLowerCase().contains('annul');
    final statusColor = isConf
        ? const Color(0xFF059669)
        : isPend
            ? const Color(0xFFEA580C)
            : const Color(0xFFDC2626);
    final statusBg = isConf
        ? const Color(0xFFDCFCE7)
        : isPend
            ? const Color(0xFFFEF3C7)
            : const Color(0xFFFEE2E2);
    final statusLabel = isConf
        ? 'CONFIRMÉE'
        : isPend
            ? 'EN ATTENTE'
            : 'ANNULÉE';

    final space = r['space'] as Map<String, dynamic>?;
    final name = space?['name']?.toString() ?? 'Espace';
    final loc = space?['location']?.toString() ?? '';
    final floor = space?['floor']?.toString() ?? '';
    final amount = _amountOf(r);
    final date = _startDateOf(r);
    final timeRange = _timeRangeOf(r);
    final docId = r['documentId']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0F8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colonne gauche ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statut + localisation
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(statusLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ),
                    if (loc.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF64748B)),
                      const SizedBox(width: 3),
                      Text(loc,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  // Nom espace
                  Text(name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A))),
                  const SizedBox(height: 4),
                  // Sous-titre
                  Text(
                    [
                      if (loc.isNotEmpty) 'Espace de Travail',
                      if (floor.isNotEmpty) 'Étage $floor',
                    ].join(' • '),
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  ),
                  const SizedBox(height: 14),
                  // Date + Horaires
                  Row(children: [
                    if (date.isNotEmpty) ...[
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: Color(0xFF0B6BFF)),
                      const SizedBox(width: 5),
                      Text(date,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                    ],
                    if (timeRange.isNotEmpty) ...[
                      const SizedBox(width: 18),
                      const Icon(Icons.access_time_outlined,
                          size: 13, color: Color(0xFF0B6BFF)),
                      const SizedBox(width: 5),
                      Text(timeRange,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                    ],
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // ── Colonne droite ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('MONTANT TOTAL',
                    style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                          text: amount.toStringAsFixed(0),
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A))),
                      const TextSpan(
                          text: ' DT',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Bouton Annuler (si pas déjà annulé/confirmé)
                if (!isConf && !isCancel && docId.isNotEmpty)
                  GestureDetector(
                    onTap: () => _cancel(docId),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('ANNULER',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
