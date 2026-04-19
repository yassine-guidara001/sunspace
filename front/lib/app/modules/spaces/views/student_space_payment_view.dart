import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class StudentSpacePaymentView extends StatefulWidget {
  const StudentSpacePaymentView({
    super.key,
    required this.space,
    required this.plan,
    required this.startDate,
    required this.startTime,
    required this.endDate,
    required this.endTime,
  });

  final Space space;
  final String plan;
  final DateTime startDate;
  final TimeOfDay startTime;
  final DateTime endDate;
  final TimeOfDay endTime;

  @override
  State<StudentSpacePaymentView> createState() =>
      _StudentSpacePaymentViewState();
}

class _StudentSpacePaymentViewState extends State<StudentSpacePaymentView> {
  static const String _baseUrl = 'http://localhost:3001/api';
  static const int _openingHour = 9;
  static const int _closingHour = 18;

  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _sendEmailReceipt = true;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    _cvcController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Map<String, String> get _headers {
    try {
      return Get.find<AuthService>().authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  String get _organizerName {
    try {
      final u = Get.find<StorageService>().getUserData();
      if (u != null) {
        final fn = u['firstName'] ?? u['first_name'] ?? '';
        final ln = u['lastName'] ?? u['last_name'] ?? '';
        final un = u['username'] ?? '';
        final full = '$fn $ln'.trim();
        return full.isNotEmpty ? full : (un.isNotEmpty ? un : 'Utilisateur');
      }
    } catch (_) {}
    return 'Utilisateur';
  }

  String get _organizerPhone {
    try {
      final u = Get.find<StorageService>().getUserData();
      return u?['phone'] ?? u?['phoneNumber'] ?? '00000000';
    } catch (_) {
      return '00000000';
    }
  }

  // ── POST /api/reservations ────────────────────────────────────────────────
  Future<void> _pay() async {
    setState(() => _isLoading = true);
    try {
      final startDateTime = DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
        widget.startTime.hour,
        widget.startTime.minute,
      );

      DateTime endDateTime = DateTime(
        widget.endDate.year,
        widget.endDate.month,
        widget.endDate.day,
        widget.endTime.hour,
        widget.endTime.minute,
      );

      if (!endDateTime.isAfter(startDateTime)) {
        endDateTime = widget.plan == 'monthly'
            ? startDateTime.add(const Duration(days: 30))
            : startDateTime.add(const Duration(hours: 1));
      }

      if (!_isWithinOpeningHours(startDateTime) ||
          !_isWithinOpeningHours(endDateTime)) {
        throw Exception('Cet espace est ouvert uniquement de 09:00 à 18:00');
      }

      final alreadyExists =
          await _hasExistingOverlappingReservation(startDateTime, endDateTime);
      if (alreadyExists) {
        _showReservationAlreadySaved();
        return;
      }

      final localStartDt = _toLocalApiDateTime(startDateTime);
      final endDt = _toLocalApiDateTime(endDateTime);

      final payload = {
        'data': {
          'space': widget.space.id.toString(),
          'start_datetime': localStartDt,
          'end_datetime': endDt,
          'is_all_day': widget.plan == 'monthly',
          'attendees': 1,
          'mystatus': 'En_attente',
          'organizer_name': _organizerName,
          'organizer_phone': _organizerPhone,
          'total_amount': _price,
          'payment_method': 'Carte',
          'payment_status': 'En_attente',
        }
      };

      final uri = Uri.parse('$_baseUrl/reservations');
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Get.snackbar(
          'Paiement confirmé',
          'Votre réservation pour ${widget.space.name} est enregistrée !',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF22C55E),
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
        // Retour à l'accueil après succès
        Get.until((route) => route.isFirst);
      } else {
        final message = _extractApiErrorMessage(response);

        if (response.statusCode == 400 &&
            message.toLowerCase().contains('indisponible sur ce créneau')) {
          final existsAfterCheck = await _hasExistingOverlappingReservation(
              startDateTime, endDateTime);
          if (existsAfterCheck) {
            _showReservationAlreadySaved();
            return;
          }
        }

        throw Exception(message);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur paiement',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _hasExistingOverlappingReservation(
    DateTime targetStart,
    DateTime targetEnd,
  ) async {
    try {
      final dateFilter =
          '${targetStart.year.toString().padLeft(4, '0')}-${targetStart.month.toString().padLeft(2, '0')}-${targetStart.day.toString().padLeft(2, '0')}';

      final uri = Uri.parse('$_baseUrl/reservations').replace(
        queryParameters: {
          'filters[space][id][\$eq]': widget.space.id.toString(),
          'filters[start_datetime][\$contains]': dateFilter,
        },
      );

      final response = await http.get(uri, headers: _headers);
      if (response.statusCode != 200) return false;

      final decoded = jsonDecode(response.body);
      final list = decoded is Map<String, dynamic>
          ? (decoded['data'] as List<dynamic>? ?? const <dynamic>[])
          : const <dynamic>[];

      for (final item in list) {
        if (item is! Map<String, dynamic>) continue;

        final status = (item['status'] ?? '').toString().toUpperCase();
        if (status != 'PENDING' && status != 'CONFIRMED') {
          continue;
        }

        final space = item['space'];
        final reservationSpaceId =
            space is Map<String, dynamic> ? space['id'] : null;
        if (reservationSpaceId == null ||
            reservationSpaceId.toString() != widget.space.id.toString()) {
          continue;
        }

        final start =
            DateTime.tryParse((item['start_datetime'] ?? '').toString());
        final end = DateTime.tryParse((item['end_datetime'] ?? '').toString());
        if (start == null || end == null) continue;

        final overlaps = start.isBefore(targetEnd) && end.isAfter(targetStart);
        if (overlaps) return true;
      }
    } catch (_) {
      return false;
    }

    return false;
  }

  String _extractApiErrorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message != null && message.toString().trim().isNotEmpty) {
            return message.toString();
          }
        }
        final message = decoded['message'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Ignore parsing errors and fallback below.
    }
    return 'Erreur serveur (${response.statusCode})';
  }

  void _showReservationAlreadySaved() {
    Get.snackbar(
      'Réservation déjà enregistrée',
      'Ce créneau est déjà réservé. Redirection vers l\'accueil.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF0EA5E9),
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
    Get.until((route) => route.isFirst);
  }

  bool _isWithinOpeningHours(DateTime value) {
    final minutes = value.hour * 60 + value.minute;
    return minutes >= _openingHour * 60 && minutes <= _closingHour * 60;
  }

  DateTime get _startDateTime => DateTime(
        widget.startDate.year,
        widget.startDate.month,
        widget.startDate.day,
        widget.startTime.hour,
        widget.startTime.minute,
      );

  DateTime get _endDateTimeRaw => DateTime(
        widget.endDate.year,
        widget.endDate.month,
        widget.endDate.day,
        widget.endTime.hour,
        widget.endTime.minute,
      );

  DateTime get _effectiveEndDateTime {
    final start = _startDateTime;
    final rawEnd = _endDateTimeRaw;
    if (rawEnd.isAfter(start)) return rawEnd;
    return widget.plan == 'monthly'
        ? start.add(const Duration(days: 30))
        : start.add(const Duration(hours: 1));
  }

  Duration get _reservationDuration =>
      _effectiveEndDateTime.difference(_startDateTime);

  int get _hourlyUnits {
    final minutes = _reservationDuration.inMinutes;
    if (minutes <= 0) return 1;
    return math.max(1, (minutes / 60).ceil());
  }

  String get _durationLabel {
    if (widget.plan == 'monthly') {
      return '30 Jours';
    }
    return _hourlyUnits == 1 ? '1 Heure' : '$_hourlyUnits Heures';
  }

  String _toLocalApiDateTime(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    final hh = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-${dd}T$hh:$min:00.000';
  }

  double get _price => widget.plan == 'monthly'
      ? widget.space.monthlyRate
      : widget.space.hourlyRate * _hourlyUnits;

  String get _priceLabel {
    final code = widget.space.currency.trim().toUpperCase() == 'TND'
        ? 'DT'
        : widget.space.currency;
    if (_price <= 0) return '-- $code';
    return '${_price.toStringAsFixed(0)} $code';
  }

  String get _gatewayPriceLabel => '${_price.toStringAsFixed(3)} TND';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: Row(children: [
        const CustomSidebar(),
        Expanded(
          child: Column(children: [
            const DashboardTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 30),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 940),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPageTitle(),
                        const SizedBox(height: 20),
                        _buildSteps(),
                        const SizedBox(height: 20),
                        LayoutBuilder(builder: (context, constraints) {
                          final compact = constraints.maxWidth < 860;
                          if (compact) {
                            return Column(children: [
                              _buildPaymentCard(),
                              const SizedBox(height: 16),
                              _buildBillingSummary(),
                            ]);
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 63, child: _buildPaymentCard()),
                              const SizedBox(width: 18),
                              Expanded(flex: 37, child: _buildBillingSummary()),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPageTitle() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        InkWell(
          onTap: Get.back,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back, size: 18, color: Color(0xFF334155)),
          ),
        ),
        const SizedBox(width: 8),
        const Text('Finaliser votre reservation',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A))),
      ]),
      const SizedBox(height: 6),
      Text('Espace : ${widget.space.name}',
          style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w500)),
    ]);
  }

  Widget _buildSteps() {
    return Center(
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _stepDone(),
        _stepLine(active: true),
        _stepCircle(2, true),
        _stepLine(active: false),
        _stepCircle(3, false),
      ]),
    );
  }

  Widget _stepDone() => Container(
        width: 31,
        height: 31,
        decoration: const BoxDecoration(
            color: Color(0xFF1664FF), shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
      );

  Widget _stepCircle(int i, bool active) => Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
            color: active ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle),
        child: Center(
          child: Text('$i',
              style: TextStyle(
                  color: active ? Colors.white : const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      );

  Widget _stepLine({required bool active}) => Container(
        width: 56,
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: active ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
      );

  Widget _buildPaymentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x120F172A), blurRadius: 16, offset: Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGatewayLogoHeader(),
              const SizedBox(height: 14),
              const Text(
                'Paiement sécurisé',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Réservation de l\'espace : ${widget.space.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _textInput(
                controller: _cardNumberController,
                hint: 'Numéro de la carte',
                prefix: const Icon(Icons.credit_card,
                    size: 16, color: Color(0xFF9CA3AF)),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _textInput(
                      controller: _monthController,
                      hint: 'Mois',
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.left,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textInput(
                      controller: _yearController,
                      hint: 'Année',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textInput(
                      controller: _cvcController,
                      hint: 'Code de sûreté',
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      obscuringCharacter: '.',
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _textInput(
                controller: _cardHolderController,
                hint: 'Le nom du détenteur',
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () =>
                    setState(() => _sendEmailReceipt = !_sendEmailReceipt),
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _sendEmailReceipt,
                        onChanged: (value) =>
                            setState(() => _sendEmailReceipt = value ?? false),
                        activeColor: const Color(0xFF0B5FB3),
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(
                            color: Color(0xFF9CA3AF), width: 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Adresse e-mail',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _textInput(
                controller: _emailController,
                hint: '',
                keyboardType: TextInputType.emailAddress,
                enabled: _sendEmailReceipt,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _pay,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B5FB3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          'Paiement $_gatewayPriceLabel',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              _buildGatewayFooterBrands(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: Get.back,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF111827),
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  child: const Text(
                    "Modifier l'offre",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBillingSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('DÉTAILS FACTURATION',
            style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        _detailRow(
            'Offre :',
            widget.plan == 'monthly'
                ? 'Abonnement Mensuel'
                : 'Réservation Ponctuelle'),
        const SizedBox(height: 10),
        _detailRow('Durée :', _durationLabel),
        const SizedBox(height: 10),
        _detailRow(
          'Début :',
          '${_formatDate(widget.startDate)} ${_formatTime(widget.startTime)}',
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),
        const SizedBox(height: 12),
        // ── TOTAL sans overflow ──────────────────────────────────────
        Row(children: [
          const Text('TOTAL',
              style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 24)),
          const Spacer(),
          Flexible(
            child: Text(
              _priceLabel,
              style: const TextStyle(
                  color: Color(0xFF1664FF),
                  fontWeight: FontWeight.w800,
                  fontSize: 28),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(children: [
      Text(label,
          style: const TextStyle(
              color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Color(0xFF0F172A), fontWeight: FontWeight.w600)),
      ),
    ]);
  }

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    TextAlign textAlign = TextAlign.left,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    String obscuringCharacter = '*',
    bool enabled = true,
  }) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
          color: enabled ? const Color(0xFFFFFFFF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD1D5DB))),
      child: TextField(
        controller: controller,
        enabled: enabled,
        textAlign: textAlign,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        obscureText: obscureText,
        obscuringCharacter: obscuringCharacter,
        style: const TextStyle(
            color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIcon: prefix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildGatewayLogoHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFDC2626), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.credit_card, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ClicToPay.com.tn',
              style: TextStyle(
                color: Color(0xFF0B4FA2),
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'by Monétique Tunisie',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGatewayFooterBrands() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 16, color: Color(0xFF9CA3AF)),
            SizedBox(width: 6),
            Text(
              'Paiement sécurisé',
              style: TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _brandMastercardChip(),
        _paymentChip(label: 'VISA', color: const Color(0xFF1E3A8A)),
        _paymentChip(label: 'C-Cash', color: const Color(0xFF6B7280)),
        _paymentChip(label: 'e-DINAR', color: const Color(0xFF6B7280)),
      ],
    );
  }

  Widget _paymentChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _brandMastercardChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 12,
            child: Stack(children: const [
              Positioned(
                  left: 0,
                  child: CircleAvatar(
                      radius: 6, backgroundColor: Color(0xFFEA4335))),
              Positioned(
                  right: 0,
                  child: CircleAvatar(
                      radius: 6, backgroundColor: Color(0xFFF59E0B))),
            ]),
          ),
          const SizedBox(width: 5),
          const Text(
            'mastercard',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'janv',
      'févr',
      'mars',
      'avr',
      'mai',
      'juin',
      'juil',
      'août',
      'sept',
      'oct',
      'nov',
      'déc'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// ── Formatters ────────────────────────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll(RegExp(r'\D'), '');
    final t = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < t.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(t[i]);
    }
    final f = buf.toString();
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
