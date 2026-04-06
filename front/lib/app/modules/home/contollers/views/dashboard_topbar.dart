import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/notifications_controller.dart';
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

  @override
  Widget build(BuildContext context) {
    _controller();
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const NotificationBell(),
          const SizedBox(width: 16),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Color(0xFF1664FF), size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'Intern',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
