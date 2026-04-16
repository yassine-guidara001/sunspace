import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/models/Reservation%20modal.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/floor%20plan%20data.dart';
import 'package:flutter_getx_app/app/modules/home/modules/plan/models/space_model%20plan.dart';
import 'package:flutter_getx_app/app/modules/spaces/views/widgets/Interactive%20floor%20plan.dart';
import 'package:flutter_getx_app/services/r%C3%A9servation_api_service.dart';
import 'package:get/get.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/dashboard_topbar.dart';

class ReserverEspaceScreen extends GetView<HomeController> {
  const ReserverEspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8EDF4),
      body: Row(
        children: const [
          CustomSidebar(),
          Expanded(
            child: Column(
              children: [
                DashboardTopBar(),
                Expanded(child: _PlanContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanContent extends StatefulWidget {
  const _PlanContent();

  @override
  State<_PlanContent> createState() => _PlanContentState();
}

class _PlanContentState extends State<_PlanContent> {
  final ReservationApiService _apiService = ReservationApiService();
  String? _selectedSpaceId;
  bool _isLoading = false;
  final Map<String, SpaceModel> _spaceByZoneId = {};
  final Map<String, String> _zoneLabels = {};
  final List<SpaceModel> _loadedSpaces = [];

  @override
  void initState() {
    super.initState();
    _loadSpacesForPlan();
  }

  Future<void> _loadSpacesForPlan() async {
    try {
      final spaces = await _apiService.fetchSpaces();
      final zones = FloorPlanData.zones;
      _loadedSpaces
        ..clear()
        ..addAll(spaces);

      final mappedSpaces = <String, SpaceModel>{};
      final mappedLabels = <String, String>{};
      final usedSpaceIds = <String>{};

      String normalizeSlug(String value) {
        return value
            .toLowerCase()
            .trim()
            .replaceAll('_', '-')
            .replaceAll(' ', '-')
            .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      }

      // 1) Mapping principal: zone.spaceId <-> slug API
      for (final space in spaces) {
        final spaceSlug = normalizeSlug(space.slug);
        if (spaceSlug.isEmpty) continue;

        final matchingZones = zones.where((z) {
          return normalizeSlug(z.spaceId) == spaceSlug;
        });

        if (matchingZones.isNotEmpty) {
          final zone = matchingZones.first;
          mappedSpaces[zone.spaceId] = space;
          mappedLabels[zone.spaceId] = space.name;
          usedSpaceIds.add(space.id);
        }
      }

      // 2) Fallback: si slug non aligne, mapper par ordre pour garder le plan utilisable
      final unassignedZones =
          zones.where((z) => !mappedSpaces.containsKey(z.spaceId)).toList();
      final remainingSpaces =
          spaces.where((s) => !usedSpaceIds.contains(s.id)).toList();
      final fallbackSpaces =
          remainingSpaces.isNotEmpty ? remainingSpaces : spaces;

      // 3) Fallback robuste: couvrir toutes les zones, même si peu d'espaces existent
      if (fallbackSpaces.isNotEmpty) {
        for (var i = 0; i < unassignedZones.length; i++) {
          final zone = unassignedZones[i];
          final space = fallbackSpaces[i % fallbackSpaces.length];
          mappedSpaces[zone.spaceId] = space;
          mappedLabels[zone.spaceId] = space.name;
        }
      }

      if (!mounted) return;
      setState(() {
        _spaceByZoneId
          ..clear()
          ..addAll(mappedSpaces);
        _zoneLabels
          ..clear()
          ..addAll(mappedLabels);
      });
    } catch (_) {
      // Garde les labels statiques si le chargement des espaces échoue.
    }
  }

  Future<void> _onSpaceTapped(
      String spaceId, String label, Offset globalPos) async {
    if (_isLoading) return;

    SpaceModel? linkedSpace = _spaceByZoneId[spaceId];

    // Retry silencieux au clic si mapping indisponible (ex: chargement initial raté)
    if (linkedSpace == null) {
      await _loadSpacesForPlan();
      linkedSpace = _spaceByZoneId[spaceId] ??
          (_loadedSpaces.isNotEmpty ? _loadedSpaces.first : null);
    }

    if (linkedSpace == null) {
      _snack(
        'Impossible de charger les espaces. Vérifiez que le backend fonctionne puis réessayez.',
        const Color(0xFFEF4444),
        Icons.error_outline,
      );
      return;
    }

    setState(() {
      _selectedSpaceId = spaceId;
      _isLoading = true;
    });

    try {
      // ── 2 requêtes en parallèle ─────────────────────────────────────
      final results = await Future.wait([
        _apiService.fetchSpaceById(
            linkedSpace.id), // requête 1 : espace réel lié à la zone
        _apiService.fetchAvailableEquipments(), // requête 2 : equipment-assets
      ]);

      final space = results[0] as SpaceModel;
      final equipments = results[1] as List<EquipmentModel>;

      final filteredEquipments = equipments.where((equipment) {
        // Règle métier: "Aucun" => équipement global, visible dans tous les espaces.
        if (equipment.spaceIds.isEmpty) return true;
        return equipment.spaceIds.contains(space.id);
      }).toList();

      // Injecte les équipements disponibles dans le modèle space
      final spaceWithEquipments = SpaceModel(
        id: space.id,
        slug: space.slug,
        name: space.name,
        description: space.description,
        maxPersons: space.maxPersons,
        pricePerHour: space.pricePerHour,
        pricePerDay: space.pricePerDay,
        type: space.type,
        isAvailable: space.isAvailable,
        equipments:
            space.equipments.isNotEmpty ? space.equipments : filteredEquipments,
      );

      if (!mounted) return;

      final result = await ReservationModal.show(
        context,
        space: spaceWithEquipments,
        apiService: _apiService,
        availableEquipments: filteredEquipments,
      );

      if (result == true) {
        setState(() => _selectedSpaceId = null);
        _snack('Réservation effectuée !', const Color(0xFF22C55E),
            Icons.check_circle);
      } else {
        setState(() => _selectedSpaceId = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _selectedSpaceId = null);
        _snack('Erreur : ${e.toString()}', const Color(0xFFEF4444),
            Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Réserver un Espace',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3)),
          const SizedBox(height: 4),
          const Text(
              'Sélectionnez un espace sur le plan pour effectuer votre réservation.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 18),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4DCE6)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InteractiveFloorPlan(
                      onSpaceTapped: _onSpaceTapped,
                      selectedSpaceId: _selectedSpaceId,
                      zoneLabels: _zoneLabels,
                      spaceMap: _spaceByZoneId,
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: _Legend(),
                    ),
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.6),
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF22C55E), strokeWidth: 2.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        _Dot(color: Color(0xFF22C55E), label: 'Disponible'),
        SizedBox(width: 14),
        _Dot(color: Color(0xFF38BDF8), label: 'Sélectionné'),
        SizedBox(width: 14),
        _Dot(color: Color(0xFF94A3B8), label: 'Indisponible'),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final String label;
  const _Dot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
    ]);
  }
}
