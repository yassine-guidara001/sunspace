import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationStatus {
  cancelled,
  confirmed,
  info,
}

class NotificationViewData {
  const NotificationViewData({
    required this.title,
    required this.message,
    required this.timestampLabel,
    required this.status,
    this.reason,
  });

  final String title;
  final String message;
  final String? reason;
  final String timestampLabel;
  final NotificationStatus status;

  static List<NotificationViewData> mocked() {
    return const [
      NotificationViewData(
        title: 'Réservation annulée',
        message: 'Votre réservation de "espace12" a été annulée.',
        reason: 'Mise à jour de statut',
        timestampLabel: 'Il y a 15h',
        status: NotificationStatus.cancelled,
      ),
      NotificationViewData(
        title: 'Réservation confirmée',
        message:
            'Votre réservation de "espace12" du 21/04/2026 11:00:00 au 21/04/2026 16:00:00 a été confirmée.',
        timestampLabel: 'Il y a 1j',
        status: NotificationStatus.confirmed,
      ),
    ];
  }

  factory NotificationViewData.fromBackend(Map<String, dynamic> raw) {
    final title = (raw['title'] ?? '').toString();
    final body = (raw['body'] ?? '').toString();
    final reason = (raw['reason'] ?? '').toString();

    final normalized = '$title $body'.toLowerCase();
    final status = normalized.contains('annul')
        ? NotificationStatus.cancelled
        : normalized.contains('confirm')
            ? NotificationStatus.confirmed
            : NotificationStatus.info;

    final label = _timeAgoLabel(raw['timestamp']);

    return NotificationViewData(
      title: title.isEmpty ? 'Notification' : title,
      message: body.isEmpty ? 'Aucun détail disponible.' : body,
      reason: reason.isEmpty ? null : reason,
      timestampLabel: label,
      status: status,
    );
  }

  static String _timeAgoLabel(dynamic rawTimestamp) {
    if (rawTimestamp is! DateTime) return 'À l\'instant';

    final diff = DateTime.now().difference(rawTimestamp);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }
}

class PremiumNotificationsList extends StatelessWidget {
  const PremiumNotificationsList({
    super.key,
    required this.notifications,
    this.onViewAllTap,
    this.title = 'Notifications',
  });

  final List<NotificationViewData> notifications;
  final VoidCallback? onViewAllTap;
  final String title;

  @override
  Widget build(BuildContext context) {
    final items = notifications.isEmpty
        ? NotificationViewData.mocked()
        : notifications.take(6).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(
            items.length,
            (index) => Padding(
              padding:
                  EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 12),
              child: _AnimatedNotificationCard(
                index: index,
                item: items[index],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: _ViewAllLink(onTap: onViewAllTap),
          ),
        ],
      ),
    );
  }
}

class _AnimatedNotificationCard extends StatefulWidget {
  const _AnimatedNotificationCard({
    required this.index,
    required this.item,
  });

  final int index;
  final NotificationViewData item;

  @override
  State<_AnimatedNotificationCard> createState() =>
      _AnimatedNotificationCardState();
}

class _AnimatedNotificationCardState extends State<_AnimatedNotificationCard> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 70 * widget.index), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.06),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOut,
        child: _NotificationCard(item: widget.item),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationViewData item;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(item.status);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: palette.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: palette.border, width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: palette.iconSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  item.status == NotificationStatus.cancelled
                      ? Icons.cancel_outlined
                      : item.status == NotificationStatus.confirmed
                          ? Icons.check_circle_outline
                          : Icons.notifications_none_outlined,
                  color: palette.iconStrong,
                  size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  if (item.reason != null && item.reason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Raison : ${item.reason}',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    item.timestampLabel,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewAllLink extends StatefulWidget {
  const _ViewAllLink({this.onTap});

  final VoidCallback? onTap;

  @override
  State<_ViewAllLink> createState() => _ViewAllLinkState();
}

class _ViewAllLinkState extends State<_ViewAllLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
                width: 1.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Voir toutes les notifications',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Color(0xFF2563EB),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPalette {
  const _NotificationPalette({
    required this.background,
    required this.border,
    required this.iconSoft,
    required this.iconStrong,
    required this.shadow,
  });

  final Color background;
  final Color border;
  final Color iconSoft;
  final Color iconStrong;
  final Color shadow;
}

_NotificationPalette _paletteFor(NotificationStatus status) {
  switch (status) {
    case NotificationStatus.cancelled:
      return const _NotificationPalette(
        background: Color(0xFFFFFBF8),
        border: Color(0xFFFDD6C3),
        iconSoft: Color(0xFFFFEEE6),
        iconStrong: Color(0xFFEA580C),
        shadow: Color(0x14EA580C),
      );
    case NotificationStatus.confirmed:
      return const _NotificationPalette(
        background: Color(0xFFF7FCFA),
        border: Color(0xFFCDEEE1),
        iconSoft: Color(0xFFE8F8F1),
        iconStrong: Color(0xFF16A34A),
        shadow: Color(0x1416A34A),
      );
    case NotificationStatus.info:
      return const _NotificationPalette(
        background: Color(0xFFF8FAFF),
        border: Color(0xFFDCE6FF),
        iconSoft: Color(0xFFEDF2FF),
        iconStrong: Color(0xFF2563EB),
        shadow: Color(0x142563EB),
      );
  }
}

class NotificationsShowcaseExample extends StatelessWidget {
  const NotificationsShowcaseExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: PremiumNotificationsList(
              notifications: NotificationViewData.mocked(),
              onViewAllTap: () {},
            ),
          ),
        ),
      ),
    );
  }
}
