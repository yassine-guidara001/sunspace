import 'equipment.dart';

class Space {
  final int id;
  final String nom;
  final String slug;
  final int capacite;
  final List<Equipment> equipements;

  Space({
    required this.id,
    required this.nom,
    required this.slug,
    required this.capacite,
    required this.equipements,
  });

  factory Space.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return Space(
      id: json['id'] ?? attributes['id'] ?? 0,
      nom: attributes['nom'] ?? '',
      slug: attributes['slug'] ?? '',
      capacite: attributes['capacite'] ?? 0,
      equipements: (attributes['equipements']?['data'] ?? [])
          .map<Equipment>((e) => Equipment.fromJson(e))
          .toList(),
    );
  }
}
