import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/student_space_payment_view.dart';
import 'package:get/get.dart';

class StudentSpaceReservationView extends StatefulWidget {
  const StudentSpaceReservationView({super.key, required this.space});

  final Space space;

  @override
  State<StudentSpaceReservationView> createState() =>
      _StudentSpaceReservationViewState();
}

class _StudentSpaceReservationViewState
    extends State<StudentSpaceReservationView> {
  String _plan = 'monthly';
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late DateTime _selectedEndDate;
  late TimeOfDay _selectedEndTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay(hour: now.hour, minute: 0);
    _selectedEndDate = _selectedDate.add(const Duration(days: 30));
    _selectedEndTime = _selectedTime;
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
                                        flex: 37, child: _buildSummaryPanel()),
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
                child:
                    Icon(Icons.arrow_back, size: 18, color: Color(0xFF334155)),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Finaliser votre reservation',
              style: TextStyle(
                fontSize: titleSize,
                height: 1.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
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
          _stepCircle(1, true),
          _stepLine(),
          _stepCircle(2, false),
          _stepLine(),
          _stepCircle(3, false),
        ],
      ),
    );
  }

  Widget _stepCircle(int index, bool active) {
    return Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF1664FF) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$index',
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _stepLine() {
    return Container(
      width: 56,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFE2E8F0),
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
                  "Selectionnez l'option qui correspond le mieux a vos besoins d'etude.",
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
                      _selectedEndTime = _selectedTime;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _planTile(
                  selected: _plan == 'hourly',
                  icon: Icons.access_time_rounded,
                  title: 'Reservation Ponctuelle',
                  subtitle: "Payer a l'heure selon l'usage",
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

  Widget _inputField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
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
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: highlighted ? const Color(0xFFF8FBFF) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: highlighted
                    ? const Color(0xFFBFD9FF)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  size: 17,
                  color: highlighted
                      ? const Color(0xFF1664FF)
                      : const Color(0xFF475569),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9E8FF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'DATE DE DEBUT',
                  value: _formatDate(_selectedDate),
                  icon: Icons.calendar_today_outlined,
                  onTap: () => _pickDate(isStart: true),
                  highlighted: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'HEURE DE DEBUT',
                  value: _selectedTime.format(context),
                  icon: Icons.access_time_outlined,
                  onTap: () => _pickTime(isStart: true),
                  highlighted: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  label: 'DATE DE FIN',
                  value: _formatDate(_selectedEndDate),
                  icon: Icons.event_outlined,
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _inputField(
                  label: 'HEURE DE FIN',
                  value: _selectedEndTime.format(context),
                  icon: Icons.schedule_outlined,
                  onTap: () => _pickTime(isStart: false),
                ),
              ),
            ],
          ),
        ],
      ),
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
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Resume de l'espace",
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
                  "L'abonnement mensuel vous permet d'acceder a l'espace 7j/7 de 8h a 20h. Annulation gratuite jusqu'a 24h avant le debut.",
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
      children: [
        Icon(icon, size: 15, color: const Color(0xFFD6E7FF)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD6E7FF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart ? _selectedDate : _selectedEndDate;
    final first = isStart
        ? DateTime(now.year, now.month, now.day)
        : DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1664FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _selectedDate = selected;
      } else {
        _selectedEndDate = selected;
      }
      _ensureValidDateRange();
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? _selectedTime : _selectedEndTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1664FF),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              hourMinuteColor: Color(0xFFF1F5F9),
              dayPeriodColor: Color(0xFFF1F5F9),
              dialBackgroundColor: Color(0xFFF8FAFC),
              entryModeIconColor: Color(0xFF64748B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        _selectedTime = selected;
      } else {
        _selectedEndTime = selected;
      }
      _ensureValidDateRange();
    });
  }

  void _ensureValidDateRange() {
    final start = _startDateTime();
    final end = _endDateTime();

    if (!end.isAfter(start)) {
      final adjusted = start.add(_plan == 'monthly'
          ? const Duration(days: 30)
          : const Duration(hours: 1));
      _selectedEndDate = DateTime(adjusted.year, adjusted.month, adjusted.day);
      _selectedEndTime =
          TimeOfDay(hour: adjusted.hour, minute: adjusted.minute);
    }
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
    _ensureValidDateRange();

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

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _hourlyPrice() {
    final code = _currencyCode(widget.space.currency);
    if (widget.space.hourlyRate <= 0) return '-- $code';
    return '${widget.space.hourlyRate.toStringAsFixed(0)} $code';
  }

  String _monthlyPrice() {
    final code = _currencyCode(widget.space.currency);
    if (widget.space.monthlyRate <= 0) return '-- $code';
    return '${widget.space.monthlyRate.toStringAsFixed(0)} $code';
  }

  static String _currencyCode(String currency) {
    final normalized = currency.trim().toUpperCase();
    if (normalized == 'TND') return 'DT';
    return normalized.isEmpty ? 'DT' : normalized;
  }

  static String _locationLabel(Space s) {
    final location = (s.location ?? '').trim();
    final floor = (s.floor ?? '').trim();

    if (location.isEmpty && floor.isEmpty) return 'xxxx';
    if (location.isEmpty) return floor;
    if (floor.isEmpty) return location;
    return '$location - $floor';
  }
}
