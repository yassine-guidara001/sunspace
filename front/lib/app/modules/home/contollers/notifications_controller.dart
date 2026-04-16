import 'dart:async';
import 'dart:convert';

import 'package:flutter_getx_app/app/core/service/auth_service.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

/// Contrôleur pour gérer l'interface des notifications
class NotificationsController extends GetxController {
  static const String _baseApiUrl = 'http://localhost:3001/api';
  static const Duration _syncInterval = Duration(seconds: 20);

  final RxList<Map<String, dynamic>> notifications =
      <Map<String, dynamic>>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxString currentFilter = 'all'.obs; // 'all' ou 'unread'

  // Compatibilite avec l'ancien flux qui utilisait selectedFilter.
  // Les deux pointent vers la meme valeur reactive.
  final RxString selectedFilter = 'all'.obs;

  final RxInt currentPage = 0.obs;
  final int pageSize = 20;
  bool hasMoreData = true;
  Timer? _syncTimer;
  bool _isSyncing = false;

  AuthService get _auth => Get.find<AuthService>();

  @override
  void onInit() {
    super.onInit();
    loadNotifications(refresh: true);
    loadUnreadCount();
    _startAutoSync();
  }

  @override
  void onClose() {
    _syncTimer?.cancel();
    super.onClose();
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      syncNotificationsSilently();
    });
  }

  Future<void> syncNotificationsSilently() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      await loadUnreadCount();
      await loadNotifications(refresh: true);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        currentPage.value = 0;
        notifications.clear();
        hasMoreData = true;
      }

      isLoading.value = true;

      final skip = currentPage.value * pageSize;
      final query = <String, String>{
        'skip': '$skip',
        'take': '$pageSize',
      };

      if (selectedFilter.value == 'unread') {
        query['isRead'] = 'false';
      } else if (selectedFilter.value != 'all') {
        query['type'] = selectedFilter.value;
      }

      final uri = Uri.parse('$_baseApiUrl/notifications')
          .replace(queryParameters: query);
      final response = await http.get(uri, headers: _auth.authHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final rawList =
            (payload['data'] as List<dynamic>? ?? <dynamic>[]).cast<dynamic>();

        final parsed = rawList.map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          final createdAtRaw = map['createdAt']?.toString();
          final readAtRaw = map['readAt']?.toString();
          return {
            ...map,
            'read': map['isRead'] == true,
            'timestamp': createdAtRaw != null
                ? DateTime.tryParse(createdAtRaw)?.toLocal()
                : null,
            'readAt': readAtRaw != null
                ? DateTime.tryParse(readAtRaw)?.toLocal()
                : null,
          };
        }).toList();

        notifications.addAll(parsed);
        if (parsed.length < pageSize) {
          hasMoreData = false;
        } else {
          currentPage.value++;
        }
      }
    } catch (_) {
      hasMoreData = false;
    } finally {
      isLoading.value = false;
      await loadUnreadCount();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      final uri = Uri.parse('$_baseApiUrl/notifications/unread-count');
      final response = await http.get(uri, headers: _auth.authHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = payload['unreadCount'];
        unreadCount.value = raw is num
            ? raw.toInt()
            : int.tryParse(raw?.toString() ?? '0') ?? 0;
        return;
      }
    } catch (_) {
      // no-op
    }

    unreadCount.value = notifications.where((n) => n['read'] != true).length;
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      final uri = Uri.parse('$_baseApiUrl/notifications/$notificationId/read');
      final response = await http.patch(uri, headers: _auth.authHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final index =
            notifications.indexWhere((n) => n['id'] == notificationId);
        if (index >= 0) {
          notifications[index]['read'] = true;
          notifications[index]['isRead'] = true;
          notifications[index]['readAt'] = DateTime.now();
          notifications.refresh();
        }
      }
    } catch (_) {
      // no-op
    } finally {
      await loadUnreadCount();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final uri = Uri.parse('$_baseApiUrl/notifications/read-all');
      final response = await http.patch(uri, headers: _auth.authHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        for (final n in notifications) {
          n['read'] = true;
          n['isRead'] = true;
          n['readAt'] = DateTime.now();
        }
        notifications.refresh();
      }
    } catch (_) {
      // no-op
    } finally {
      await loadUnreadCount();
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final uri = Uri.parse('$_baseApiUrl/notifications/$notificationId');
      final response = await http.delete(uri, headers: _auth.authHeaders);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        notifications.removeWhere((n) => n['id'] == notificationId);
      }
    } catch (_) {
      // no-op
    } finally {
      await loadUnreadCount();
    }
  }

  void filterNotifications(String type) {
    selectedFilter.value = type;
    currentFilter.value = type;
    loadNotifications(refresh: true);
  }

  void toggleFilter(String filter) {
    currentFilter.value = filter;
    selectedFilter.value = filter;
    updateFilteredNotifications();
  }

  void updateFilteredNotifications() {
    notifications.refresh();
  }

  Future<void> loadMore() async {
    if (!hasMoreData || isLoading.value) return;
    await loadNotifications();
  }

  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (currentFilter.value == 'unread') {
      return notifications.where((n) => n['read'] != true).toList();
    }
    return notifications;
  }

  String getNotificationColor(String type) {
    switch (type) {
      case 'RESERVATION_CONFIRMATION':
      case 'RESERVATION_REMINDER_24H':
      case 'RESERVATION_REMINDER_1H':
      case 'RESERVATION_MODIFIED':
      case 'RESERVATION_CANCELLED':
        return '0xFF3B82F6';
      case 'NEW_COURSE_AVAILABLE':
      case 'TRAINING_SESSION_STARTED':
        return '0xFF10B981';
      case 'TEACHER_MESSAGE':
        return '0xFF8B5CF6';
      case 'SUBSCRIPTION_PAYMENT_DUE':
        return '0xFFEF4444';
      case 'PROMOTION_OFFER':
        return '0xFFF59E0B';
      default:
        return '0xFF64748B';
    }
  }

  String getNotificationIcon(String type) {
    switch (type) {
      case 'RESERVATION_CONFIRMATION':
      case 'RESERVATION_REMINDER_24H':
      case 'RESERVATION_REMINDER_1H':
        return '✓';
      case 'RESERVATION_CANCELLED':
        return '✗';
      case 'RESERVATION_MODIFIED':
        return '✎';
      case 'NEW_COURSE_AVAILABLE':
      case 'TRAINING_SESSION_STARTED':
        return '🎓';
      case 'TEACHER_MESSAGE':
        return '💬';
      case 'SUBSCRIPTION_PAYMENT_DUE':
        return '💳';
      case 'PROMOTION_OFFER':
        return '🎉';
      default:
        return 'ℹ';
    }
  }
}
