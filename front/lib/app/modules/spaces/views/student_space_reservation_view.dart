import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/student_space_payment_view.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class StudentSpaceReservationView extends StatefulWidget {
  const StudentSpaceReservationView({super.key, required this.space});

  final Space space;

  @override
  State<StudentSpaceReservationView> createState() =>
      _StudentSpaceReservationViewState();
}

class _StudentSpaceReservationViewState
    extends State<StudentSpaceReservationView> {
  static const String _baseUrl = 'http://localhost:3001/api';
  static const int _openingHour = 9;
  static const int _closingHour = 18;
  static const List<TimeOfDay> _allowedHours = [
    TimeOfDay(hour: 9, minute: 0),
    TimeOfDay(hour: 10, minute: 0),
    TimeOfDay(hour: 11, minute: 0),
    TimeOfDay(hour: 12, minute: 0),
    TimeOfDay(hour: 13, minute: 0),
    TimeOfDay(hour: 14, minute: 0),
    TimeOfDay(hour: 15, minute: 0),
    TimeOfDay(hour: 16, minute: 0),
    TimeOfDay(hour: 17, minute: 0),
    TimeOfDay(hour: 18, minute: 0),
  ];

  String _plan = 'monthly';
  late DateTime _selectedDate;
  late DateTime _selectedEndDate;
  late TimeOfDay _selectedTime;
  late TimeOfDay _selectedEndTime;
  bool _isLoadingReservedHours = false;
  final Map<String, List<_ReservedSlot>> _reservedSlotsByDate = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedEndDate = _selectedDate.add(const Duration(days: 30));
    _selectedTime = const TimeOfDay(hour: _openingHour, minute: 0);
    _selectedEndTime = const TimeOfDay(hour: _closingHour, minute: 0);
    _loadReservedHoursForSelectedDates();
  }

  Map<String, String> get _headers {
    try {
      return Get.find<AuthService>().authHeaders;
    } catch (_) {
      return {'Content-Type': 'application/json'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF0F8),
      body: Row(
        children: [
          const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
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
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 860;
                                if (compact) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildMainForm(),
                                      const SizedBox(height: 16),
                                      _buildSummaryPanel(),
                                    ],
                                  );
                                }

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 63, child: _buildMainForm()),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      flex: 37,
                                      child: _buildSummaryPanel(),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
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

  Widget _buildPageTitle() {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 900 ? 34.0 : 46.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: Get.back,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back,
                  size: 18,
                  color: Color(0xFF334155),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finaliser votre reservation',
              style: TextStyle(
                fontSize: titleSize,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Espace : ${widget.space.name}',
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSteps() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepDone(),
          _stepLine(active: true),
          _stepCircle(2, true),
          _stepLine(active: false),
          _stepCircle(3, false),
        ],
      ),
    );
  }

  Widget _stepDone() {
    return Container(
      width: 31,
      height: 31,
      decoration: const BoxDecoration(
        color: Color(0xFF1664FF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
    );
  }

  Widget _stepCircle(int step, bool active) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _stepLine({required bool active}) {
    return Container(
      width: 56,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: active ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildMainForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE4EF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choisissez votre formule',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Selectionnez l\'option qui correspond le mieux a vos besoins d\'etude.',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              children: [
                _planTile(
                  selected: _plan == 'monthly',
                  icon: Icons.calendar_month_rounded,
                  title: 'Abonnement Mensuel',
                  subtitle: 'Acces illimite pendant 30 jours',
                  price: _monthlyPrice(),
                  unit: '/ mois',
                  onTap: () {
                    setState(() {
                      _plan = 'monthly';
                      _selectedEndDate =
                          _selectedDate.add(const Duration(days: 30));
                      _selectedEndTime =
                          const TimeOfDay(hour: _closingHour, minute: 0);
                    });
                  },
                ),
                const SizedBox(height: 12),
                _planTile(
                  selected: _plan == 'hourly',
                  icon: Icons.access_time_rounded,
                  title: 'Reservation Ponctuelle',
                  subtitle: 'Payer a l\'heure selon l\'usage',
                  price: _hourlyPrice(),
                  unit: '/ heure',
                  onTap: () {
                    setState(() {
                      _plan = 'hourly';
                      final start = _startDateTime();
                      final nextHour = start.add(const Duration(hours: 1));
                      _selectedEndDate = DateTime(
                        nextHour.year,
                        nextHour.month,
                        nextHour.day,
                      );
                      _selectedEndTime = TimeOfDay(
                        hour: nextHour.hour,
                        minute: nextHour.minute,
                      );
                    });
                  },
                ),
                const SizedBox(height: 16),
                _buildDateTimeSection(),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: _continueToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1664FF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuer vers le paiement',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTile({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required String price,
    required String unit,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F6FF) : const Color(0xFFFBFCFE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFDDEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF1664FF),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1664FF)
                        : const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Periode de reservation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 640;
            if (stacked) {
              return Column(
                children: [
                  _compactDateCard(
                    label: 'Date de debut',
                    value: _formatDate(_selectedDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(isStart: true),
                  ),
                  const SizedBox(height: 10),
                  _compactDateCard(
                    label: 'Date de fin',
                    value: _formatDate(_selectedEndDate),
                    icon: Icons.event_outlined,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _compactDateCard(
                    label: 'Date de debut',
                    value: _formatDate(_selectedDate),
                    icon: Icons.calendar_today_outlined,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _compactDateCard(
                    label: 'Date de fin',
                    value: _formatDate(_selectedEndDate),
                    icon: Icons.event_outlined,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _timeDropdownField(
                label: 'Heure de debut',
                value: _selectedTime,
                icon: Icons.access_time_rounded,
                isStart: true,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedTime = value;
                    _ensureValidDateRange();
                  });
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _timeDropdownField(
                label: 'Heure de fin',
                value: _selectedEndTime,
                icon: Icons.schedule_outlined,
                isStart: false,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _selectedEndTime = value;
                    _ensureValidDateRange();
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _openingHoursHint(),
        const SizedBox(height: 10),
        _reservedHoursHint(),
      ],
    );
  }

  Widget _openingHoursHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_outlined, size: 16, color: Color(0xFF1664FF)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Horaires autorises: 09:00 - 18:00',
              style: TextStyle(
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _compactDateCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1664FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                color: Color(0xFF64748B)),
          ],
        ),
      ),
    );
  }

  Widget _timeDropdownField({
    required String label,
    required TimeOfDay value,
    required IconData icon,
    required bool isStart,
    required ValueChanged<TimeOfDay?> onChanged,
  }) {
    final currentValue =
        _allowedHours.contains(value) ? value : _allowedHours.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF22C55E)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TimeOfDay>(
              value: currentValue,
              isExpanded: true,
              icon: Icon(icon, size: 16, color: const Color(0xFF1664FF)),
              items: _allowedHours
                  .map(
                    (hour) => DropdownMenuItem<TimeOfDay>(
                      value: hour,
                      enabled: !_isTimeDisabled(hour, isStart: isStart),
                      child: Text(_formatTimeOfDay(hour)),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryPanel() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1664FF),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x261664FF),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resume de l\'espace',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.apartment_outlined,
                      color: Color(0xFFD6E7FF), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.space.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                (widget.space.type ?? 'Espace').trim().isEmpty
                    ? 'Espace'
                    : (widget.space.type ?? 'Espace').trim(),
                style: const TextStyle(
                  color: Color(0xFFD6E7FF),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 10),
              _summaryLine(
                Icons.location_on_outlined,
                _locationLabel(widget.space),
              ),
              const SizedBox(height: 8),
              _summaryLine(
                Icons.people_outline,
                'Jusqu\'a ${widget.space.capacity} personnes',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF8DDA7)),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'L\'abonnement mensuel vous permet d\'acceder a l\'espace 7j/7 de 8h a 20h. Annulation gratuite jusqu\'a 24h avant le debut.',
                  style: TextStyle(
                    color: Color(0xFF9A5B00),
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryLine(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFD6E7FF), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initialDate = isStart ? _selectedDate : _selectedEndDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: isStart ? 'Choisir la date de debut' : 'Choisir la date de fin',
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      } else {
        _selectedEndDate = DateTime(picked.year, picked.month, picked.day);
      }
      _ensureValidDateRange();
    });

    await _loadReservedHoursForSelectedDates();
  }

  void _ensureValidDateRange() {
    final start = _startDateTime();
    final end = _endDateTime();

    if (!end.isAfter(start)) {
      if (_plan == 'monthly') {
        _selectedEndDate = _selectedDate.add(const Duration(days: 30));
        _selectedEndTime = const TimeOfDay(hour: _closingHour, minute: 0);
      } else {
        final next = start.add(const Duration(hours: 1));
        _selectedEndDate = DateTime(next.year, next.month, next.day);
        _selectedEndTime = TimeOfDay(hour: next.hour, minute: next.minute);
      }
    }

    if (_selectedTime.hour < _openingHour) {
      _selectedTime = const TimeOfDay(hour: _openingHour, minute: 0);
    }
    if (_selectedTime.hour > _closingHour) {
      _selectedTime = const TimeOfDay(hour: _closingHour, minute: 0);
    }
    if (_selectedEndTime.hour < _openingHour) {
      _selectedEndTime = const TimeOfDay(hour: _openingHour, minute: 0);
    }
    if (_selectedEndTime.hour > _closingHour) {
      _selectedEndTime = const TimeOfDay(hour: _closingHour, minute: 0);
    }

    _ensureSelectionNotReserved();
  }

  DateTime _startDateTime() {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  DateTime _endDateTime() {
    return DateTime(
      _selectedEndDate.year,
      _selectedEndDate.month,
      _selectedEndDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );
  }

  void _continueToPayment() {
    final start = _startDateTime();
    final end = _endDateTime();

    if (_hasOverlapWithReservedSlots(start, end)) {
      Get.snackbar(
        'Créneau indisponible',
        'Cette heure de reservation est deja reservee pour cet espace.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    if (!_isWithinOpeningHours(start) || !_isWithinOpeningHours(end)) {
      Get.snackbar(
        'Heure invalide',
        'L\'espace est ouvert uniquement de 09:00 à 18:00.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    if (!end.isAfter(start)) {
      Get.snackbar(
        'Heure invalide',
        'L\'heure de fin doit être après l\'heure de début.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
      );
      return;
    }

    Get.to(
      () => StudentSpacePaymentView(
        space: widget.space,
        plan: _plan,
        startDate: _selectedDate,
        startTime: _selectedTime,
        endDate: _selectedEndDate,
        endTime: _selectedEndTime,
      ),
    );
  }

  bool _isWithinOpeningHours(DateTime value) {
    final minutes = value.hour * 60 + value.minute;
    return minutes >= _openingHour * 60 && minutes <= _closingHour * 60;
  }

  String _dateKey(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  Future<void> _loadReservedHoursForSelectedDates() async {
    final keysToLoad = <String>{
      _dateKey(_selectedDate),
      _dateKey(_selectedEndDate)
    };

    setState(() => _isLoadingReservedHours = true);
    try {
      for (final key in keysToLoad) {
        await _loadReservedHoursByDateKey(key);
      }
      _ensureSelectionNotReserved();
    } catch (_) {
      // Silent: backend validations still protect against overlap.
    } finally {
      if (mounted) {
        setState(() => _isLoadingReservedHours = false);
      }
    }
  }

  Future<void> _loadReservedHoursByDateKey(String dateKey) async {
    final uri = Uri.parse(
      '$_baseUrl/reservations'
      '?filters%5Bspace%5D%5Bid%5D%5B%24eq%5D=${widget.space.id}'
      '&filters%5Bstart_datetime%5D%5B%24contains%5D=$dateKey'
      '&pagination%5BpageSize%5D=200',
    );

    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return;

    final decoded = jsonDecode(response.body);
    final List raw = decoded['data'] is List ? decoded['data'] : const [];
    final slots = <_ReservedSlot>[];

    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;

      final statusRaw =
          (item['mystatus'] ?? item['status'] ?? '').toString().toLowerCase();
      if (statusRaw.contains('annul') ||
          statusRaw.contains('rejet') ||
          statusRaw.contains('cancel') ||
          statusRaw.contains('reject')) {
        continue;
      }

      final startRaw = item['start_datetime'];
      final endRaw = item['end_datetime'];
      final start = DateTime.tryParse(startRaw?.toString() ?? '')?.toLocal();
      final end = DateTime.tryParse(endRaw?.toString() ?? '')?.toLocal();
      if (start == null || end == null || !end.isAfter(start)) continue;

      if (_dateKey(start) == dateKey) {
        slots.add(_ReservedSlot(start: start, end: end));
      }
    }

    slots.sort((a, b) => a.start.compareTo(b.start));
    _reservedSlotsByDate[dateKey] = slots;
  }

  List<_ReservedSlot> _reservedSlotsForDate(DateTime date) {
    return _reservedSlotsByDate[_dateKey(date)] ?? const [];
  }

  bool _isTimeDisabled(TimeOfDay time, {required bool isStart}) {
    final date = isStart ? _selectedDate : _selectedEndDate;
    final slots = _reservedSlotsForDate(date);
    if (slots.isEmpty) return false;

    final point =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    for (final slot in slots) {
      final minutes = point.difference(slot.start).inMinutes;
      final untilEnd = slot.end.difference(point).inMinutes;
      if (isStart) {
        if (minutes >= 0 && untilEnd > 0) return true;
      } else {
        if (minutes > 0 && untilEnd > 0) return true;
      }
    }
    return false;
  }

  bool _hasOverlapWithReservedSlots(DateTime start, DateTime end) {
    for (final slots in _reservedSlotsByDate.values) {
      for (final slot in slots) {
        if (slot.start.isBefore(end) && slot.end.isAfter(start)) {
          return true;
        }
      }
    }
    return false;
  }

  void _ensureSelectionNotReserved() {
    if (_isTimeDisabled(_selectedTime, isStart: true)) {
      final replacement = _firstAvailableHour(isStart: true);
      if (replacement != null) {
        _selectedTime = replacement;
      }
    }

    if (_isTimeDisabled(_selectedEndTime, isStart: false)) {
      final replacement = _firstAvailableHour(isStart: false);
      if (replacement != null) {
        _selectedEndTime = replacement;
      }
    }
  }

  TimeOfDay? _firstAvailableHour({required bool isStart}) {
    for (final hour in _allowedHours) {
      if (!_isTimeDisabled(hour, isStart: isStart)) {
        return hour;
      }
    }
    return null;
  }

  Widget _reservedHoursHint() {
    final slots = _reservedSlotsForDate(_selectedDate);

    if (_isLoadingReservedHours) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chargement des heures reservees...',
                style: TextStyle(
                  color: Color(0xFF9A3412),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 16, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Aucune heure deja reservee pour cette date.',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ranges = slots
        .map((s) =>
            '${_formatTimeOfDay(TimeOfDay(hour: s.start.hour, minute: s.start.minute))} - ${_formatTimeOfDay(TimeOfDay(hour: s.end.hour, minute: s.end.minute))}')
        .join('   |   ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFC2410C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Heures deja reservees: $ranges',
              style: const TextStyle(
                color: Color(0xFF9A3412),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    const weekdays = [
      'Lun',
      'Mar',
      'Mer',
      'Jeu',
      'Ven',
      'Sam',
      'Dim',
    ];
    const months = [
      'janvier',
      'fevrier',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'aout',
      'septembre',
      'octobre',
      'novembre',
      'decembre',
    ];
    final weekday = weekdays[(value.weekday + 6) % 7];
    return '$weekday ${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
  }

  String _formatTimeOfDay(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _locationLabel(Space space) {
    final location = (space.location ?? '').trim();
    final floor = (space.floor ?? '').trim();
    if (location.isEmpty && floor.isEmpty) {
      return 'Localisation non renseignee';
    }
    if (location.isNotEmpty && floor.isNotEmpty) {
      return '$location - $floor';
    }
    return location.isNotEmpty ? location : floor;
  }

  String _monthlyPrice() {
    final code = widget.space.currency.trim().toUpperCase() == 'TND'
        ? 'DT'
        : widget.space.currency;
    if (widget.space.monthlyRate <= 0) {
      return '-- $code';
    }
    return '${widget.space.monthlyRate.toStringAsFixed(0)} $code';
  }

  String _hourlyPrice() {
    final code = widget.space.currency.trim().toUpperCase() == 'TND'
        ? 'DT'
        : widget.space.currency;
    if (widget.space.hourlyRate <= 0) {
      return '-- $code';
    }
    return '${widget.space.hourlyRate.toStringAsFixed(0)} $code';
  }
}

class _ReservedSlot {
  const _ReservedSlot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}
