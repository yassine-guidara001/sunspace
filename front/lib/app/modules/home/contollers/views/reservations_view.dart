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
      body: LayoutBuilder(builder: (context, constraints) {
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
      }),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Réservations',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                color: Color(0xFF0F172A))),
        SizedBox(height: 4),
        Text("Gérez toutes les réservations d'espaces",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
      ],
    );
  }

  // ── Search + Filter ───────────────────────────────────────────────────────
  Widget _buildSearchAndFilter() {
    return Row(children: [
      Expanded(
        child: TextField(
          onChanged: controller.setSearchQuery,
          decoration: InputDecoration(
            hintText: 'Rechercher par espace ou utilisateur...',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 18),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF22C55E))),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Filtre statut
      Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButton<String>(
              value: controller.selectedStatus.value,
              underline: const SizedBox(),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF64748B)),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF1E293B)),
              items: ['Tous', 'En attente', 'Confirmé', 'Annulé']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) {
                if (v != null) controller.changeStatusFilter(v);
              },
            ),
          )),
    ]);
  }

  // ── Table ─────────────────────────────────────────────────────────────────
  Widget _buildTable() {
    return Obx(() {
      if (controller.isLoading.value && controller.reservations.isEmpty) {
        return const Center(
            child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF22C55E))));
      }

      if (controller.reservations.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(48),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Center(
              child: Text('Aucune réservation trouvée',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14))),
        );
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(children: [
          _buildTableHeader(),
          ...controller.reservations.map((r) => _buildTableRow(r)),
        ]),
      );
    });
  }

  // ── Table Header ──────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Espace
        Expanded(
          flex: 3,
          child: Text(r.spaceName,
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF0F172A))),
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
            DateFormat('dd MMM yyyy  HH:mm', 'fr').format(r.dateTime),
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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
          child: Text(
            r.paymentMethod.isNotEmpty ? r.paymentMethod : '-',
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
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
      const Color(0xFF6366F1), const Color(0xFF22C55E),
      const Color(0xFFF59E0B), const Color(0xFFEF4444),
      const Color(0xFF0B6BFF), const Color(0xFFEC4899),
    ];
    final color = colors[name.hashCode.abs() % colors.length];
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(4)),
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
      bg = const Color(0xFFDCFCE7); text = const Color(0xFF16A34A);
      label = 'CONFIRMÉ';
    } else if (s.contains('annul')) {
      bg = const Color(0xFFFEE2E2); text = const Color(0xFFDC2626);
      label = 'ANNULÉ';
    } else {
      bg = const Color(0xFFFEF3C7); text = const Color(0xFFB45309);
      label = 'EN ATTENTE';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: text)),
    );
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