import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/association_budget_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AssociationBudgetUsageView extends GetView<AssociationBudgetController> {
  const AssociationBudgetUsageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDCE5F1),
      body: LayoutBuilder(builder: (context, constraints) {
        return Row(children: [
          if (constraints.maxWidth >= 1080) const CustomSidebar(),
          Expanded(
            child: Column(children: [
              const DashboardTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 26),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1180),
                      child: Obx(() => _BudgetLayout(
                            isLoading: controller.isLoading.value,
                            errorMessage: controller.errorMessage.value,
                            currentBalance: controller.totalBalance,
                            currency: controller.currency,
                            assocDocId: controller.userAssociations.isNotEmpty
                                ? controller.userAssociations.first.documentId
                                : '',
                            headers: Get.find<AuthService>().authHeaders,
                          )),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ]);
      }),
    );
  }
}

class _BudgetLayout extends StatefulWidget {
  const _BudgetLayout({
    required this.isLoading,
    required this.errorMessage,
    required this.currentBalance,
    required this.currency,
    required this.assocDocId,
    required this.headers,
  });

  final bool isLoading;
  final String errorMessage;
  final double currentBalance;
  final String currency;
  final String assocDocId;
  final Map<String, String> headers;

  @override
  State<_BudgetLayout> createState() => _BudgetLayoutState();
}

class _BudgetLayoutState extends State<_BudgetLayout> {
  static const double _maxHours = 200;
  final List<Map<String, dynamic>> _journal = [];
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;
  }

  @override
  void didUpdateWidget(_BudgetLayout old) {
    super.didUpdateWidget(old);
    if (old.currentBalance != widget.currentBalance) {
      setState(() => _balance = widget.currentBalance);
    }
  }

  void _onTransactionSuccess(double newBalance, Map<String, dynamic> tx) {
    setState(() {
      _balance = newBalance;
      _journal.insert(0, tx);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(tx['amount'] > 0 ? 'Solde rechargé !' : 'Retrait effectué !'),
      backgroundColor: const Color(0xFF22C55E),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        if (widget.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ErrorBanner(message: widget.errorMessage),
        ],
        const SizedBox(height: 18),
        _buildTopCards(),
        const SizedBox(height: 22),
        _buildBottomPanels(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 900;

    const titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('BUDGET & UTILISATION',
            style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF020617),
                height: 0.95,
                letterSpacing: -0.9)),
        SizedBox(height: 8),
        Text(
          'Gérez vos fonds et suivez la consommation d\'heures de votre association.',
          style: TextStyle(
              color: Color(0xFF556176),
              fontSize: 20,
              fontWeight: FontWeight.w500),
        ),
      ],
    );

    final actionButton = ElevatedButton.icon(
      onPressed: () => showDialog(
        context: context,
        barrierColor: Colors.black38,
        builder: (_) => _AjusterSoldeDialog(
          assocDocId: widget.assocDocId,
          currentBalance: _balance,
          currency: widget.currency,
          headers: widget.headers,
          onSuccess: _onTransactionSuccess,
        ),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('AJUSTER LE SOLDE'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B6BFF),
        foregroundColor: Colors.white,
        elevation: 6,
        shadowColor: const Color(0x3A0B6BFF),
        padding:
            EdgeInsets.symmetric(horizontal: isNarrow ? 14 : 18, vertical: 12),
        textStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );

    if (isNarrow) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        titleBlock,
        const SizedBox(height: 14),
        actionButton,
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Expanded(child: titleBlock),
      const SizedBox(width: 12),
      actionButton,
    ]);
  }

  Widget _buildTopCards() {
    return LayoutBuilder(builder: (context, constraints) {
      final isStacked = constraints.maxWidth < 1080;
      final cardOne = _MetricCard(
        label: 'SOLDE ACTUEL',
        value: '${_formatMoney(_balance)} ${widget.currency}',
        subtitle: 'Fonds disponibles pour vos réservations',
        icon: Icons.account_balance_wallet_outlined,
        iconColor: const Color(0xFF0B6BFF),
        iconBackground: const Color(0xFFE7F0FF),
        shapeBackground: const Color(0xFFDDE8F9),
        isLoading: widget.isLoading,
      );
      final cardTwo = _MetricCard(
        label: 'CONSOMMATION',
        value: '0h',
        valueTail: '/${_maxHours.toStringAsFixed(0)}h',
        icon: Icons.schedule_outlined,
        iconColor: const Color(0xFF1E73FF),
        iconBackground: const Color(0xFFE8F0FF),
        shapeBackground: const Color(0xFFDCE8FA),
        progress: 0,
        isLoading: widget.isLoading,
      );
      final cardThree = _MetricCard(
        label: 'ECONOMIES',
        value: '0,000 ${widget.currency}',
        subtitle: 'Grâce aux tarifs préférentiels Sunspace',
        icon: Icons.bar_chart_rounded,
        iconColor: const Color(0xFF16A34A),
        iconBackground: const Color(0xFFDDF7E8),
        shapeBackground: const Color(0xFFD8F0E1),
        isLoading: widget.isLoading,
      );

      if (isStacked) {
        return Column(children: [
          cardOne,
          const SizedBox(height: 12),
          cardTwo,
          const SizedBox(height: 12),
          cardThree,
        ]);
      }
      return Row(children: [
        Expanded(child: cardOne),
        const SizedBox(width: 14),
        Expanded(child: cardTwo),
        const SizedBox(width: 14),
        Expanded(child: cardThree),
      ]);
    });
  }

  Widget _buildBottomPanels(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final stacked = constraints.maxWidth < 1120;

      final monthly = _LargePanel(
        child: Column(children: const [
          _PanelHeader(
              title: 'ACTIVITÉ MENSUELLE', trailing: _PeriodDropdown()),
          SizedBox(height: 18),
          Expanded(child: _MonthlyPlaceholder()),
        ]),
      );

      final journal = _LargePanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _PanelHeader(
                title: 'JOURNAL FINANCIER', trailing: _SeeAllAction()),
            const SizedBox(height: 16),
            Expanded(
                child: _journal.isEmpty
                    ? const Center(
                        child: Text('Aucune transaction',
                            style: TextStyle(
                                color: Color(0xFF94A3B8), fontSize: 13)))
                    : ListView.separated(
                        itemCount: _journal.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (_, i) => _journalRow(_journal[i]),
                      )),
          ],
        ),
      );

      if (stacked) {
        return Column(children: [
          SizedBox(height: 370, child: monthly),
          const SizedBox(height: 14),
          SizedBox(height: 370, child: journal),
        ]);
      }
      return SizedBox(
        height: 370,
        child: Row(children: [
          Expanded(flex: 50, child: monthly),
          const SizedBox(width: 14),
          Expanded(flex: 50, child: journal),
        ]),
      );
    });
  }

  Widget _journalRow(Map<String, dynamic> tx) {
    final isRecharge = (tx['amount'] as double) > 0;
    final label = tx['label'] as String;
    final amount = (tx['amount'] as double).abs();
    final date = tx['date'] as DateTime;
    final dateStr =
        'ADMIN • ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color:
                isRecharge ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isRecharge ? Icons.arrow_downward : Icons.arrow_upward,
            size: 16,
            color:
                isRecharge ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF0F172A))),
            Text(dateStr,
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        )),
        Text(
          '${isRecharge ? '+' : '-'}${amount.toStringAsFixed(0)}\nTND',
          textAlign: TextAlign.right,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isRecharge
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
              height: 1.2),
        ),
      ]),
    );
  }

  static String _formatMoney(double value) =>
      value.toStringAsFixed(3).replaceAll('.', ',');
}

// ─── Dialog Ajuster le Solde ──────────────────────────────────────────────────
class _AjusterSoldeDialog extends StatefulWidget {
  const _AjusterSoldeDialog({
    required this.assocDocId,
    required this.currentBalance,
    required this.currency,
    required this.headers,
    required this.onSuccess,
  });

  final String assocDocId;
  final double currentBalance;
  final String currency;
  final Map<String, String> headers;
  final void Function(double newBalance, Map<String, dynamic> transaction)
      onSuccess;

  @override
  State<_AjusterSoldeDialog> createState() => _AjusterSoldeDialogState();
}

class _AjusterSoldeDialogState extends State<_AjusterSoldeDialog> {
  static const String _baseUrl = 'http://localhost:3001/api';

  bool _isAjouter = true;
  double _montant = 0.0;
  bool _isLoading = false;
  final _controller = TextEditingController(text: '0.00');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('GESTION DU SOLDE',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.3)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child:
                    const Icon(Icons.close, size: 18, color: Color(0xFF64748B)),
              ),
            ]),
            const SizedBox(height: 6),
            const Text('Modifiez le solde disponible pour l\'association.',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 18),

            // Toggle
            Container(
              height: 42,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Expanded(child: _toggleBtn('Ajouter (+)', true)),
                Expanded(child: _toggleBtn('Retirer (-)', false)),
              ]),
            ),
            const SizedBox(height: 18),

            // Montant
            const Text('MONTANT (TND)',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.5)),
            const SizedBox(height: 8),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A)),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (v) =>
                    setState(() => _montant = double.tryParse(v) ?? 0),
              ),
            ),
            const SizedBox(height: 14),

            // Raccourcis
            Row(children: [
              _quickBtn('10 TND', 10),
              const SizedBox(width: 8),
              _quickBtn('50 TND', 50),
              const SizedBox(width: 8),
              _quickBtn('100 TND', 100),
            ]),
            const SizedBox(height: 24),

            // Actions
            Row(children: [
              TextButton(
                onPressed:
                    _isLoading ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B)),
                child: const Text('Annuler',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (_montant > 0 && !_isLoading) ? _valider : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6BFF),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('VALIDER',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _toggleBtn(String label, bool isAjouter) {
    final selected = _isAjouter == isAjouter;
    return GestureDetector(
      onTap: () => setState(() => _isAjouter = isAjouter),
      child: Container(
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B6BFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : const Color(0xFF64748B))),
      ),
    );
  }

  Widget _quickBtn(String label, double amount) {
    final sel = _montant == amount;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _montant = amount;
          _controller.text = amount.toStringAsFixed(2);
        }),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFDBEAFE) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: sel ? const Color(0xFF0B6BFF) : const Color(0xFFE2E8F0)),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      sel ? const Color(0xFF0B6BFF) : const Color(0xFF475569))),
        ),
      ),
    );
  }

  Future<void> _valider() async {
    setState(() => _isLoading = true);
    try {
      final newBalance = _isAjouter
          ? widget.currentBalance + _montant
          : widget.currentBalance - _montant;

      // PUT /associations/{documentId}
      final uri = Uri.parse('$_baseUrl/associations/${widget.assocDocId}');
      final response = await http.put(
        uri,
        headers: widget.headers,
        body: jsonEncode({
          'data': {'budget': newBalance}
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final transaction = {
          'type': _isAjouter ? 'recharge' : 'retrait',
          'label': _isAjouter ? 'Recharge de compte' : 'Retrait de fonds',
          'amount': _isAjouter ? _montant : -_montant,
          'date': DateTime.now(),
        };
        if (mounted) {
          Navigator.of(context).pop();
          widget.onSuccess(newBalance, transaction);
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

// ─── Supporting widgets (inchangés) ──────────────────────────────────────────
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.shapeBackground,
    this.valueTail,
    this.subtitle,
    this.progress,
    required this.isLoading,
  });

  final String label;
  final String value;
  final String? valueTail;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color shapeBackground;
  final double? progress;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 188,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCFD8E5)),
      ),
      child: Stack(children: [
        Positioned(
          top: -26,
          right: -26,
          child: Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
                color: shapeBackground,
                borderRadius: BorderRadius.circular(999)),
          ),
        ),
        Positioned(
          right: 20,
          top: 20,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: iconBackground, borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, size: 19, color: iconColor),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Color(0xFF9AA4B2),
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 2.0)),
              const SizedBox(height: 28),
              isLoading
                  ? Container(
                      width: 150,
                      height: 22,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8EDF6),
                          borderRadius: BorderRadius.circular(8)))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(value,
                            style: const TextStyle(
                                color: Color(0xFF020617),
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -0.8)),
                        if (valueTail != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 5),
                            child: Text(valueTail!,
                                style: const TextStyle(
                                    color: Color(0xFFA1A8B3),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ],
                    ),
              const Spacer(),
              if (progress != null)
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: const Color(0xFFEBEEF4),
                      borderRadius: BorderRadius.circular(999)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0xFF0B6BFF),
                            borderRadius: BorderRadius.circular(999))),
                  ),
                )
              else
                Text(subtitle ?? '',
                    style: const TextStyle(
                        color: Color(0xFF9AA4B2),
                        fontStyle: FontStyle.italic,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _LargePanel extends StatelessWidget {
  const _LargePanel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFCFD8E5))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      child: child,
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, required this.trailing});
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFF020617),
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1,
                  letterSpacing: -0.7))),
      trailing,
    ]);
  }
}

class _PeriodDropdown extends StatefulWidget {
  const _PeriodDropdown();
  @override
  State<_PeriodDropdown> createState() => _PeriodDropdownState();
}

class _PeriodDropdownState extends State<_PeriodDropdown> {
  static const _options = ['DERNIERS 3 MOIS', 'ANNÉE 2026'];
  String _selected = 'ANNÉE 2026';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: _selected,
      onSelected: (v) => setState(() => _selected = v),
      offset: const Offset(0, 42),
      color: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      constraints: const BoxConstraints(minWidth: 190),
      itemBuilder: (_) => _options.map((o) {
        final sel = o == _selected;
        return PopupMenuItem<String>(
          value: o,
          padding: EdgeInsets.zero,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
                color: sel ? const Color(0xFF0B6BFF) : Colors.transparent,
                borderRadius: BorderRadius.circular(6)),
            child: Text(o,
                style: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF020617),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.9)),
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFFF1F3F7),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDCE0E8))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(_selected,
              style: const TextStyle(
                  color: Color(0xFF020617),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: Color(0xFF020617)),
        ]),
      ),
    );
  }
}

class _SeeAllAction extends StatelessWidget {
  const _SeeAllAction();
  @override
  Widget build(BuildContext context) {
    return const Row(children: [
      Icon(Icons.filter_list_alt, size: 16, color: Color(0xFF111827)),
      SizedBox(width: 6),
      Text('Tout voir',
          style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    ]);
  }
}

class _MonthlyPlaceholder extends StatelessWidget {
  const _MonthlyPlaceholder();
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const Spacer(),
      Row(children: const [
        Expanded(
            child: Center(
                child: Text('JAN',
                    style: TextStyle(
                        color: Color(0xFFB0B8C3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)))),
        Expanded(
            child: Center(
                child: Text('FEV',
                    style: TextStyle(
                        color: Color(0xFFB0B8C3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)))),
        Expanded(
            child: Center(
                child: Text('MAR',
                    style: TextStyle(
                        color: Color(0xFFB0B8C3),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0)))),
      ]),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFCA5A5))),
      child: Row(children: [
        const Icon(Icons.error_outline, size: 18, color: Color(0xFFB91C1C)),
        const SizedBox(width: 8),
        Expanded(
            child: Text(message,
                style: const TextStyle(
                    color: Color(0xFF991B1B), fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
