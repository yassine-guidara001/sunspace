import 'dart:convert';
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
  });

  final Space space;
  final String plan;
  final DateTime startDate;
  final TimeOfDay startTime;

  @override
  State<StudentSpacePaymentView> createState() =>
      _StudentSpacePaymentViewState();
}

class _StudentSpacePaymentViewState extends State<StudentSpacePaymentView> {
  static const String _baseUrl = 'http://localhost:3001/api';

  final _cardHolderController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
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
      final dateStr = widget.startDate.toIso8601String().split('T').first;
      final h = widget.startTime.hour.toString().padLeft(2, '0');
      final m = widget.startTime.minute.toString().padLeft(2, '0');

      DateTime endDateTime;
      if (widget.plan == 'monthly') {
        endDateTime = widget.startDate.add(const Duration(days: 30));
      } else {
        endDateTime = DateTime(
          widget.startDate.year,
          widget.startDate.month,
          widget.startDate.day,
          widget.startTime.hour + 1,
          widget.startTime.minute,
        );
      }

      final startDt = '${dateStr}T$h:$m:00.000Z';
      final endDt = endDateTime
          .toIso8601String()
          .replaceFirst(RegExp(r'\.\d+Z?$'), '.000Z');

      final payload = {
        'data': {
          'space': widget.space.id.toString(),
          'start_datetime': startDt,
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
        final body = jsonDecode(response.body);
        throw Exception(body['error']?['message'] ?? '${response.statusCode}');
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

  double get _price => widget.plan == 'monthly'
      ? widget.space.monthlyRate
      : widget.space.hourlyRate;

  String get _priceLabel {
    final code = widget.space.currency.trim().toUpperCase() == 'TND'
        ? 'DT'
        : widget.space.currency;
    if (_price <= 0) return '-- $code';
    return '${_price.toStringAsFixed(0)} $code';
  }

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4EF)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x120F172A), blurRadius: 20, offset: Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18)),
          ),
          child: Row(children: [
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAIEMENT SECURISE',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A))),
                    SizedBox(height: 4),
                    Text('Vos données sont cryptées et protégées.',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                  ]),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F1FF),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.shield_outlined,
                  color: Color(0xFF60A5FA), size: 26),
            ),
          ]),
        ),
        // Fields
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Nom sur la carte'),
            const SizedBox(height: 6),
            _textInput(
                controller: _cardHolderController, hint: 'Ex. Jean Dupont'),
            const SizedBox(height: 10),
            _label('Numéro de carte'),
            const SizedBox(height: 6),
            _textInput(
              controller: _cardNumberController,
              hint: '1234 5678 9012 3456',
              prefix: const Icon(Icons.credit_card,
                  size: 16, color: Color(0xFF64748B)),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
                _CardNumberFormatter(),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label("Date d'expiration"),
                    const SizedBox(height: 6),
                    _textInput(
                      controller: _expiryController,
                      hint: 'MM/AA',
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryDateFormatter(),
                      ],
                    ),
                  ])),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _label('CVC'),
                    const SizedBox(height: 6),
                    _textInput(
                      controller: _cvcController,
                      hint: '000',
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ])),
            ]),
            const SizedBox(height: 14),
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFFBFCFE),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(children: [
                _brandMastercard(),
                const SizedBox(width: 10),
                _brandVisa(),
                const Spacer(),
                const Text('PAIEMENT CRYPTÉ SSL 256 BITS',
                    style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ]),
            ),
          ]),
        ),
        // Footer
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
          child: Row(children: [
            TextButton(
              onPressed: Get.back,
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A)),
              child: const Text("Modifier l'offre",
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Spacer(),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.credit_card_outlined, size: 16),
                        const SizedBox(width: 8),
                        Text('Payer $_priceLabel',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                      ]),
              ),
            ),
          ]),
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
        _detailRow(
            'Durée :', widget.plan == 'monthly' ? '30 Jours' : '1 Heure'),
        const SizedBox(height: 10),
        _detailRow('Début :', _formatDate(widget.startDate)),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Color(0xFF0F172A), fontSize: 12, fontWeight: FontWeight.w600));

  Widget _textInput({
    required TextEditingController controller,
    required String hint,
    Widget? prefix,
    TextAlign textAlign = TextAlign.left,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
          color: const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextField(
        controller: controller,
        textAlign: textAlign,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
            color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          prefixIcon: prefix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }

  Widget _brandMastercard() {
    return Row(children: [
      SizedBox(
        width: 18,
        height: 12,
        child: Stack(children: const [
          Positioned(
              left: 0,
              child:
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFFEA4335))),
          Positioned(
              right: 0,
              child:
                  CircleAvatar(radius: 6, backgroundColor: Color(0xFFF59E0B))),
        ]),
      ),
      const SizedBox(width: 4),
      const Text('mastercard',
          style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _brandVisa() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0))),
      child: const Text('visa',
          style: TextStyle(
              color: Color(0xFF1E40AF),
              fontSize: 10,
              fontWeight: FontWeight.w700)),
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

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue o, TextEditingValue n) {
    final digits = n.text.replaceAll(RegExp(r'\D'), '');
    final t = digits.length > 4 ? digits.substring(0, 4) : digits;
    final f = t.length > 2 ? '${t.substring(0, 2)}/${t.substring(2)}' : t;
    return TextEditingValue(
        text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
