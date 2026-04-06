import 'package:flutter/material.dart';

class FloorSpaceZone {
  final String spaceId; // = slug Strapi exact
  final String label;
  final Rect rect;

  const FloorSpaceZone({
    required this.spaceId,
    required this.label,
    required this.rect,
  });

  bool containsPoint(Offset point) => rect.contains(point);
}

/// viewBox = 0 0 2780 1974
/// spaceId = slug Strapi → filters[slug][$eq]=espaceX
class FloorPlanData {
  static const double svgWidth  = 2780;
  static const double svgHeight = 1974;

  static const List<FloorSpaceZone> zones = [
    FloorSpaceZone(
      spaceId: 'espace1',
      label: 'Open Space Principal',
      rect: Rect.fromLTWH(794, 30, 686, 419),
    ),
    FloorSpaceZone(
      spaceId: 'espace2',
      label: 'Espace 2',
      rect: Rect.fromLTWH(2032, 27, 355, 430),
    ),
    FloorSpaceZone(
      spaceId: 'espace3',
      label: 'Espace 3',
      rect: Rect.fromLTWH(2026, 470, 361, 365),
    ),
    FloorSpaceZone(
      spaceId: 'espace4',
      label: 'Espace 4',
      rect: Rect.fromLTWH(2034, 862, 345, 352),
    ),
    FloorSpaceZone(
      spaceId: 'espace5',
      label: 'Espace 5',
      rect: Rect.fromLTWH(2024, 1235, 361, 395),
    ),
    FloorSpaceZone(
      spaceId: 'espace6',
      label: 'Espace 6',
      rect: Rect.fromLTWH(1514, 1531, 349, 408),
    ),
    FloorSpaceZone(
      spaceId: 'espace7',
      label: 'Espace 7',
      rect: Rect.fromLTWH(1451, 1168, 245, 341),
    ),
    FloorSpaceZone(
      spaceId: 'espace8',
      label: 'Espace 8',
      rect: Rect.fromLTWH(975, 1123, 280, 384),
    ),
    FloorSpaceZone(
      spaceId: 'espace9',
      label: 'Espace 9',
      rect: Rect.fromLTWH(712, 873, 261, 704),
    ),
    FloorSpaceZone(
      spaceId: 'espace10',
      label: 'Espace 10',
      rect: Rect.fromLTWH(382, 599, 326, 867),
    ),
    FloorSpaceZone(
      spaceId: 'espace11',
      label: 'Espace 11',
      rect: Rect.fromLTWH(718, 462, 224, 384),
    ),
    FloorSpaceZone(
      spaceId: 'espace12',
      label: 'Espace 12',
      rect: Rect.fromLTWH(1153, 462, 253, 478),
    ),
    FloorSpaceZone(
      spaceId: 'espace13',
      label: 'Espace 13',
      rect: Rect.fromLTWH(1475, 518, 324, 333),
    ),
  ];
}