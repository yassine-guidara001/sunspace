import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/notifications_controller.dart';

class NotificationsPage extends GetView<NotificationsController> {
  const NotificationsPage({super.key});

  // Palette de couleurs raffinée (light theme)
  static const Color _bg = Color(0xFFF9FAFB);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _cardUnread = Color(0xFFFEFCE8); // très léger jaune crème
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _accent = Color(0xFF6366F1); // Indigo doux
  static const Color _success = Color(0xFF10B981);
  static const Color _error = Color(0xFFEF4444);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _info = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 420;

    return AppBar(
      toolbarHeight: 78,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      titleSpacing: 20,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ce qu’il faut savoir',
            style: GoogleFonts.inter(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w400,
              color: _textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        Obx(() {
          final unread = controller.unreadCount.value;
          if (unread == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: controller.markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: Text(
                compact ? 'Tout' : 'Tout marquer',
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: TextButton.styleFrom(
                foregroundColor: _accent,
                backgroundColor: _accent.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final notifications = controller.filteredNotifications;
      final unread = notifications.where((n) => n['read'] != true).length;
      final total = notifications.length;
      final read = total - unread;

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
            child: _buildHero(total: total, unread: unread, read: read),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
            child: _buildFilters(),
          ),
          Expanded(child: _buildNotificationList()),
        ],
      );
    });
  }

  Widget _buildHero({
    required int total,
    required int unread,
    required int read,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF), Color(0xFFF6F7FF)],
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
      child: LayoutBuilder(builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 860;
        final stats = [
          _NotificationStat(
            label: 'Total',
            value: total.toString(),
            icon: Icons.notifications_none_rounded,
            accent: _accent,
            tint: const Color(0xFFDCE6FF),
          ),
          _NotificationStat(
            label: 'Non lues',
            value: unread.toString(),
            icon: Icons.mark_email_unread_outlined,
            accent: _warning,
            tint: const Color(0xFFFEF3C7),
          ),
          _NotificationStat(
            label: 'Lues',
            value: read.toString(),
            icon: Icons.done_all_rounded,
            accent: _success,
            tint: const Color(0xFFDCFCE7),
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFDCE6FF)),
                        ),
                        child: const Text(
                          'Centre de notifications',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          fontSize: isCompact ? 24 : 30,
                          fontWeight: FontWeight.w800,
                          color: _textPrimary,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Suivez les réservations, les mises à jour et les messages importants dans un flux plus lisible et plus rapide à parcourir.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 150,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.bolt_rounded, color: _accent, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Flux en direct',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Mises à jour et réservations récentes',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: _textSecondary,
                              height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: stats
                  .map((stat) => SizedBox(
                        width: isCompact
                            ? (constraints.maxWidth - 12) / 2
                            : (constraints.maxWidth - 24) / 3,
                        child: stat,
                      ))
                  .toList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilters() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 640;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      const Icon(Icons.tune_rounded, color: _accent, size: 17),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtrer le flux',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${controller.filteredNotifications.length} éléments',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FilterChips(
              controller: controller,
              onFilterChanged: controller.toggleFilter,
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              Text(
                'Les notifications non lues sont mises en avant avec un fond plus clair.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _textSecondary,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildNotificationList() {
    final notifications = controller.filteredNotifications;

    if (controller.isLoading.value && notifications.isEmpty) {
      return const _ShimmerLoadingList();
    }

    if (notifications.isEmpty) {
      return _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      color: _accent,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 18),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationCardImproved(
            notification: notification,
            controller: controller,
            onTap: () {
              if (notification['read'] != true) {
                controller.markAsRead(notification['id']);
              }
            },
          );
        },
      ),
    );
  }
}

class _NotificationStat extends StatelessWidget {
  const _NotificationStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: NotificationsPage._textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: NotificationsPage._textPrimary,
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

// ============================================================================
//  FILTRES
// ============================================================================
class _FilterChips extends StatelessWidget {
  final NotificationsController controller;
  final Function(String) onFilterChanged;

  const _FilterChips({required this.controller, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFilter = controller.currentFilter.value;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _FilterChip(
            label: 'Toutes',
            icon: Icons.all_inclusive_rounded,
            value: 'all',
            selected: currentFilter == 'all',
            onSelected: onFilterChanged,
          ),
          _FilterChip(
            label: 'Non lues',
            icon: Icons.mark_email_unread_outlined,
            value: 'unread',
            selected: currentFilter == 'unread',
            onSelected: onFilterChanged,
          ),
        ],
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? NotificationsPage._accent : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: selected ? Colors.transparent : NotificationsPage._border,
            width: 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: NotificationsPage._accent.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : NotificationsPage._textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color:
                    selected ? Colors.white : NotificationsPage._textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
//  CARTE DE NOTIFICATION AMÉLIORÉE
// ============================================================================
class _NotificationCardImproved extends StatefulWidget {
  final Map<String, dynamic> notification;
  final NotificationsController controller;
  final VoidCallback onTap;

  const _NotificationCardImproved({
    required this.notification,
    required this.controller,
    required this.onTap,
  });

  @override
  State<_NotificationCardImproved> createState() =>
      _NotificationCardImprovedState();
}

class _NotificationCardImprovedState extends State<_NotificationCardImproved>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRead = widget.notification['read'] ?? false;
    final type = widget.notification['type'] ?? 'default';
    final color = _getColorForType(type);
    final iconData = _getIconForType(type);
    final timestamp = widget.notification['timestamp'] as DateTime?;
    final timeAgo = _formatTimeAgo(timestamp);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isRead
                    ? NotificationsPage._card
                    : NotificationsPage._cardUnread,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isRead
                      ? NotificationsPage._border
                      : color.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                  if (!isRead)
                    BoxShadow(
                      color: color.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: color.withOpacity(0.12)),
                    ),
                    child: Icon(iconData, color: color, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                widget.notification['title'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: NotificationsPage._textPrimary,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.notification['body'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.5,
                            color: NotificationsPage._textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _buildMetaChip(
                              icon: Icons.access_time_rounded,
                              label: timeAgo,
                            ),
                            _buildTypeBadge(type, color),
                          ],
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

  Widget _buildMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: NotificationsPage._textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: NotificationsPage._textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String type, Color color) {
    String label;
    switch (type) {
      case 'reservation':
        label = 'Réservation';
        break;
      case 'cancellation':
        label = 'Annulation';
        break;
      case 'update':
        label = 'Mise à jour';
        break;
      default:
        label = 'Info';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'reservation':
        return NotificationsPage._success;
      case 'cancellation':
        return NotificationsPage._error;
      case 'update':
        return NotificationsPage._warning;
      default:
        return NotificationsPage._info;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'reservation':
        return Icons.event_available_rounded;
      case 'cancellation':
        return Icons.cancel_outlined;
      case 'update':
        return Icons.sync_alt_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatTimeAgo(DateTime? timestamp) {
    if (timestamp == null) return 'à l’instant';
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inSeconds < 60) return 'à l’instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return 'il y a ${diff.inDays} j';
    if (diff.inDays < 30) return 'il y a ${(diff.inDays / 7).floor()} sem.';
    return '${timestamp.day}/${timestamp.month}';
  }
}

// ============================================================================
//  ÉTAT VIDE
// ============================================================================
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF0F4FF), Color(0xFFF8FAFF)],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFDCE6FF)),
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 52,
              color: NotificationsPage._accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: NotificationsPage._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour. Les nouvelles alertes apparaîtront ici.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: NotificationsPage._textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
//  SHIMMER LOADING
// ============================================================================
class _ShimmerLoadingList extends StatelessWidget {
  const _ShimmerLoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: NotificationsPage._border,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 16,
                  color: NotificationsPage._border,
                ),
                const SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.75,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: double.infinity,
                    height: 12,
                    color: NotificationsPage._border,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                        width: 56,
                        height: 10,
                        color: NotificationsPage._border),
                    const SizedBox(width: 12),
                    Container(
                        width: 72,
                        height: 10,
                        color: NotificationsPage._border),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key});

  NotificationsController _resolveController() {
    if (Get.isRegistered<NotificationsController>()) {
      return Get.find<NotificationsController>();
    }
    return Get.put(NotificationsController(), permanent: true);
  }

  void _showNotificationsDialog(
      BuildContext context, NotificationsController controller) {
    controller.syncNotificationsSilently();

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Obx(() {
              final items = controller.filteredNotifications.take(4).toList();

              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: NotificationsPage._textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: NotificationsPage._textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 22),
                        child: Center(
                          child: Text(
                            'Aucune notification pour le moment',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: NotificationsPage._textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ...items.map((n) {
                        final isRead = n['read'] == true;
                        final type = (n['type'] ?? '').toString().toLowerCase();
                        final color = type.contains('cancel')
                            ? NotificationsPage._error
                            : type.contains('confirm') ||
                                    type.contains('reservation')
                                ? NotificationsPage._success
                                : NotificationsPage._info;
                        final icon = type.contains('cancel')
                            ? Icons.cancel_outlined
                            : type.contains('confirm') ||
                                    type.contains('reservation')
                                ? Icons.check_circle_outline
                                : Icons.notifications_none_rounded;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                isRead ? Colors.white : const Color(0xFFF8FAFF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isRead
                                  ? NotificationsPage._border
                                  : color.withOpacity(0.25),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (n['title'] ?? 'Notification').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: NotificationsPage._textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      (n['body'] ?? '').toString(),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: NotificationsPage._textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (controller.unreadCount.value > 0)
                            TextButton(
                              onPressed: controller.markAllAsRead,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                              child: Text(
                                'Tout marquer',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: NotificationsPage._accent,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.toNamed('/notifications');
                            },
                            icon: const Icon(Icons.arrow_forward_rounded,
                                size: 16),
                            label: Text(
                              'Toutes les notifications',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: NotificationsPage._accent,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = _resolveController();
      final unread = controller.unreadCount.value;

      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showNotificationsDialog(context, controller),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NotificationsPage._border),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 20,
                color: NotificationsPage._textSecondary,
              ),
            ),
            if (unread > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: NotificationsPage._accent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
