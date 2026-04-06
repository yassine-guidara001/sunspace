import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/data/models/space_model.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:flutter_getx_app/app/modules/spaces/controllers/spaces_controller.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/create_space_view.dart';

class SpaceDetailsView extends StatefulWidget {
  const SpaceDetailsView({super.key, required this.space});

  final Space space;

  @override
  State<SpaceDetailsView> createState() => _SpaceDetailsViewState();
}

class _SpaceDetailsViewState extends State<SpaceDetailsView> {
  late Space _space;

  @override
  void initState() {
    super.initState();
    _space = widget.space;
  }

  @override
  Widget build(BuildContext context) {
    final displayStatus = _toDisplayStatus(_space.status);
    final currency = _displayCurrency(_space.currency);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(displayStatus),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: _infoCard(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  _pricingCard(currency),
                                  const SizedBox(height: 16),
                                  _systemCard(),
                                ],
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String displayStatus) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _space.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _typeChip(_space.type ?? '—'),
                    const SizedBox(width: 8),
                    _statusChip(displayStatus),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _onEdit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1664FF),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    final location =
        _space.location?.isNotEmpty == true ? _space.location! : '—';
    final floor = _space.floor?.isNotEmpty == true ? _space.floor! : '';
    final locationValue = floor.isNotEmpty
        ? (location == '—' ? floor : '$location\n$floor')
        : location;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations générales',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Localisation',
                  value: locationValue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _infoTile(
                  icon: Icons.people_alt_outlined,
                  title: 'Capacité',
                  value: '${_space.capacity} personnes',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Description',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            _space.description.trim().isEmpty
                ? 'Aucune description disponible pour cet espace.'
                : _space.description,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _pricingCard(String currency) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tarification',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _priceRow('Par Heure', _space.hourlyRate, currency),
          const SizedBox(height: 10),
          _priceRow('Par Jour', _space.dailyRate, currency),
          const SizedBox(height: 10),
          _priceRow('Par Mois', _space.monthlyRate, currency),
        ],
      ),
    );
  }

  Widget _systemCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations système',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _systemRow('Créé le', _formatDate(_space.createdAt)),
          const SizedBox(height: 10),
          _systemRow('Mis à jour le', _formatDate(_space.updatedAt)),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1664FF)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style:
                      const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, double amount, String currency) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${amount.toStringAsFixed(0)} $currency',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1664FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _systemRow(String label, String value) {
    return Row(
      children: [
        const Icon(Icons.calendar_today_outlined,
            size: 16, color: Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$label $value',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _typeChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(text, style: const TextStyle()),
    );
  }

  Widget _statusChip(String displayStatus) {
    final normalized = displayStatus.toLowerCase();

    Color bg;
    Color fg;
    if (normalized.contains('disponible')) {
      bg = const Color(0xFFE7F8ED);
      fg = const Color(0xFF16A34A);
    } else if (normalized.contains('occup')) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFF59E0B);
    } else {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Future<void> _onEdit() async {
    final result = await Get.to(() => CreateSpaceView(space: _space));
    if (result == true) {
      final controller = Get.find<SpaceController>();
      final refreshed = controller.findByDocumentId(_space.documentId);
      if (refreshed != null && mounted) {
        setState(() => _space = refreshed);
      }
    }
  }

  String _toDisplayStatus(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'available') return 'Disponible';
    if (normalized == 'occupied') return 'Occupé';
    if (normalized == 'maintenance') return 'Maintenance';
    return value;
  }

  String _displayCurrency(String value) {
    final v = value.trim();
    if (v.toUpperCase() == 'TND') return 'DT';
    return v.isEmpty ? 'DT' : v;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final d = date.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
