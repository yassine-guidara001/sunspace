class Equipment {
  final int id;
  final String documentId;
  final String name;
  final String type;
  final String status;
  final String serialNumber;
  final String purchaseDate;
  final double purchasePrice;
  final double pricePerDay;
  final String warrantyExpiration;
  final String description;
  final String notes;

  // 👇 رجعناهم
  final List<int> spaceIds;
  final String spaceLabel;

  Equipment({
    required this.id,
    required this.documentId,
    required this.name,
    required this.type,
    required this.status,
    required this.serialNumber,
    required this.purchaseDate,
    required this.purchasePrice,
    this.pricePerDay = 0,
    required this.warrantyExpiration,
    required this.description,
    required this.notes,
    required this.spaceIds,
    required this.spaceLabel,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    List<int> spaces = [];
    String spaceLabel = "Aucun";

    if (json['spaces'] != null && json['spaces'] is List) {
      spaces = List<int>.from(
        json['spaces'].map((e) => e['id']),
      );

      if (json['spaces'].isNotEmpty) {
        spaceLabel = json['spaces'][0]['name'] ?? "Aucun";
      }
    }

    return Equipment(
      id: json['id'] ?? 0,
      documentId: json['documentId'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      status: json['mystatus'] ?? '',
      serialNumber: json['serial_number'] ?? '',
      purchaseDate: json['purchase_date'] ?? '',
      purchasePrice: (json['purchase_price'] ?? 0).toDouble(),
      pricePerDay: (json['price_per_day'] ?? 0).toDouble(),
      warrantyExpiration: json['warranty_expiry'] ?? '',
      description: json['description'] ?? '',
      notes: json['notes'] ?? '',
      spaceIds: spaces,
      spaceLabel: spaceLabel,
    );
  }

  static String? _normalizeDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (iso.hasMatch(value)) return value;

    final fr = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(value);
    if (fr != null) {
      final dd = fr.group(1)!;
      final mm = fr.group(2)!;
      final yyyy = fr.group(3)!;
      return '$yyyy-$mm-$dd';
    }

    return null;
  }

  Map<String, dynamic> toJson() {
    final safeName = name.trim().isEmpty ? 'Sans nom' : name.trim();
    final safeType = type.trim().isEmpty ? 'Autre' : type.trim();
    final safeStatus = status.trim().isEmpty ? 'Disponible' : status.trim();
    final safeSerial = serialNumber.trim().isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : serialNumber.trim();

    final payload = <String, dynamic>{
      "name": safeName,
      "type": safeType,
      "mystatus": safeStatus,
      "serial_number": safeSerial,
    };

    final normalizedPurchaseDate = _normalizeDate(purchaseDate);
    if (normalizedPurchaseDate != null) {
      payload["purchase_date"] = normalizedPurchaseDate;
    }

    if (purchasePrice > 0) {
      payload["purchase_price"] = purchasePrice;
    }

    final normalizedWarrantyDate = _normalizeDate(warrantyExpiration);
    if (normalizedWarrantyDate != null) {
      payload["warranty_expiry"] = normalizedWarrantyDate;
    }

    if (description.trim().isNotEmpty) {
      payload["description"] = description.trim();
    }

    if (notes.trim().isNotEmpty) {
      payload["notes"] = notes.trim();
    }

    payload["spaces"] = spaceIds;

    payload["price_per_day"] = pricePerDay > 0 ? pricePerDay : 0;

    return {
      "data": payload,
    };
  }
}
