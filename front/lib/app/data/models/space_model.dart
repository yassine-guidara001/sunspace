class Space {
  final int id;
  final String documentId;
  final String name;
  final String slug;
  final String? type;
  final String? location;
  final String? floor;
  final int capacity;
  final double area;
  final int svgWidth;
  final int svgHeight;
  final String status;
  final bool isCoworking;
  final bool allowGuestReservations;
  final double hourlyRate;
  final double dailyRate;
  final double monthlyRate;
  final double? overtimeRate;
  final String currency;
  final String description;
  final bool available24h;
  final bool isCoworkingSpace;
  final bool allowLimitedReservations;
  final double? surface;
  final double? width;
  final double? height;
  final String? features;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Space({
    required this.id,
    required this.documentId,
    required this.name,
    required this.slug,
    required this.type,
    required this.location,
    required this.floor,
    required this.capacity,
    required this.area,
    required this.svgWidth,
    required this.svgHeight,
    required this.status,
    required this.isCoworking,
    required this.allowGuestReservations,
    required this.hourlyRate,
    required this.dailyRate,
    required this.monthlyRate,
    required this.overtimeRate,
    required this.currency,
    required this.description,
    required this.available24h,
    required this.isCoworkingSpace,
    required this.allowLimitedReservations,
    required this.surface,
    required this.width,
    required this.height,
    required this.features,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  static int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  static bool _toBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final s = v.toString().toLowerCase().trim();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString())?.toLocal();
  }

  /// Extrait le texte brut depuis un champ description Strapi v5 (rich text ou string).
  static String _parseDescription(dynamic v) {
    if (v == null) return '';
    if (v is String) return v.trim();
    if (v is List) {
      final buffer = StringBuffer();
      for (final block in v) {
        if (block is Map) {
          final children = block['children'];
          if (children is List) {
            for (final child in children) {
              if (child is Map) {
                final text = child['text'];
                if (text is String && text.isNotEmpty) {
                  buffer.write(text);
                }
              }
            }
          }
        }
        if (buffer.isNotEmpty) buffer.write(' ');
      }
      return buffer.toString().trim();
    }
    return '';
  }

  factory Space.fromJson(Map<String, dynamic> json) {
    final attrs = json["attributes"];
    final a = attrs is Map<String, dynamic> ? attrs : json;

    final spaceId = _toInt(json["id"]);

    final rawDocumentId = json["documentId"] ??
        json["document_id"] ??
        a["documentId"] ??
        a["document_id"];

    // Si pas de documentId, utiliser l'id comme fallback
    final finalDocumentId = (rawDocumentId ?? '').toString().trim().isEmpty
        ? spaceId.toString()
        : (rawDocumentId ?? '').toString().trim();

    return Space(
      id: spaceId,
      documentId: finalDocumentId,
      name: (a["name"] ?? "").toString(),
      slug: (a["slug"] ?? "").toString(),
      type: a["type"]?.toString(),
      location: a["location"]?.toString(),
      floor: a["floor"]?.toString(),
      capacity: _toInt(a["capacity"], fallback: 1),
      area: _toDouble(a["area_sqm"] ?? a["surface"]),
      svgWidth: _toInt(a["svg_width"] ?? a["width"]),
      svgHeight: _toInt(a["svg_height"] ?? a["height"]),
      status:
          (a["availability_status"] ?? a["status"] ?? "Disponible").toString(),
      isCoworking: _toBool(a["is_coworking"] ?? a["isCoworkingSpace"]),
      allowGuestReservations: _toBool(
          a["allow_guest_reservations"] ?? a["allowLimitedReservations"]),
      hourlyRate: _toDouble(a["hourly_rate"] ?? a["hourlyRate"]),
      dailyRate: _toDouble(a["daily_rate"] ?? a["dailyRate"]),
      monthlyRate: _toDouble(a["monthly_rate"] ?? a["monthlyRate"]),
      overtimeRate: _toDouble(a["overtimeRate"]),
      currency: (a["currency"] ?? "TND").toString(),
      description: _parseDescription(a["description"]),
      available24h: _toBool(a["available24h"]),
      isCoworkingSpace: _toBool(a["isCoworkingSpace"] ?? a["is_coworking"]),
      allowLimitedReservations: _toBool(
          a["allowLimitedReservations"] ?? a["allow_guest_reservations"]),
      surface: _toDouble(a["surface"] ?? a["area_sqm"]),
      width: _toDouble(a["width"] ?? a["svg_width"]),
      height: _toDouble(a["height"] ?? a["svg_height"]),
      features: a["features"]?.toString(),
      imageUrl: a["imageUrl"]?.toString(),
      createdAt: _toDateTime(a["createdAt"]),
      updatedAt: _toDateTime(a["updatedAt"]),
    );
  }
}
