import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/space_controller.dart';
import 'package:flutter_getx_app/app/routes/app_routes.dart';

import 'custom_sidebar.dart';

class SpacesView extends StatelessWidget {
  SpacesView({super.key});

  final SpaceController controller = Get.isRegistered<SpaceController>()
      ? Get.find<SpaceController>()
      : Get.put(SpaceController());

  final RxString _statusFilter = 'Tous les statuts'.obs;

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
                _buildAppBar(context, isCompact),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 20),
                        _buildFilterBar(),
                        const SizedBox(height: 20),
                        _buildSpacesTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isCompact) {
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
              icon: const Icon(Icons.menu, color: Colors.black87),
            ),
            const SizedBox(width: 8),
          ],
          const Spacer(),
          const Icon(Icons.notifications_outlined,
              color: Colors.grey, size: 20),
          const SizedBox(width: 14),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFFE2E8F0),
            child: Icon(Icons.person, color: Colors.blue, size: 18),
          ),
          const SizedBox(width: 8),
          const Text(
            'intern',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.black, size: 18),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des espaces',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Gerez vos espaces de coworking',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Get.toNamed(Routes.CREATE_SPACE),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Nouvel espace'),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: controller.searchSpaces,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(Icons.search, size: 18),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: _statusFilter.value,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                ),
                items: const [
                  'Tous les statuts',
                  'Disponible',
                  'Occupé',
                  'En maintenance',
                ]
                    .map((value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _statusFilter.value = value;
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacesTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Obx(() {
        if (controller.isLoading.value) {
          return const Padding(
            padding: EdgeInsets.all(80),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final items = controller.spaces
            .where((space) => _matchesStatus(space.status, _statusFilter.value))
            .toList();

        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('Aucun espace trouve')),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: const Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text('ESPACE',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 2,
                      child: Text('TYPE',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      flex: 2,
                      child: Text('LOCALISATION',
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Text('CAPACITE',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Text('TARIF/H',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Text('STATUT',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w700))),
                  Expanded(
                      child: Align(
                          alignment: Alignment.centerRight,
                          child: Text('ACTIONS',
                              style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w700)))),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
              itemBuilder: (_, index) => _buildSpaceRow(items[index]),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSpaceRow(Space space) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              space.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              space.type,
              style: const TextStyle(color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              space.location,
              style: const TextStyle(color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '${space.capacity}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          Expanded(
            child: Text(
              '${space.hourlyRate.toStringAsFixed(0)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Center(child: _buildStatusBadge(space.status))),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () =>
                        Get.toNamed(Routes.CREATE_SPACE, arguments: space),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    onPressed: () => controller.deleteSpace(space.id),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final normalized = status.trim().toLowerCase();

    Color color;
    if (normalized.contains('disponible')) {
      color = const Color(0xFF16A34A);
    } else if (normalized.contains('occup')) {
      color = const Color(0xFFD97706);
    } else if (normalized.contains('maintenance')) {
      color = const Color(0xFFDC2626);
    } else {
      color = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  bool _matchesStatus(String status, String filter) {
    if (filter == 'Tous les statuts') return true;

    final left = status.trim().toLowerCase();
    final right = filter.trim().toLowerCase();

    if (right.contains('maintenance')) {
      return left.contains('maintenance');
    }
    if (right.contains('occup')) {
      return left.contains('occup');
    }
    if (right.contains('disponible')) {
      return left.contains('disponible');
    }

    return left == right;
  }
}
