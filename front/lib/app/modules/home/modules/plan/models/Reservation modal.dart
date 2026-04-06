import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/models/space_model%20plan.dart';
import 'package:flutter_getx_app/services/r%C3%A9servation_api_service.dart';

import 'package:intl/intl.dart';

class ReservationModal extends StatefulWidget {
  final SpaceModel space;
  final ReservationApiService apiService;
  final List<EquipmentModel> availableEquipments;

  const ReservationModal({
    super.key,
    required this.space,
    required this.apiService,
    this.availableEquipments = const [],
  });

  static Future<bool?> show(
    BuildContext context, {
    required SpaceModel space,
    required ReservationApiService apiService,
    List<EquipmentModel> availableEquipments = const [],
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => ReservationModal(
        space: space,
        apiService: apiService,
        availableEquipments: availableEquipments,
      ),
    );
  }

  @override
  State<ReservationModal> createState() => _ReservationModalState();
}

class _ReservationModalState extends State<ReservationModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  DateTime _selectedDate = DateTime.now();
  bool _fullDay = false;
  String? _startTime;
  String? _endTime;
  int _participants = 1;
  bool _isLoading = false;
  List<Map<String, dynamic>> _existingReservations = [];
  String? _errorMessage;
  final Set<String> _selectedEquipmentIds = {};

  final List<String> _timeSlots = [
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '11:30',
    '12:00',
    '12:30',
    '13:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
    '17:00',
    '17:30',
    '18:00',
  ];

  List<EquipmentModel> get _equipments {
    if (widget.space.equipments.isNotEmpty) return widget.space.equipments;
    return widget.availableEquipments;
  }

  String _equipmentKey(int index, EquipmentModel equipment) {
    final id = equipment.id.trim();
    if (id.isNotEmpty) return 'id_$id';

    final name = equipment.name.trim().toLowerCase();
    if (name.isNotEmpty)
      return 'name_${name.replaceAll(RegExp(r'\s+'), '_')}_$index';

    return 'equipment_$index';
  }

  double get _totalAmount {
    double baseAmt = 0;
    if (_fullDay) {
      baseAmt = widget.space.pricePerDay;
    } else if (_startTime != null && _endTime != null) {
      final start = _timeSlots.indexOf(_startTime!);
      final end = _timeSlots.indexOf(_endTime!);
      if (start >= 0 && end > start) {
        baseAmt = (end - start) * 0.5 * widget.space.pricePerHour;
      }
    }

    // Ajout du montant pour chaque équipement sélectionné
    double equipmentAmt = 0;
    for (var i = 0; i < _equipments.length; i++) {
      final e = _equipments[i];
      final key = _equipmentKey(i, e);
      if (_selectedEquipmentIds.contains(key)) {
        equipmentAmt += e.price;
      }
    }

    return baseAmt + equipmentAmt;
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadReservations();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    try {
      final res = await widget.apiService.fetchReservationsForDate(
          spaceId: widget.space.id, date: _selectedDate);
      if (mounted) setState(() => _existingReservations = res);
    } catch (_) {}
  }

  String _formatTimeFromRaw(dynamic raw) {
    if (raw == null) return '';
    final text = raw.toString().trim();
    if (text.isEmpty) return '';

    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return DateFormat('HH:mm').format(parsed.toLocal());
    }

    // Fallback: already a time-only value like "09:30".
    if (text.length >= 5 && text.contains(':')) {
      return text.substring(0, 5);
    }
    return '';
  }

  bool _isTimeSlotBooked(String time) {
    for (final res in _existingReservations) {
      final attrs = res['attributes'] ?? res;

      final statusRaw =
          (attrs['mystatus'] ?? attrs['status'] ?? '').toString().toLowerCase();
      final isCancelled = statusRaw.contains('annul') ||
          statusRaw.contains('cancel') ||
          statusRaw.contains('rej') ||
          statusRaw.contains('reject');
      if (isCancelled) continue;

      if (attrs['is_all_day'] == true || attrs['fullDay'] == true) return true;
      final startRaw = attrs['start_datetime'] ?? attrs['startTime'] ?? '';
      final endRaw = attrs['end_datetime'] ?? attrs['endTime'] ?? '';
      final startT = _formatTimeFromRaw(startRaw);
      final endT = _formatTimeFromRaw(endRaw);
      if (startT.isNotEmpty &&
          endT.isNotEmpty &&
          time.compareTo(startT) >= 0 &&
          time.compareTo(endT) < 0) return true;
    }
    return false;
  }

  bool get _canSubmit {
    if (_participants < 1 || _participants > widget.space.maxPersons)
      return false;
    if (_fullDay) return true;
    if (_startTime == null || _endTime == null) return false;
    return _startTime!.compareTo(_endTime!) < 0;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dateStr = _selectedDate.toIso8601String().split('T').first;
      final startDt =
          _fullDay ? '${dateStr}T09:00:00' : '${dateStr}T${_startTime}:00';
      final endDt =
          _fullDay ? '${dateStr}T18:00:00' : '${dateStr}T${_endTime}:00';

      await widget.apiService.createReservationRaw({
        'data': {
          'space': widget.space.id,
          'start_datetime': startDt,
          'end_datetime': endDt,
          'is_all_day': _fullDay,
          'attendees': _participants,
          'mystatus': 'En_attente',
          'organizer_name': 'Réservation App',
          'organizer_phone': '00000000',
          'total_amount':
              _totalAmount > 0 ? _totalAmount : widget.space.pricePerDay,
        }
      });

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Réservation de "${widget.space.name}" effectuée !',
                    style: const TextStyle(fontWeight: FontWeight.w500))),
          ]),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.of(context).size;
    final isMobile = viewport.width < 640;
    final horizontalInset = isMobile ? 8.0 : 24.0;
    final maxDialogWidth = isMobile
        ? (viewport.width - (horizontalInset * 2)).clamp(320.0, 640.0)
        : 820.0;
    final borderRadius = isMobile ? 14.0 : 16.0;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: horizontalInset,
            vertical: isMobile ? 10 : 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxDialogWidth,
              maxHeight: viewport.height * 0.92,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(borderRadius),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 32,
                        offset: const Offset(0, 8))
                  ],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isMobile ? 14 : 24,
                        0,
                        isMobile ? 14 : 24,
                        isMobile ? 14 : 24,
                      ),
                      child: _buildBody(),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
      decoration: BoxDecoration(
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFF8FAFC),
            const Color(0xFFF0FDF4).withOpacity(0.55),
          ],
        ),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.space.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Wrap(spacing: 12, children: [
              _InfoChip(
                  icon: Icons.group_outlined,
                  label: 'Max ${widget.space.maxPersons} personnes'),
              if (widget.space.location.isNotEmpty)
                _InfoChip(
                    icon: Icons.location_on_outlined,
                    label: widget.space.location),
              _InfoChip(
                  icon: Icons.euro_outlined,
                  label:
                      '${widget.space.pricePerHour.toStringAsFixed(0)} TND/h • '
                      '${widget.space.pricePerDay.toStringAsFixed(0)} TND/jour'),
            ]),
          ]),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          style: IconButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              backgroundColor: const Color(0xFFF8FAFC)),
        ),
      ]),
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 760;

      final leftColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSection('Description', _buildDescription()),
          if (_equipments.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection('Équipements disponibles', _buildEquipments()),
          ],
          const SizedBox(height: 20),
          _buildSection('Nombre de participants *', _buildParticipants()),
        ],
      );

      final rightColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildSection('Sélectionner une date', _buildCalendar()),
          const SizedBox(height: 20),
          _buildSection('Sélectionner l\'horaire', _buildTimeSelector()),
          const SizedBox(height: 16),
          _buildSection('Emploi du temps du Aujourd\'hui', _buildTimeline()),
          const SizedBox(height: 20),
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Text(_errorMessage!,
                  style:
                      const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
            ),
          _buildSubmitButton(),
          const SizedBox(height: 4),
          const Center(
            child: Text('* Tous les champs sont obligatoires',
                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ),
        ],
      );

      if (isCompact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leftColumn,
            const SizedBox(height: 10),
            rightColumn,
          ],
        );
      }

      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(flex: 5, child: leftColumn),
        const SizedBox(width: 28),
        Expanded(flex: 6, child: rightColumn),
      ]);
    });
  }

  Widget _buildSection(String title, Widget child) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(2))),
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
      ]),
      const SizedBox(height: 10),
      child,
    ]);
  }

  Widget _buildDescription() {
    final desc = widget.space.description;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8)),
      child: Text(
        desc.isEmpty ? 'Aucune description disponible.' : desc,
        style: TextStyle(
          fontSize: 13,
          color:
              desc.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          fontStyle: desc.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildEquipments() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(_equipments.length, (index) {
        final e = _equipments[index];
        final String equipmentKey = _equipmentKey(index, e);
        final isSelected = _selectedEquipmentIds.contains(equipmentKey);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => setState(() {
              if (isSelected) {
                _selectedEquipmentIds.remove(equipmentKey);
              } else {
                _selectedEquipmentIds.add(equipmentKey);
              }
            }),
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    const Icon(Icons.check, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    e.price > 0
                        ? '${e.name} (${e.price.toStringAsFixed(0)} TND/j)'
                        : e.name,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isSelected ? Colors.white : const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildParticipants() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _participants > 1
                  ? () => setState(() => _participants--)
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Icon(
                  Icons.remove,
                  size: 20,
                  color: _participants > 1
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextFormField(
                initialValue: _participants.toString(),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (v) {
                  final val = int.tryParse(v);
                  if (val != null)
                    setState(() =>
                        _participants = val.clamp(1, widget.space.maxPersons));
                },
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _participants < widget.space.maxPersons
                  ? () => setState(() => _participants++)
                  : null,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: _participants < widget.space.maxPersons
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text('Capacité maximale: ${widget.space.maxPersons} personnes',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
    ]);
  }

  Widget _buildCalendar() {
    return _CompactCalendar(
      selectedDate: _selectedDate,
      onDateSelected: (d) {
        setState(() {
          _selectedDate = d;
          _startTime = null;
          _endTime = null;
          _existingReservations = [];
        });
        _loadReservations();
      },
    );
  }

  Widget _buildTimeSelector() {
    final endSlots = _startTime == null
        ? _timeSlots
        : _timeSlots.where((t) => t.compareTo(_startTime!) > 0).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Checkbox journée entière - zone entière cliquable
      InkWell(
        onTap: () => setState(() {
          _fullDay = !_fullDay;
          _startTime = null;
          _endTime = null;
        }),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _fullDay,
                onChanged: (_) {}, // Géré par InkWell parent
                activeColor: const Color(0xFF22C55E),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Réserver toute la journée (09:00 - 18:00)',
                  style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
            ),
          ]),
        ),
      ),
      if (!_fullDay) ...[
        const SizedBox(height: 12),
        // Labels
        const Row(children: [
          Expanded(
              child: Text('Heure de début',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
          SizedBox(width: 12),
          Expanded(
              child: Text('Heure de fin',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
        ]),
        const SizedBox(height: 6),
        // Selects natifs Flutter
        Row(children: [
          Expanded(
              child: _buildSelect(
            value: _startTime,
            items: _timeSlots,
            hint: 'Début (ex: 09:00)',
            onChanged: (v) => setState(() {
              _startTime = v;
              if (_endTime != null &&
                  v != null &&
                  _endTime!.compareTo(v) <= 0) {
                _endTime = null;
              }
            }),
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _buildSelect(
            value: _endTime,
            items: endSlots,
            hint: 'Fin (ex: 10:00)',
            onChanged: (v) => setState(() => _endTime = v),
          )),
        ]),
        if (_startTime != null && _endTime != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Durée: $_startTime → $_endTime',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(_timeSlots.indexOf(_endTime!) - _timeSlots.indexOf(_startTime!)) * 30} min',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
        ]
      ],
    ]);
  }

  Widget _buildSelect({
    required String? value,
    required List<String> items,
    required String hint,
    required void Function(String?) onChanged,
  }) {
    final hasValue = value != null && value.isNotEmpty;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasValue ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(hint,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8))),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color:
                  hasValue ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
              size: 24),
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF1E293B)),
          items: items.map((t) {
            final booked = _isTimeSlotBooked(t);
            return DropdownMenuItem<String>(
              value: t,
              enabled: !booked,
              child: Text(
                t,
                style: TextStyle(
                    fontSize: 13.5,
                    color: booked
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF1E293B),
                    fontWeight: booked ? FontWeight.normal : FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_existingReservations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text('Aucune réservation pour cette date',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic)),
      );
    }
    return Column(
      children: _existingReservations.map((r) {
        final attrs = r['attributes'] ?? r;
        final startRaw = attrs['start_datetime'] ?? attrs['startTime'] ?? '';
        final endRaw = attrs['end_datetime'] ?? attrs['endTime'] ?? '';
        final isFullDay =
            attrs['is_all_day'] == true || attrs['fullDay'] == true;
        final startT = isFullDay ? '09:00' : _formatTimeFromRaw(startRaw);
        final endT = isFullDay ? '18:00' : _formatTimeFromRaw(endRaw);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(children: [
            const Icon(Icons.schedule, size: 14, color: Color(0xFFEA580C)),
            const SizedBox(width: 6),
            Text('$startT → $endT',
                style:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF9A3412))),
          ]),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _canSubmit && !_isLoading ? _submit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF22C55E),
          disabledBackgroundColor: const Color(0xFFE2E8F0),
          foregroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF94A3B8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white)))
            : const Text('Réserver l\'Espace',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }
}

// ─── InfoChip ────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: const Color(0xFF64748B)),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
    ]);
  }
}

// ─── Compact Calendar ────────────────────────────────────────────────────────
class _CompactCalendar extends StatefulWidget {
  final DateTime selectedDate;
  final void Function(DateTime) onDateSelected;
  const _CompactCalendar(
      {required this.selectedDate, required this.onDateSelected});

  @override
  State<_CompactCalendar> createState() => _CompactCalendarState();
}

class _CompactCalendarState extends State<_CompactCalendar> {
  late DateTime _viewMonth;
  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  static const _months = [
    'Janvier',
    'Février',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Août',
    'Septembre',
    'Octobre',
    'Novembre',
    'Décembre',
  ];

  @override
  void initState() {
    super.initState();
    _viewMonth = DateTime(widget.selectedDate.year, widget.selectedDate.month);
  }

  List<DateTime?> get _calendarDays {
    final firstDay = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final cells = <DateTime?>[];
    for (int i = 0; i < startOffset; i++) cells.add(null);
    for (int d = 1; d <= daysInMonth; d++)
      cells.add(DateTime(_viewMonth.year, _viewMonth.month, d));
    while (cells.length % 7 != 0) cells.add(null);
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = _calendarDays;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Material(
            color: Colors.transparent,
            child: _NavBtn(
                icon: Icons.chevron_left,
                onTap: () => setState(() => _viewMonth =
                    DateTime(_viewMonth.year, _viewMonth.month - 1))),
          ),
          Text('${_months[_viewMonth.month - 1]} ${_viewMonth.year}',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
          Material(
            color: Colors.transparent,
            child: _NavBtn(
                icon: Icons.chevron_right,
                onTap: () => setState(() => _viewMonth =
                    DateTime(_viewMonth.year, _viewMonth.month + 1))),
          ),
        ]),
        const SizedBox(height: 8),
        Row(
            children: _weekdays
                .map((d) => Expanded(
                      child: Center(
                          child: Text(d,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8)))),
                    ))
                .toList()),
        const SizedBox(height: 4),
        ...List.generate(
            days.length ~/ 7,
            (row) => Row(
                  children: List.generate(7, (col) {
                    final d = days[row * 7 + col];
                    if (d == null)
                      return const Expanded(child: SizedBox(height: 32));
                    final isSelected = d.year == widget.selectedDate.year &&
                        d.month == widget.selectedDate.month &&
                        d.day == widget.selectedDate.day;
                    final isToday = d.year == today.year &&
                        d.month == today.month &&
                        d.day == today.day;
                    final isPast = d
                        .isBefore(DateTime(today.year, today.month, today.day));
                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isPast ? null : () => widget.onDateSelected(d),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap:
                                isPast ? null : () => widget.onDateSelected(d),
                            mouseCursor: isPast
                                ? SystemMouseCursors.forbidden
                                : SystemMouseCursors.click,
                            borderRadius: BorderRadius.circular(8),
                            splashColor:
                                const Color(0xFF22C55E).withOpacity(0.2),
                            highlightColor:
                                const Color(0xFF22C55E).withOpacity(0.1),
                            child: Container(
                              height: 40,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF22C55E)
                                    : isToday
                                        ? const Color(0xFFDCFCE7)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: const Color(0xFF86EFAC),
                                        width: 1.5)
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Text('${d.day}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected || isToday
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: isSelected
                                        ? Colors.white
                                        : isPast
                                            ? const Color(0xFFCBD5E1)
                                            : isToday
                                                ? const Color(0xFF166534)
                                                : const Color(0xFF1E293B),
                                  )),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                )),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(6)),
          child: Column(children: [
            Text(
                DateFormat('EEEE d MMMM yyyy', 'fr')
                    .format(widget.selectedDate),
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF166534))),
            const Text("Aujourd'hui",
                style: TextStyle(fontSize: 10.5, color: Color(0xFF4ADE80))),
          ]),
        ),
      ]),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(10),
            splashColor: const Color(0xFF22C55E).withOpacity(0.2),
            highlightColor: const Color(0xFF22C55E).withOpacity(0.1),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
