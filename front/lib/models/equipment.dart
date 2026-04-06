class Equipment {
  final int id;
  final String nom;
  final double prix;
  final String statut;

  Equipment({
    required this.id,
    required this.nom,
    required this.prix,
    required this.statut,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? json;
    return Equipment(
      id: json['id'] ?? attributes['id'] ?? 0,
      nom: attributes['nom'] ?? '',
      prix: (attributes['prix'] ?? 0).toDouble(),
      statut: attributes['statut'] ?? '',
    );
  }
}
