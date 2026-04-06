class Course {
  final int id;
  final String documentId;
  final String title;
  final String description;
  final String level;
  final double price;
  final String status;
  final DateTime createdAt;

  const Course({
    required this.id,
    required this.documentId,
    required this.title,
    required this.description,
    required this.level,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    final data = _extractDataNode(json);

    return Course(
      id: _toInt(data['id']),
      documentId: _extractDocumentId(data),
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      level: (data['level'] ?? 'Débutant').toString(),
      price: _toDouble(data['price']),
      status: (data['mystatus'] ?? data['status'] ?? 'Brouillon').toString(),
      createdAt: _toDateTime(data['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({bool withDataWrapper = true}) {
    final payload = <String, dynamic>{
      'title': title,
      'description': description,
      'level': level,
      'price': price,
      'status': status,
    };

    if (withDataWrapper) {
      return {'data': payload};
    }

    return payload;
  }

  Course copyWith({
    int? id,
    String? documentId,
    String? title,
    String? description,
    String? level,
    double? price,
    String? status,
    DateTime? createdAt,
  }) {
    return Course(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      description: description ?? this.description,
      level: level ?? this.level,
      price: price ?? this.price,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static Map<String, dynamic> _extractDataNode(Map<String, dynamic> json) {
    if (json.containsKey('data')) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return _extractDataNode(data);
      }
    }

    final attributes = json['attributes'];
    if (attributes is Map<String, dynamic>) {
      return {
        'id': json['id'] ?? _toInt(attributes['id']),
        'documentId': json['documentId'] ?? json['document_id'],
        ...attributes,
      };
    }

    return json;
  }

  static String _extractDocumentId(Map<String, dynamic> data) {
    final raw = data['documentId'] ?? data['document_id'];
    if (raw == null) return '';
    return raw.toString().trim();
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
