import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/notifications_controller.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:get/get.dart';
import 'notifications_page.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({super.key});

  NotificationsController _controller() {
    if (Get.isRegistered<NotificationsController>()) {
      return Get.find<NotificationsController>();
    }
    return Get.put(NotificationsController(), permanent: true);
  }

  StorageService? _storage() {
    try {
      return Get.find<StorageService>();
    } catch (_) {
      return null;
    }
  }

  String _displayName() {
    final data = _storage()?.getUserData();
    if (data == null) return 'Utilisateur';

    final firstName = data['firstName']?.toString().trim() ??
        data['first_name']?.toString().trim() ??
        '';
    final lastName = data['lastName']?.toString().trim() ??
        data['last_name']?.toString().trim() ??
        '';
    final username = data['username']?.toString().trim() ?? '';
    final email = data['email']?.toString().trim() ?? '';

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    if (email.isNotEmpty) return email.split('@').first;
    return 'Utilisateur';
  }

  String _roleLabel() {
    final data = _storage()?.getUserData();
    final role = data?['role'];

    if (role is Map) {
      final name = role['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
    }

    final explicitRole = data?['userType']?.toString().trim() ??
        data?['user_type']?.toString().trim() ??
        '';
    if (explicitRole.isNotEmpty) return explicitRole;

    return 'Connecté';
  }

  @override
  Widget build(BuildContext context) {
    _controller();
    final isCompact = MediaQuery.of(context).size.width < 920;

    return Container(
      height: isCompact ? 60 : 70,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              tooltip: 'Menu',
              onPressed: () => CustomSidebar.openDrawerMenu(context),
              icon: const Icon(Icons.menu, color: Color(0xFF475569)),
            ),
            const SizedBox(width: 6),
          ] else
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          if (!isCompact) const SizedBox(width: 16),
          const NotificationBell(),
          const SizedBox(width: 12),
          if (!isCompact)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFDCEAFE),
                    child: Text(
                      _displayName().isNotEmpty
                          ? _displayName()[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Color(0xFF1664FF),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _displayName(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _roleLabel(),
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0xFFDCEAFE),
              child: Text(
                _displayName().isNotEmpty
                    ? _displayName()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF1664FF),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
