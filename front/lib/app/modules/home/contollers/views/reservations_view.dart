import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/reservations_controller.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'custom_sidebar.dart';
import 'dashboard_topbar.dart';

class ReservationsView extends GetView<ReservationsController> {
  const ReservationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: GetBuilder<ReservationsController>(
        builder: (_) {
          return LayoutBuilder(builder: (context, constraints) {
            return Row(children: [
              if (constraints.maxWidth >= 1080) const CustomSidebar(),
              Expanded(
                child: Column(children: [
                  const DashboardTopBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 20),
                          _buildOverviewCards(),
                          const SizedBox(height: 18),
                          _buildSearchAndFilter(),
                          const SizedBox(height: 16),
                          _buildTable(),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ]);
          });
        },
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFF0FDF4)],
        ),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Gestion des réservations',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Réservations',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Gérez toutes les réservations d'espaces avec une vue claire sur les statuts, paiements et actions rapides.",
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Container(
            width: 140,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calendar_month_outlined,
                    color: Color(0xFF22C55E), size: 28),
                SizedBox(height: 10),
                Text(
                  'Suivi temps réel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Statuts, paiements et actions',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 760;
      final total = controller.totalCount.toString();
      final confirmed = controller.confirmedCount.toString();
      final pending = controller.pendingCount.toString();

      if (isCompact) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: _StatCard(
                title: 'Total',
                value: total,
                icon: Icons.event_note_outlined,
                iconColor: const Color(0xFF0B6BFF),
                iconBackground: const Color(0xFFDBEAFE),
              ),
            ),
            SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: _StatCard(
                title: 'Confirmées',
                value: confirmed,
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBackground: const Color(0xFFDCFCE7),
              ),
            ),
            SizedBox(
              width: constraints.maxWidth,
              child: _StatCard(
                title: 'En attente',
                value: pending,
                icon: Icons.hourglass_top_outlined,
                iconColor: const Color(0xFFB45309),
                iconBackground: const Color(0xFFFEF3C7),
              ),
            ),
          ],
        );
      }

      return Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatCard(
                title: 'Total',
                value: total,
                icon: Icons.event_note_outlined,
                iconColor: const Color(0xFF0B6BFF),
                iconBackground: const Color(0xFFDBEAFE),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _StatCard(
                title: 'Confirmées',
                value: confirmed,
                icon: Icons.verified_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBackground: const Color(0xFFDCFCE7),
              ),
            ),
          ),
          Expanded(
            child: _StatCard(
              title: 'En attente',
              value: pending,
              icon: Icons.hourglass_top_outlined,
              iconColor: const Color(0xFFB45309),
              iconBackground: const Color(0xFFFEF3C7),
            ),
          ),
        ],
      );
    });
  }

  // ── Search + Filter ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: isCompact
                  ? constraints.maxWidth
                  : constraints.maxWidth * 0.72,
              child: TextField(
                onChanged: controller.setSearchQuery,
                decoration: InputDecoration(
                  hintText: 'Rechercher par espace ou utilisateur...',
                  hintStyle:
                      const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF94A3B8), size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF22C55E))),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedStatus.value,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF64748B)),
                  style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600),
                  items: ['Tous', 'En attente', 'Confirmé', 'Annulé']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.changeStatusFilter(v);
                  },
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.filter_alt_outlined,
                      size: 16, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Text(
                    '${controller.reservations.length} résultats',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF166534),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  // ── Table ─────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    if (controller.isLoading.value && controller.reservations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    if (controller.reservations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 54),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 42, color: Color(0xFF94A3B8)),
            SizedBox(height: 12),
            Text(
              'Aucune réservation trouvée',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Essayez un autre filtre ou une autre recherche.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: [
        _buildTableHeader(),
        ...controller.reservations.map((r) => _buildTableRow(r)),
      ]),
    );
  }

  // ── Table Header ──────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18)),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(children: const [
        Expanded(flex: 3, child: _HeaderCell('Espace')),
        Expanded(flex: 4, child: _HeaderCell('Utilisateur')),
        Expanded(flex: 3, child: _HeaderCell('Date & Heure')),
        Expanded(flex: 2, child: _HeaderCell('Montant')),
        Expanded(flex: 2, child: _HeaderCell('Statut')),
        Expanded(flex: 2, child: _HeaderCell('Paiement')),
        SizedBox(width: 100, child: _HeaderCell('Actions')),
      ]),
    );
  }

  // ── Table Row ─────────────────────────────────────────────────────────────
  Widget _buildTableRow(ReservationModel r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Espace
        Expanded(
          flex: 3,
          child: Text(
            r.spaceName,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF0F172A)),
          ),
        ),

        // Utilisateur avec avatar
        Expanded(
          flex: 4,
          child: Row(children: [
            _buildAvatar(r.userName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(r.userName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFF0F172A))),
                      const SizedBox(width: 6),
                      _buildRoleBadge(r),
                    ]),
                    if (r.userEmail.isNotEmpty)
                      Text(r.userEmail,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                    if (r.userPhone.isNotEmpty)
                      Text(r.userPhone,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF94A3B8))),
                  ]),
            ),
          ]),
        ),

        // Date & Heure
        Expanded(
          flex: 3,
          child: Text(
            _formatDateTimeRange(r.dateTime, r.endDateTime),
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF475569),
                fontWeight: FontWeight.w500),
          ),
        ),

        // Montant
        Expanded(
          flex: 2,
          child: Text('${r.amount.toStringAsFixed(0)} DT',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF0F172A))),
        ),

        // Statut
        Expanded(flex: 2, child: _buildStatusBadge(r.status)),

        // Paiement
        Expanded(
          flex: 2,
          child: _buildPaymentBadge(r.paymentMethod),
        ),

        // Actions
        SizedBox(
          width: 100,
          child: Row(children: [
            // Confirmer
            _ActionBtn(
              icon: Icons.check,
              color: const Color(0xFF16A34A),
              bg: const Color(0xFFDCFCE7),
              onTap: () => controller.updateStatus(r.documentId, 'confirmé'),
            ),
            const SizedBox(width: 6),
            // Modifier
            _ActionBtn(
              icon: Icons.edit_outlined,
              color: const Color(0xFF0B6BFF),
              bg: const Color(0xFFDBEAFE),
              onTap: () {},
            ),
            const SizedBox(width: 6),
            // Supprimer
            _ActionBtn(
              icon: Icons.delete_outline,
              color: const Color(0xFFDC2626),
              bg: const Color(0xFFFEE2E2),
              onTap: () => controller.deleteReservation(r.documentId),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Avatar ────────────────────────────────────────────────────────────────
  Widget _buildAvatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final colors = [
      const Color(0xFF6366F1),
      const Color(0xFF22C55E),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF0B6BFF),
      const Color(0xFFEC4899),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.82)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }

  // ── Role Badge ────────────────────────────────────────────────────────────
  Widget _buildRoleBadge(ReservationModel r) {
    final role = r.userRole;
    Color bg, text;
    if (role.toLowerCase().contains('visiteur') ||
        role.toLowerCase().contains('guest')) {
      bg = const Color(0xFFF1F5F9);
      text = const Color(0xFF64748B);
    } else {
      bg = const Color(0xFFDBEAFE);
      text = const Color(0xFF0B6BFF);
    }
    final label = role.isNotEmpty ? role : 'Client';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: text)),
    );
  }

  // ── Status Badge ──────────────────────────────────────────────────────────
  Widget _buildStatusBadge(String status) {
    final s = status.toLowerCase().replaceAll('_', ' ').trim();
    Color bg, text;
    String label;
    if (s.contains('confirm')) {
      bg = const Color(0xFFDCFCE7);
      text = const Color(0xFF16A34A);
      label = 'CONFIRMÉ';
    } else if (s.contains('annul')) {
      bg = const Color(0xFFFEE2E2);
      text = const Color(0xFFDC2626);
      label = 'ANNULÉ';
    } else {
      bg = const Color(0xFFFEF3C7);
      text = const Color(0xFFB45309);
      label = 'EN ATTENTE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: text.withOpacity(0.14))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            s.contains('confirm')
                ? Icons.verified_rounded
                : s.contains('annul')
                    ? Icons.cancel_rounded
                    : Icons.schedule_rounded,
            size: 12,
            color: text,
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: text,
                  letterSpacing: 0.2)),
        ],
      ),
    );
  }

  Widget _buildPaymentBadge(String paymentMethod) {
    final value = paymentMethod.trim();
    if (value.isEmpty || value == '-') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          '-',
          style: TextStyle(
              fontSize: 12,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF166534),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatDateTimeRange(DateTime start, DateTime? end) {
    final date = DateFormat('dd MMM yyyy', 'fr').format(start);
    final startHour = DateFormat('HH:mm').format(start);
    if (end == null) {
      return '$date • $startHour';
    }
    final endHour = DateFormat('HH:mm').format(end);
    return '$date • $startHour - $endHour';
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: Color(0xFF475569)));
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }
}
