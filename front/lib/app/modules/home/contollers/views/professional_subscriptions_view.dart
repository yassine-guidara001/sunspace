import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/professional_subscriptions_page.dart';
import 'package:get/get.dart';
import 'custom_sidebar.dart';

class ProfessionalSubscriptionsView extends StatelessWidget {
  const ProfessionalSubscriptionsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 920;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          if (!isCompact) const CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, isCompact),
                const Expanded(child: ProfessionalSubscriptionsPage()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isCompact) {
    return Container(
      height: isCompact ? 60 : 64,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 20),
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
          ] else
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 12),
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none,
                color: Color(0xFF475569), size: 20),
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 14,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, size: 16, color: Colors.blue),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 8),
            const Text(
              'intern',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
