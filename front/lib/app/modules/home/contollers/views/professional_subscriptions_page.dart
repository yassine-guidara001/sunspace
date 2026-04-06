import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class ProfessionalSubscriptionsPage extends StatefulWidget {
  const ProfessionalSubscriptionsPage({super.key});

  @override
  State<ProfessionalSubscriptionsPage> createState() =>
      _ProfessionalSubscriptionsPageState();
}

class _ProfessionalSubscriptionsPageState
    extends State<ProfessionalSubscriptionsPage> {
  bool _annualBilling = false;
  String? _activePlanName;
  int? _activePlanAmount;
  String? _activePlanPeriodLabel;
  IconData? _activePlanIcon;
  Color? _activePlanAccent;
  String? _topNoticeTitle;
  String? _topNoticeMessage;
  IconData _topNoticeIcon = Icons.check_circle_rounded;
  Color _topNoticeIconColor = const Color(0xFF16A34A);
  Timer? _topNoticeTimer;

  void _showTopNotice({
    required String title,
    String? message,
    IconData icon = Icons.check_circle_rounded,
    Color iconColor = const Color(0xFF16A34A),
  }) {
    _topNoticeTimer?.cancel();
    setState(() {
      _topNoticeTitle = title;
      _topNoticeMessage = message;
      _topNoticeIcon = icon;
      _topNoticeIconColor = iconColor;
    });

    _topNoticeTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _topNoticeTitle = null;
        _topNoticeMessage = null;
      });
    });
  }

  @override
  void dispose() {
    _topNoticeTimer?.cancel();
    super.dispose();
  }

  Future<void> _openCheckoutDialog({
    required String planName,
    required int monthlyPrice,
    required IconData planIcon,
    required Color accent,
  }) async {
    final amount =
        _annualBilling ? ((monthlyPrice * 12 * 0.83).round()) : monthlyPrice;
    final periodLabel = _annualBilling ? 'an' : 'mois';
    final billingLabel =
        _annualBilling ? 'Facturation annuelle' : 'Facturation mensuelle';

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer le paiement',
      barrierColor: const Color(0x800F172A),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return _SubscriptionCheckoutDialog(
          planName: planName,
          amount: amount,
          periodLabel: periodLabel,
          billingLabel: billingLabel,
          accent: accent,
          planIcon: planIcon,
          onClose: () => Navigator.of(dialogContext).pop(),
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            if (!mounted) return;
            setState(() {
              _activePlanName = planName;
              _activePlanAmount = amount;
              _activePlanPeriodLabel = periodLabel;
              _activePlanIcon = planIcon;
              _activePlanAccent = accent;
            });
            _showTopNotice(
              title: 'Abonnement $planName active !',
              message: 'Bienvenue ! Votre espace professionnel est pret.',
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFFF59E0B),
            );
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth > 980 ? 980.0 : constraints.maxWidth;
          final starterActive = _activePlanName == 'Starter';
          final businessActive = _activePlanName == 'Business';
          final premiumActive = _activePlanName == 'Premium';
          final columns = contentWidth >= 760
              ? 3
              : contentWidth >= 520
                  ? 2
                  : 1;
          final cardWidth = (contentWidth - ((columns - 1) * 18)) / columns;
          final cardHeight = columns == 3 ? 590.0 : 560.0;

          return Stack(
            children: [
              SingleChildScrollView(
                primary: true,
                child: Column(
                  children: [
                    _buildHero(),
                    const SizedBox(height: 22),
                    if (_activePlanName != null) ...[
                      _buildActiveSubscriptionBanner(contentWidth),
                      const SizedBox(height: 18),
                    ],
                    SizedBox(
                      width: contentWidth,
                      child: Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        alignment: WrapAlignment.center,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _PlanCard(
                              name: 'Starter',
                              subtitle:
                                  'Ideal pour les freelances et independants',
                              monthlyPrice: 49,
                              cardHeight: cardHeight,
                              annualBilling: _annualBilling,
                              icon: Icons.bolt,
                              iconColor: const Color(0xFF3B82F6),
                              headerTint: const Color(0xFFF8FAFC),
                              borderColor: starterActive
                                  ? const Color(0xFF1D77FF)
                                  : const Color(0xFFE2E8F0),
                              highlighted: starterActive,
                              isActive: starterActive,
                              buttonLabel: starterActive
                                  ? 'Abonnement actif'
                                  : 'Choisir Starter',
                              buttonPrimary: false,
                              features: const [
                                '5 jours/mois d\'acces coworking',
                                '2 heures de salle de reunion',
                                'Acces Wi-Fi haut debit',
                                'Espace cafe inclus',
                                'Adresse postale professionnelle',
                              ],
                              bonus: const ['Support par email'],
                              accent: const Color(0xFF3B82F6),
                              onSelect: () => _openCheckoutDialog(
                                planName: 'Starter',
                                monthlyPrice: 49,
                                planIcon: Icons.bolt,
                                accent: const Color(0xFF3B82F6),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _PlanCard(
                              name: 'Business',
                              subtitle: 'Ideal pour les professionnels actifs',
                              monthlyPrice: 129,
                              cardHeight: cardHeight,
                              annualBilling: _annualBilling,
                              icon: Icons.business_center_rounded,
                              iconColor: const Color(0xFF2563EB),
                              headerTint: const Color(0xFFF5F9FF),
                              borderColor: businessActive
                                  ? const Color(0xFF1D77FF)
                                  : const Color(0xFF93C5FD),
                              highlighted: true,
                              isActive: businessActive,
                              badgeText: 'Populaire',
                              buttonLabel: businessActive
                                  ? 'Abonnement actif'
                                  : 'Choisir Business',
                              buttonPrimary: true,
                              features: const [
                                'Acces illimite coworking',
                                '10 heures de salle de reunion',
                                'Acces Wi-Fi haut debit',
                                'Cafe & boissons illimites',
                                'Adresse postale professionnelle',
                                'Casier personnel securise',
                                'Impression (100 pages/mois)',
                              ],
                              bonus: const [
                                'Support prioritaire',
                                'Acces formations continues',
                              ],
                              accent: const Color(0xFF2563EB),
                              onSelect: () => _openCheckoutDialog(
                                planName: 'Business',
                                monthlyPrice: 129,
                                planIcon: Icons.business_center_rounded,
                                accent: const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _PlanCard(
                              name: 'Premium',
                              subtitle: 'L\'experience coworking complete',
                              monthlyPrice: 249,
                              cardHeight: cardHeight,
                              annualBilling: _annualBilling,
                              icon: Icons.workspace_premium_outlined,
                              iconColor: const Color(0xFFF59E0B),
                              headerTint: const Color(0xFFFFF7ED),
                              borderColor: premiumActive
                                  ? const Color(0xFF1D77FF)
                                  : const Color(0xFFE2E8F0),
                              highlighted: premiumActive,
                              isActive: premiumActive,
                              badgeText: 'Meilleure valeur',
                              badgeColor: const Color(0xFFF59E0B),
                              buttonLabel: premiumActive
                                  ? 'Abonnement actif'
                                  : 'Choisir Premium',
                              buttonPrimary: false,
                              features: const [
                                'Acces illimite 24h/24 7j/7',
                                'Salles de reunion illimitees',
                                'Wi-Fi fibre dediee',
                                'Cafe, the & snacks illimites',
                                'Adresse postale + domiciliation',
                                'Bureau prive dedie',
                                'Impression illimitee',
                                'Acces a tous les equipements',
                              ],
                              bonus: const [
                                'Support VIP dedie',
                                'Acces formations continues',
                                'Invites gratuits (2/mois)',
                                'Parking inclus',
                              ],
                              accent: const Color(0xFFF59E0B),
                              onSelect: () => _openCheckoutDialog(
                                planName: 'Premium',
                                monthlyPrice: 249,
                                planIcon: Icons.workspace_premium_outlined,
                                accent: const Color(0xFFF59E0B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _GuaranteeItem(label: 'Paiement 100% securise'),
                        _GuaranteeItem(label: 'Sans engagement'),
                        _GuaranteeItem(label: 'Annulation a tout moment'),
                        _GuaranteeItem(label: 'Facture mensuelle automatique'),
                      ],
                    ),
                  ],
                ),
              ),
              _buildTopNotice(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopNotice() {
    final isVisible = _topNoticeTitle != null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: !isVisible
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey('${_topNoticeTitle}_${_topNoticeMessage}'),
                    constraints: const BoxConstraints(maxWidth: 420),
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE7F8EE),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFB7E7CB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            _topNoticeIcon,
                            size: 14,
                            color: _topNoticeIconColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _topNoticeTitle!,
                                style: const TextStyle(
                                  color: Color(0xFF047857),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                              ),
                              if (_topNoticeMessage != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  _topNoticeMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF166534),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSubscriptionBanner(double contentWidth) {
    final planName = _activePlanName ?? '';
    final amount = _activePlanAmount ?? 0;
    final period = _activePlanPeriodLabel ?? 'mois';
    final planIcon = _activePlanIcon ?? Icons.bolt;
    final accent = _activePlanAccent ?? const Color(0xFF1D77FF);

    return SizedBox(
      width: contentWidth,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEBFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFA3C8FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(planIcon, color: accent, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                      children: [
                        const TextSpan(text: 'Abonnement actif : '),
                        TextSpan(
                          text: planName,
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$amount DT / $period - Renouvellement automatique',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _activePlanName = null;
                  _activePlanAmount = null;
                  _activePlanPeriodLabel = null;
                  _activePlanIcon = null;
                  _activePlanAccent = null;
                });
                _showTopNotice(title: 'Abonnement annule');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                backgroundColor: Colors.white,
                minimumSize: const Size(94, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text(
                  'Abonnements Professionnels',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choisissez votre espace de travail',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 48,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Des formules flexibles adaptees a votre activite. Changez ou annulez a tout\nmoment.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _buildBillingToggle(),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Mensuel',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () {
            setState(() {
              _annualBilling = !_annualBilling;
            });
          },
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: 36,
            height: 20,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: _annualBilling
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment:
                _annualBilling ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Annuel',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            '-17%',
            style: TextStyle(
              color: Color(0xFF16A34A),
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final int monthlyPrice;
  final double cardHeight;
  final bool annualBilling;
  final IconData icon;
  final Color iconColor;
  final Color headerTint;
  final Color borderColor;
  final bool highlighted;
  final bool isActive;
  final String? badgeText;
  final Color? badgeColor;
  final String buttonLabel;
  final bool buttonPrimary;
  final List<String> features;
  final List<String> bonus;
  final Color accent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.name,
    required this.subtitle,
    required this.monthlyPrice,
    required this.cardHeight,
    required this.annualBilling,
    required this.icon,
    required this.iconColor,
    required this.headerTint,
    required this.borderColor,
    required this.highlighted,
    required this.isActive,
    this.badgeText,
    this.badgeColor,
    required this.buttonLabel,
    required this.buttonPrimary,
    required this.features,
    required this.bonus,
    required this.accent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final displayedPrice =
        annualBilling ? ((monthlyPrice * 12 * 0.83).round()) : monthlyPrice;
    final effectiveBadgeText = isActive ? 'Actif' : badgeText;
    final effectiveBadgeColor = isActive
        ? const Color(0xFF22C55E)
        : badgeColor ?? const Color(0xFF0B6BFF);
    final buttonBackground = isActive
        ? const Color(0xFF6AD39B)
        : buttonPrimary
            ? const Color(0xFF0B6BFF)
            : const Color(0xFFE5E7EB);
    final buttonForeground = isActive
        ? Colors.white
        : buttonPrimary
            ? Colors.white
            : const Color(0xFF111827);

    return Container(
      constraints: BoxConstraints.tightFor(height: cardHeight),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: highlighted ? 1.4 : 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: headerTint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          height: 0.95,
                        ),
                      ),
                    ),
                    if (effectiveBadgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: effectiveBadgeColor,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          effectiveBadgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 9.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$displayedPrice',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontWeight: FontWeight.w900,
                        fontSize: 40,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'DT / ${annualBilling ? 'an' : 'mois'}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  ...features.map(
                    (item) => _FeatureRow(
                      text: item,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 6),
                  ...bonus.map(
                    (item) => _FeatureRow(
                      text: item,
                      color: accent,
                      bonus: true,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isActive) return;
                        onSelect();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonBackground,
                        foregroundColor: buttonForeground,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isActive) ...[
                            const Icon(Icons.check, size: 14),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCheckoutDialog extends StatefulWidget {
  const _SubscriptionCheckoutDialog({
    required this.planName,
    required this.amount,
    required this.periodLabel,
    required this.billingLabel,
    required this.accent,
    required this.planIcon,
    required this.onClose,
    required this.onConfirm,
  });

  final String planName;
  final int amount;
  final String periodLabel;
  final String billingLabel;
  final Color accent;
  final IconData planIcon;
  final VoidCallback onClose;
  final VoidCallback onConfirm;

  @override
  State<_SubscriptionCheckoutDialog> createState() =>
      _SubscriptionCheckoutDialogState();
}

class _SubscriptionCheckoutDialogState
    extends State<_SubscriptionCheckoutDialog> {
  late final TextEditingController _cardNameController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _expiryController;
  late final TextEditingController _cvcController;

  @override
  void initState() {
    super.initState();
    _cardNameController = TextEditingController();
    _cardNumberController = TextEditingController();
    _expiryController = TextEditingController();
    _cvcController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width;
    final dialogWidth =
        maxWidth < 540 ? (maxWidth - 22).clamp(300.0, 500.0).toDouble() : 500.0;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 22),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: dialogWidth,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D0F172A),
                    blurRadius: 28,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Confirmer l\'abonnement',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Plan '),
                                    TextSpan(
                                      text: widget.planName,
                                      style: TextStyle(
                                        color: widget.accent,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text:
                                          ' - ${widget.amount} DT /${widget.periodLabel}',
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          children: [
                            InkWell(
                              onTap: widget.onClose,
                              borderRadius: BorderRadius.circular(999),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.close,
                                    size: 16, color: Color(0xFF64748B)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF2FF),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.shield_outlined,
                                color: Color(0xFF60A5FA),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Icon(widget.planIcon,
                                    size: 14, color: widget.accent),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.planName,
                                      style: const TextStyle(
                                        color: Color(0xFF111827),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      widget.billingLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF9CA3AF),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${widget.amount} DT',
                                style: TextStyle(
                                  color: widget.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 30,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _checkoutField(
                          label: 'NOM SUR LA CARTE',
                          hint: 'Jean Dupont',
                          controller: _cardNameController,
                        ),
                        const SizedBox(height: 8),
                        _checkoutField(
                          label: 'NUMERO DE CARTE',
                          hint: '0000 0000 0000 0000',
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          inputFormatters: const [
                            _CardNumberInputFormatter(),
                          ],
                          prefix: const Icon(Icons.credit_card,
                              size: 15, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _checkoutField(
                                label: 'EXPIRATION',
                                hint: 'MM/AA',
                                controller: _expiryController,
                                keyboardType: TextInputType.number,
                                inputFormatters: const [
                                  _ExpiryDateInputFormatter(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _checkoutField(
                                label: 'CVC',
                                hint: '...',
                                controller: _cvcController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Visa',
                                  style: TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 22,
                                height: 12,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 0,
                                      child: const CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Color(0xFFF97316),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: const CircleAvatar(
                                        radius: 6,
                                        backgroundColor: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'SSL 256 BITS',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: widget.onClose,
                            child: const Text(
                              'Annuler',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 3,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: widget.onConfirm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF76A9F0),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(11),
                                ),
                              ),
                              child: Text(
                                'Payer ${widget.amount} DT',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _checkoutField({
    required String label,
    required String hint,
    required TextEditingController controller,
    Widget? prefix,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFAFBFD),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (prefix != null) ...[
                prefix,
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  obscureText: obscureText,
                  obscuringCharacter: '.',
                  inputFormatters: inputFormatters,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  const _CardNumberInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated =
        digitsOnly.length > 16 ? digitsOnly.substring(0, 16) : digitsOnly;

    final buffer = StringBuffer();
    for (var i = 0; i < truncated.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(truncated[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateInputFormatter extends TextInputFormatter {
  const _ExpiryDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final truncated =
        digitsOnly.length > 4 ? digitsOnly.substring(0, 4) : digitsOnly;

    var formatted = truncated;
    if (truncated.length > 2) {
      formatted = '${truncated.substring(0, 2)}/${truncated.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  final Color color;
  final bool bonus;

  const _FeatureRow({
    required this.text,
    required this.color,
    this.bonus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            bonus ? Icons.star_border_rounded : Icons.check_rounded,
            size: bonus ? 13 : 14,
            color: bonus ? color.withValues(alpha: 0.92) : color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color:
                    bonus ? const Color(0xFF64748B) : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: bonus ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuaranteeItem extends StatelessWidget {
  final String label;

  const _GuaranteeItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check, size: 15, color: Color(0xFF22C55E)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
