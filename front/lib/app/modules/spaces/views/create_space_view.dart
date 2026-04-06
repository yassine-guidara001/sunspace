import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/spaces/controllers/spaces_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';

class CreateSpaceView extends StatefulWidget {
  const CreateSpaceView({super.key, this.space});
  final Space? space;

  @override
  State<CreateSpaceView> createState() => _CreateSpaceViewState();
}

class _CreateSpaceViewState extends State<CreateSpaceView> {
  final _formKey = GlobalKey<FormState>();

  static const _pageBg = Color(0xFFF1F5F9);
  static const _cardBorder = Color(0xFFE2E8F0);
  static const _muted = Color(0xFF64748B);
  static const _primary = Color(0xFF1664FF);
  static const _fieldBg = Colors.white;

  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _floor;
  late final TextEditingController _capacity;
  late final TextEditingController _area;
  late final TextEditingController _svgWidth;
  late final TextEditingController _svgHeight;
  late final TextEditingController _hourlyRate;
  late final TextEditingController _dailyRate;
  late final TextEditingController _monthlyRate;
  late final TextEditingController _currency;
  late final TextEditingController _description;

  late String _selectedType;
  late String _selectedStatus;
  bool _isCoworking = false;
  bool _allowGuestReservations = false;

  final List<String> _types = const [
    'Espace de Travail',
    'Salle de Réunion',
    'Salle de Formation',
    'Bureau Privé',
  ];

  final List<String> _statuses = const [
    'Disponible',
    'Occupé',
    'Maintenance',
  ];

  String _normalizeStatusForDropdown(String? raw) {
    final v = (raw ?? '').trim();
    if (v.isEmpty) return _statuses.first;

    final normalized = v
        .toLowerCase()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.contains('maint')) return 'Maintenance';
    if (normalized.contains('occup')) return 'Occupé';
    if (normalized.contains('dispo') || normalized == 'available') {
      return 'Disponible';
    }
    if (normalized == 'occupied') return 'Occupé';
    if (normalized == 'maintenance') return 'Maintenance';

    // Valeur inattendue du backend: on retombe sur la valeur par défaut.
    return _statuses.first;
  }

  @override
  void initState() {
    super.initState();

    final s = widget.space;

    _name = TextEditingController(text: s?.name ?? '');
    _location = TextEditingController(text: s?.location ?? '');
    _floor = TextEditingController(text: s?.floor ?? '');
    _capacity = TextEditingController(text: (s?.capacity ?? 1).toString());
    _area = TextEditingController(text: (s?.area ?? 0).toString());
    _svgWidth = TextEditingController(text: (s?.svgWidth ?? 0).toString());
    _svgHeight = TextEditingController(text: (s?.svgHeight ?? 0).toString());
    _hourlyRate = TextEditingController(text: (s?.hourlyRate ?? 0).toString());
    _dailyRate = TextEditingController(text: (s?.dailyRate ?? 0).toString());
    _monthlyRate =
        TextEditingController(text: (s?.monthlyRate ?? 0).toString());
    _currency = TextEditingController(text: s?.currency ?? 'TND');
    _description = TextEditingController(text: s?.description ?? '');

    _selectedType = s?.type ?? _types.first;
    _selectedStatus = _normalizeStatusForDropdown(s?.status);
    _isCoworking = s?.isCoworking ?? false;
    _allowGuestReservations = s?.allowGuestReservations ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.space != null;

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
                    padding: const EdgeInsets.all(24),
                    child: _content(isEdit),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(bool isEdit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isEdit),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardBorder),
          ),
          padding: const EdgeInsets.all(14),
          child: _form(isEdit),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isEdit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          onPressed: () => Get.back(result: false),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF475569)),
          splashRadius: 18,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? "Modifier l'espace" : "Créer un espace",
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isEdit
                    ? "Modifiez les informations de l'espace de coworking"
                    : "Ajoutez un nouvel espace à votre espace de coworking",
                style: const TextStyle(color: _muted, ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(bool isEdit) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 920;
          final spacing = 16.0;
          final fieldWidth = isWide
              ? (constraints.maxWidth - spacing) / 2
              : constraints.maxWidth;

          return Wrap(
            spacing: spacing,
            runSpacing: 14,
            children: [
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Nom de l'espace",
                  _name,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _dropdown(
                  "Type",
                  _types,
                  _selectedType,
                  (v) => setState(() => _selectedType = v),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Localisation",
                  _location,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Étage",
                  _floor,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Capacité (personnes)",
                  _capacity,
                  keyboard: TextInputType.number,
                  requiredField: true,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Surface (m²)",
                  _area,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Largeur SVG (px)",
                  _svgWidth,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Hauteur SVG (px)",
                  _svgHeight,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _dropdown(
                  "Statut",
                  _statuses,
                  _selectedStatus,
                  (v) => setState(() => _selectedStatus = v),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Tarif horaire",
                  _hourlyRate,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Tarif journalier",
                  _dailyRate,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Tarif mensuel",
                  _monthlyRate,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: _field(
                  "Devise",
                  _currency,
                ),
              ),
              SizedBox(
                width: isWide ? constraints.maxWidth : fieldWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Wrap(
                    spacing: 22,
                    runSpacing: 6,
                    children: [
                      _checkbox(
                        label: "C'est un espace de coworking",
                        value: _isCoworking,
                        onChanged: (v) =>
                            setState(() => _isCoworking = v ?? false),
                      ),
                      _checkbox(
                        label: "Autoriser les réservations invitées",
                        value: _allowGuestReservations,
                        onChanged: (v) => setState(
                            () => _allowGuestReservations = v ?? false),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: isWide ? constraints.maxWidth : fieldWidth,
                child: _field(
                  "Description",
                  _description,
                  maxLines: 4,
                  hintText: "Description détaillée de l'espace...",
                ),
              ),
              SizedBox(
                width: isWide ? constraints.maxWidth : fieldWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton(
                      onPressed: () => _submit(isEdit),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(isEdit ? 'Mettre à jour' : 'Créer'),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _field(String label, TextEditingController c,
      {TextInputType? keyboard,
      bool requiredField = false,
      int maxLines = 1,
      String? hintText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: c,
          keyboardType: keyboard,
          maxLines: maxLines,
          validator: (v) {
            if (requiredField && (v == null || v.trim().isEmpty)) {
              return "$label obligatoire";
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.grey, ),
            filled: true,
            fillColor: _fieldBg,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _primary),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> items, String value,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _fieldBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 18),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: _primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle()),
        ],
      ),
    );
  }

  // 🔥 slug generator
  String _slug(String text) {
    return text
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '');
  }

  Future<void> _submit(bool isEdit) async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "name": _name.text.trim(),
      "slug": _slug(_name.text),
      "type": _selectedType,
      "location": _location.text.trim(),
      "floor": _floor.text.trim(),
      "capacity": int.parse(_capacity.text),
      "area_sqm": double.tryParse(_area.text) ?? 0,
      "svg_width": int.tryParse(_svgWidth.text) ?? 0,
      "svg_height": int.tryParse(_svgHeight.text) ?? 0,
      "availability_status": _selectedStatus,
      "is_coworking": _isCoworking,
      "allow_guest_reservations": _allowGuestReservations,
      "hourly_rate": double.tryParse(_hourlyRate.text) ?? 0,
      "daily_rate": double.tryParse(_dailyRate.text) ?? 0,
      "monthly_rate": double.tryParse(_monthlyRate.text) ?? 0,
      "currency": _currency.text.isEmpty ? "TND" : _currency.text,
      "description": _description.text,
    };

    final controller = Get.find<SpaceController>();

    if (isEdit) {
      final ok =
          await controller.updateSpace(widget.space!.documentId, payload);
      if (!ok) return;
    } else {
      final created = await controller.create(payload);
      if (created == null) return;
    }

    Get.back(result: true);
  }
}
