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
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Ce qu’il faut savoir',
            style: GoogleFonts.inter(
              fontSize: 13,
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
                'Tout marquer',
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
      final all = controller.filteredNotifications;
      final unread = all.where((n) => n['read'] != true).toList();

      // Filtre local (Toutes / Non lues)
      return Column(
        children: [
          // Filtres
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: _FilterChips(
              onFilterChanged: (filter) {
                controller
                    .toggleFilter(filter); // à implémenter dans le controller
              },
            ),
          ),
          Expanded(
            child: _buildNotificationList(),
          ),
        ],
      );
    });
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

// ============================================================================
//  FILTRES
// ============================================================================
class _FilterChips extends StatelessWidget {
  final Function(String) onFilterChanged;

  const _FilterChips({required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentFilter =
          Get.find<NotificationsController>().currentFilter.value;
      return Row(
        children: [
          _FilterChip(
            label: 'Toutes',
            value: 'all',
            selected: currentFilter == 'all',
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 10),
          _FilterChip(
            label: 'Non lues',
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
  final String value;
  final bool selected;
  final Function(String) onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : NotificationsPage._textSecondary,
          ),
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
              padding: const EdgeInsets.all(16),
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
                  // Icône animée
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.15),
                          color.withOpacity(0.05)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(iconData, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.notification['title'] ?? '',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: NotificationsPage._textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
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
                            height: 1.45,
                            color: NotificationsPage._textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                size: 12,
                                color: NotificationsPage._textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              timeAgo,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: NotificationsPage._textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: NotificationsPage._accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 48,
              color: NotificationsPage._accent,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: NotificationsPage._textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: NotificationsPage._textSecondary,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: NotificationsPage._border,
              borderRadius: BorderRadius.circular(16),
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
                Container(
                  width: 200,
                  height: 12,
                  color: NotificationsPage._border,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                        width: 50,
                        height: 10,
                        color: NotificationsPage._border),
                    const SizedBox(width: 12),
                    Container(
                        width: 70,
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
