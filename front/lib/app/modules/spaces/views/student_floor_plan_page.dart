import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/student_space_reservation_view.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';

class StudentFloorPlanPage extends StatefulWidget {
  const StudentFloorPlanPage({super.key});

  @override
  State<StudentFloorPlanPage> createState() => _StudentFloorPlanPageState();
}

class _StudentFloorPlanPageState extends State<StudentFloorPlanPage> {
  static const String _baseUrl = 'http://localhost:3001/api';

  final _isLoading = true.obs;
  final _all = <Map<String, dynamic>>[].obs;
  final _filtered = <Map<String, dynamic>>[].obs;
  String _search = '';

  Map<String, String> get _headers {
    try {
      return Get.find<AuthService>().authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ── GET /spaces/{documentId}?populate=* ──────────────────────────────────
  Future<void> _openReservation(Map<String, dynamic> s) async {
    final identifier = (s['documentId']?.toString().trim().isNotEmpty ?? false)
        ? s['documentId'].toString().trim()
        : (s['id']?.toString().trim() ?? '');
    if (identifier.isEmpty) {
      Get.snackbar('Erreur', 'Identifiant espace manquant',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Affiche un loader pendant le fetch
    Get.dialog(
      const Center(child: CircularProgressIndicator(color: Color(0xFF0B6BFF))),
      barrierDismissible: false,
    );

    try {
      final uri = Uri.parse('$_baseUrl/spaces/$identifier?populate=*');
      final response = await http.get(uri, headers: _headers);

      Get.back(); // ferme le loader

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        final space = _mapToSpace(data is Map<String, dynamic> ? data : s);
        Get.to(() => StudentSpaceReservationView(space: space));
      } else {
        throw Exception('${response.statusCode}');
      }
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('Erreur', 'Impossible de charger l\'espace: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Space _mapToSpace(Map<String, dynamic> s) {
    return Space(
      id: (s['id'] ?? 0) is int
          ? (s['id'] ?? 0)
          : int.tryParse(s['id'].toString()) ?? 0,
      documentId: s['documentId']?.toString() ?? '',
      name: s['name']?.toString() ?? 'Espace',
      slug: s['slug']?.toString() ?? '',
      type: s['type']?.toString(),
      location: s['location']?.toString(),
      floor: s['floor']?.toString(),
      capacity: (s['capacity'] ?? 1) is int
          ? (s['capacity'] ?? 1)
          : int.tryParse(s['capacity'].toString()) ?? 1,
      area: (s['area_sqm'] ?? s['surface'] ?? 0).toDouble(),
      svgWidth: (s['svg_width'] ?? s['width'] ?? 2780) is int
          ? (s['svg_width'] ?? s['width'] ?? 2780)
          : int.tryParse((s['svg_width'] ?? s['width']).toString()) ?? 2780,
      svgHeight: (s['svg_height'] ?? s['height'] ?? 1974) is int
          ? (s['svg_height'] ?? s['height'] ?? 1974)
          : int.tryParse((s['svg_height'] ?? s['height']).toString()) ?? 1974,
      status:
          (s['availability_status'] ?? s['status'] ?? 'Disponible').toString(),
      isCoworking: s['is_coworking'] == true || s['isCoworkingSpace'] == true,
      allowGuestReservations: s['allow_guest_reservations'] == true ||
          s['allowLimitedReservations'] == true,
      hourlyRate: _resolveHourlyRate(s),
      dailyRate: _toDoubleValue(s['daily_rate'] ?? s['dailyRate']),
      monthlyRate: _resolveMonthlyRate(s),
      overtimeRate: _toDoubleValue(s['overtimeRate']),
      currency: s['currency']?.toString() ?? 'TND',
      description: _extractDescription(s['description']),
      available24h: s['available24h'] == true,
      isCoworkingSpace:
          s['isCoworkingSpace'] == true || s['is_coworking'] == true,
      allowLimitedReservations: s['allowLimitedReservations'] == true ||
          s['allow_guest_reservations'] == true,
      surface: _toDoubleValue(s['surface']),
      width: _toDoubleValue(s['width']),
      height: _toDoubleValue(s['height']),
      features: s['features']?.toString(),
      imageUrl: s['imageUrl']?.toString(),
      createdAt: DateTime.tryParse(s['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(s['updatedAt']?.toString() ?? ''),
    );
  }

  double _toDoubleValue(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  double _resolveHourlyRate(Map<String, dynamic> s) {
    final pricing = s['pricing'];
    final rates = s['rates'];

    return _toDoubleValue(
      s['hourlyRate'] ??
          s['hourly_rate'] ??
          s['pricePerHour'] ??
          s['price_per_hour'] ??
          s['pricingHourly'] ??
          s['pricing_hourly'] ??
          (pricing is Map
              ? pricing['hourlyRate'] ?? pricing['hourly_rate']
              : null) ??
          (rates is Map ? rates['hourlyRate'] ?? rates['hourly_rate'] : null),
    );
  }

  double _resolveMonthlyRate(Map<String, dynamic> s) {
    final pricing = s['pricing'];
    final rates = s['rates'];

    return _toDoubleValue(
      s['monthlyRate'] ??
          s['monthly_rate'] ??
          s['pricePerMonth'] ??
          s['price_per_month'] ??
          s['pricingMonthly'] ??
          s['pricing_monthly'] ??
          (pricing is Map
              ? pricing['monthlyRate'] ?? pricing['monthly_rate']
              : null) ??
          (rates is Map ? rates['monthlyRate'] ?? rates['monthly_rate'] : null),
    );
  }

  String _extractDescription(dynamic raw) {
    if (raw is String) return raw;
    if (raw is List) {
      return raw
          .map((b) {
            if (b is Map) {
              final children = b['children'];
              if (children is List) {
                return children
                    .map((c) => c is Map ? (c['text'] ?? '') : '')
                    .join('');
              }
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
    }
    return '';
  }

  Future<void> _load() async {
    _isLoading.value = true;
    try {
      final uri = Uri.parse(
        '$_baseUrl/spaces'
        '?pagination%5Bpage%5D=1'
        '&pagination%5BpageSize%5D=25'
        '&sort=createdAt%3Adesc'
        '&populate=*',
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
      Get.snackbar('Erreur', 'Impossible de charger les espaces: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      _isLoading.value = false;
    }
  }

  void _applyFilter() {
    final q = _search.toLowerCase();
    _filtered.assignAll(q.isEmpty
        ? _all
        : _all.where((s) {
            final name = (s['name'] ?? '').toString().toLowerCase();
            final type = (s['type'] ?? '').toString().toLowerCase();
            final floor = (s['floor'] ?? '').toString().toLowerCase();
            final loc = (s['location'] ?? '').toString().toLowerCase();
            return name.contains(q) ||
                type.contains(q) ||
                floor.contains(q) ||
                loc.contains(q);
          }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 980;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FC),
      body: Row(children: [
        if (!compact) const CustomSidebar(),
        Expanded(
          child: Column(children: [
            const DashboardTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 28, 32, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(),
                    const SizedBox(height: 28),
                    _buildSearch(),
                    const SizedBox(height: 24),
                    _buildGrid(),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAF8)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBFD9FF))),
          child: const Text('COWORKING & STUDY',
              style: TextStyle(
                  color: Color(0xFF0B6BFF),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8)),
        ),
        const SizedBox(height: 14),
        RichText(
          text: const TextSpan(
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.2),
            children: [
              TextSpan(text: 'Trouvez '),
              TextSpan(
                  text: 'l\'espace idéal',
                  style: TextStyle(color: Color(0xFF0B6BFF))),
              TextSpan(text: ' pour vos\nétudes'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Réservez des bureaux premium, des salles de réunion ou des postes de travail\néquipés. Profitez de nos abonnements mensuels avantageux.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.5),
        ),
      ]),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EAF8)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: TextField(
        onChanged: (v) {
          _search = v;
          _applyFilter();
        },
        decoration: InputDecoration(
          hintText: 'Rechercher un espace (nom, type, étage...)',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────
  Widget _buildGrid() {
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
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Center(
              child: Text('Aucun espace trouvé.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 15))),
        );
      }

      return LayoutBuilder(builder: (ctx, constraints) {
        final cols = constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 650
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 0.78,
          ),
          itemCount: _filtered.length,
          itemBuilder: (ctx, i) => _buildCard(_filtered[i]),
        );
      });
    });
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> s) {
    final name = s['name']?.toString() ?? 'Espace';
    final type = s['type']?.toString() ?? 'Abonnement';
    final location = s['location']?.toString() ?? '';
    final floor = s['floor']?.toString() ?? '';
    final capacity = s['capacity']?.toString() ?? '-';
    final monthly = _resolveMonthlyRate(s);
    final hourly = _resolveHourlyRate(s);
    final currency = _currencyCode(s['currency']?.toString() ?? 'TND');

    // Label de localisation pour le header de la carte
    final locLabel =
        floor.isNotEmpty ? floor : (location.isNotEmpty ? location : 'Accueil');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F0FA)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header gris avec badges ──────────────────────────────
          Container(
            height: 136,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FB),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(children: [
              // Badges haut gauche
              Positioned(
                top: 12,
                left: 12,
                child: Row(children: [
                  _badge(locLabel, const Color(0xFFE2E8F0),
                      const Color(0xFF475569)),
                  const SizedBox(width: 6),
                  _badge(type.isNotEmpty ? type : 'Abonnement',
                      const Color(0xFF0B6BFF), Colors.white),
                ]),
              ),
              // Icône centrale
              Center(
                child: Icon(Icons.apartment_outlined,
                    size: 52, color: const Color(0xFF94A3B8).withOpacity(0.5)),
              ),
            ]),
          ),

          // ── Body ─────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF0B6BFF)),
                      const SizedBox(width: 3),
                      Text(location,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ]),
                  ],
                  const SizedBox(height: 12),

                  // Stats : capacité + abonnement mensuel
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.people_outline,
                                  size: 12, color: Color(0xFF94A3B8)),
                              SizedBox(width: 4),
                              Text('CAPACITÉ',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ]),
                            const SizedBox(height: 4),
                            Text('$capacity pers.',
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBFD9FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: const [
                              Icon(Icons.euro_outlined,
                                  size: 12, color: Color(0xFF0B6BFF)),
                              SizedBox(width: 4),
                              Text('PAR MOIS',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: Color(0xFF0B6BFF),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              _formatMoney(monthly, currency),
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0B6BFF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  const Spacer(),

                  // ── Footer : prix/heure + bouton Réserver ────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prix / heure
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: _formatMoney(hourly, currency),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A)),
                            ),
                            const TextSpan(
                              text: ' / heure',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                      // Bouton Réserver
                      ElevatedButton.icon(
                        onPressed: () => _openReservation(s),
                        icon: const Icon(Icons.arrow_forward, size: 14),
                        label: const Text('Réserver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
    );
  }

  String _currencyCode(String currency) {
    final normalized = currency.trim().toUpperCase();
    if (normalized == 'TND') return 'DT';
    return normalized.isEmpty ? 'DT' : normalized;
  }

  String _formatMoney(double value, String currency) {
    if (value <= 0) return '-- $currency';
    return '${value.toStringAsFixed(0)} $currency';
  }
}
