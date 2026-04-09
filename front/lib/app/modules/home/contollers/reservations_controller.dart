import 'package:flutter_getx_app/app/data/services/reservations_service.dart';
import 'package:get/get.dart';

class ReservationsController extends GetxController {
  final ReservationsService _service = ReservationsService();

  final allReservations = <ReservationModel>[].obs;
  final reservations = <ReservationModel>[].obs;
  final isLoading = false.obs;
  final selectedStatus = 'Tous'.obs;
  final searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadReservations();
  }

  Future<void> loadReservations() async {
    try {
      isLoading.value = true;
      update();
      final result = await _service.getReservations();
      final List<dynamic> data = result['data'] ?? [];
      allReservations.assignAll(
          data.map((json) => ReservationModel.fromJson(json)).toList());
      _applyFilters();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les réservations: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
      update();
    }
  }

  Future<void> updateStatus(String documentId, String newStatus) async {
    try {
      await _service.updateReservationStatus(documentId, newStatus);
      await loadReservations();
      Get.snackbar('Succès', 'Statut mis à jour',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de modifier le statut: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteReservation(String documentId) async {
    try {
      await _service.deleteReservation(documentId);
      await loadReservations();
      Get.snackbar('Succès', 'Réservation supprimée',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de supprimer: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void changeStatusFilter(String status) {
    selectedStatus.value = status;
    _applyFilters();
    update();
  }

  void setSearchQuery(String value) {
    searchQuery.value = value;
    _applyFilters();
    update();
  }

  int get totalCount => allReservations.length;
  int get confirmedCount => allReservations
      .where((r) => _normalizeStatus(r.status) == 'confirmé')
      .length;
  int get pendingCount => allReservations
      .where((r) => _normalizeStatus(r.status) == 'en attente')
      .length;

  List<ReservationModel> get upcomingReservations {
    final now = DateTime.now();
    return (reservations.where((r) => r.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime)));
  }

  void _applyFilters() {
    final selected = _normalizeStatus(selectedStatus.value);
    final query = searchQuery.value.trim().toLowerCase();

    reservations.assignAll(allReservations.where((r) {
      final statusMatch = selectedStatus.value == 'Tous' ||
          _normalizeStatus(r.status) == selected;
      final searchMatch = query.isEmpty ||
          r.spaceName.toLowerCase().contains(query) ||
          r.userName.toLowerCase().contains(query);
      return statusMatch && searchMatch;
    }).toList());
    update();
  }

  String _normalizeStatus(String value) {
    final lower = value.toLowerCase().trim().replaceAll('_', ' ');
    if (lower == 'en attente' || lower == 'en_attente') return 'en attente';
    if (lower.contains('confirm')) return 'confirmé';
    if (lower.contains('annul')) return 'annulé';
    return lower;
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
class ReservationModel {
  final int id;
  final String documentId; // ← Strapi v5 documentId pour DELETE/PUT
  final String spaceName;
  final String userName;
  final String userEmail;
  final String userPhone;
  final String userRole;
  final String? userType;
  final DateTime dateTime;
  final double amount;
  final String status;
  final String paymentMethod;

  ReservationModel({
    required this.id,
    required this.documentId,
    required this.spaceName,
    required this.userName,
    required this.userEmail,
    this.userPhone = '',
    this.userRole = '',
    this.userType,
    required this.dateTime,
    required this.amount,
    required this.status,
    this.paymentMethod = '',
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final attrs = _extractAttributes(json);
    final space = _extractRelationMap(attrs['space']);
    final user = _extractRelationMap(attrs['user']);

    // ── Rôle utilisateur ──────────────────────────────────────────────────
    // Strapi v5 : role peut être dans user.role ou user.userType
    final roleRaw = _extractRelationMap(user?['role']);
    final roleName = _firstNonEmptyString([
      roleRaw?['name'],
      user?['role']?.toString(),
      attrs['user_type'],
      attrs['userType'],
    ]);
    // Classifie : si pas d'user Strapi → Visiteur
    final isGuest = user == null || (user['id'] == null);
    final role =
        roleName.isNotEmpty ? roleName : (isGuest ? 'Visiteur' : 'Client');

    return ReservationModel(
      id: _toInt(json['id']),
      documentId:
          json['documentId']?.toString() ?? json['id']?.toString() ?? '',
      spaceName: _firstNonEmptyString([
        space?['name'],
        attrs['space_name'],
      ], fallback: 'N/A'),
      userName: _firstNonEmptyString([
        user?['username'],
        user?['fullName'],
        user?['firstName'],
        attrs['organizer_name'],
        attrs['guest_name'],
      ], fallback: 'Guest'),
      userEmail: _firstNonEmptyString([
        user?['email'],
        attrs['guest_email'],
      ]),
      userPhone: _firstNonEmptyString([
        user?['phone'],
        user?['phoneNumber'],
        user?['phone_number'],
        attrs['organizer_phone'],
      ]),
      userRole: role,
      userType: _firstNonEmptyString([
        attrs['userType'],
        attrs['user_type'],
      ]),
      dateTime: _parseDate([
            attrs['start_datetime'],
            attrs['startDate'],
            attrs['createdAt'],
          ]) ??
          DateTime.now(),
      amount: _toDouble(
          attrs['total_amount'] ?? attrs['amount'] ?? attrs['totalAmount']),
      status: _firstNonEmptyString([
        attrs['mystatus'],
        attrs['status'],
      ], fallback: 'en_attente'),
      paymentMethod: _firstNonEmptyString([
        attrs['payment_method'],
        attrs['paymentMethod'],
      ]),
    );
  }

  static Map<String, dynamic> _extractAttributes(Map<String, dynamic> source) {
    final attrs = source['attributes'];
    if (attrs is Map) return Map<String, dynamic>.from(attrs);
    return Map<String, dynamic>.from(source);
  }

  static Map<String, dynamic>? _extractRelationMap(dynamic value) {
    if (value is Map) {
      final data = value['data'];
      if (data is Map) {
        final nested = data['attributes'];
        if (nested is Map) {
          return {...Map<String, dynamic>.from(nested), 'id': data['id']};
        }
        return Map<String, dynamic>.from(data);
      }
      final attrs = value['attributes'];
      if (attrs is Map) return Map<String, dynamic>.from(attrs);
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  static String _firstNonEmptyString(List<dynamic> values,
      {String fallback = ''}) {
    for (final v in values) {
      if (v == null) continue;
      final t = v.toString().trim();
      if (t.isNotEmpty) return t;
    }
    return fallback;
  }

  static DateTime? _parseDate(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c == null) continue;
      final p = DateTime.tryParse(c.toString());
      if (p != null) return p;
    }
    return null;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
