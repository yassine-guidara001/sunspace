class SpaceModel {
  final String id;
  final String slug; // Ex: "espace1", "espace2" - utilisé pour plan interactif
  final String name;
  final String description;
  final int maxPersons;
  final double pricePerHour;
  final double pricePerDay;
  final double pricePerMonth;
  final List<EquipmentModel> equipments;
  final SpaceType type;
  final bool isAvailable;
  final String location;
  final String floor;
  final String currency;

  const SpaceModel({
    required this.id,
    required this.slug,
    required this.name,
    required this.description,
    required this.maxPersons,
    required this.pricePerHour,
    required this.pricePerDay,
    this.pricePerMonth = 0,
    required this.equipments,
    required this.type,
    this.isAvailable = true,
    this.location = '',
    this.floor = '',
    this.currency = 'TND',
  });

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static int _toInt(dynamic value, {int fallback = 1}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    // Strapi v5 : données à plat
    String descText = '';
    final rawDesc = json['description'];
    if (rawDesc is String) {
      descText = rawDesc;
    } else if (rawDesc is List) {
      descText = rawDesc
          .map((block) {
            if (block is Map) {
              final children = block['children'];
              if (children is List) {
                return children
                    .map((c) => c is Map ? (c['text'] ?? '') : '')
                    .join('');
              }
            }
            return '';
          })
          .where((s) => s.isNotEmpty)
          .join('\n');
    }

    List<EquipmentModel> equipmentList = [];
    final equipRaw = json['equipment'] ?? json['equipments'];
    if (equipRaw is List && equipRaw.isNotEmpty) {
      equipmentList = equipRaw
          .map((e) => EquipmentModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final typeStr = json['type'] as String? ?? '';
    SpaceType spaceType;
    switch (typeStr.toLowerCase()) {
      case 'open space':
      case 'openspace':
        spaceType = SpaceType.openSpace;
        break;
      case 'salle de réunion':
      case 'meeting room':
      case 'meetingroom':
        spaceType = SpaceType.meetingRoom;
        break;
      case 'bureau privé':
      case 'bureau prive':
      case 'privateoffice':
        spaceType = SpaceType.privateOffice;
        break;
      case 'coworking':
        spaceType = SpaceType.coworking;
        break;
      case 'studio':
        spaceType = SpaceType.studio;
        break;
      default:
        spaceType = SpaceType.openSpace;
    }

    return SpaceModel(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: descText,
      maxPersons: _toInt(json['capacity'] ?? json['maxPersons'], fallback: 1),
      pricePerHour: _toDouble(
        json['hourlyRate'] ??
            json['hourly_rate'] ??
            json['price_per_hour'] ??
            json['pricePerHour'],
      ),
      pricePerDay: _toDouble(
        json['dailyRate'] ??
            json['daily_rate'] ??
            json['price_per_day'] ??
            json['pricePerDay'],
      ),
      pricePerMonth: _toDouble(
        json['monthlyRate'] ??
            json['monthly_rate'] ??
            json['price_per_month'] ??
            json['pricePerMonth'],
      ),
      equipments: equipmentList,
      type: spaceType,
      isAvailable: (json['availability_status'] == 'Disponible') ||
          (json['status'] == 'Disponible') ||
          json['isAvailable'] == true,
      location: json['location'] ?? '',
      floor: json['floor'] ?? '',
      currency: json['currency'] ?? 'TND',
    );
  }
}

class EquipmentModel {
  final String id;
  final String name;
  final double price; // = price_per_day

  const EquipmentModel({
    required this.id,
    required this.name,
    required this.price,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    // Strapi v5 flat — champ prix = price_per_day
    return EquipmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price_per_day'] ??
              json['price'] ??
              json['pricePerSession'] ??
              0)
          .toDouble(),
    );
  }
}

enum SpaceType {
  openSpace,
  meetingRoom,
  privateOffice,
  coworking,
  studio,
}

extension SpaceTypeExtension on SpaceType {
  String get label {
    switch (this) {
      case SpaceType.openSpace:
        return 'Open Space';
      case SpaceType.meetingRoom:
        return 'Salle de Réunion';
      case SpaceType.privateOffice:
        return 'Bureau Privé';
      case SpaceType.coworking:
        return 'Coworking';
      case SpaceType.studio:
        return 'Studio';
    }
  }
}

class ReservationModel {
  final String? id;
  final String spaceId;
  final DateTime date;
  final String? startTime;
  final String? endTime;
  final bool fullDay;
  final int participants;
  final String? userId;
  final ReservationStatus status;

  const ReservationModel({
    this.id,
    required this.spaceId,
    required this.date,
    this.startTime,
    this.endTime,
    required this.fullDay,
    required this.participants,
    this.userId,
    this.status = ReservationStatus.pending,
  });

  Map<String, dynamic> toJson() {
    final dateStr = date.toIso8601String().split('T').first;
    final startDt =
        fullDay ? '${dateStr}T09:00:00.000' : '${dateStr}T${startTime}:00.000';
    final endDt =
        fullDay ? '${dateStr}T18:00:00.000' : '${dateStr}T${endTime}:00.000';
    return {
      'data': {
        'space': spaceId,
        'start_datetime': startDt,
        'end_datetime': endDt,
        'is_all_day': fullDay,
        'attendees': participants,
        'mystatus': 'En_attente',
      }
    };
  }
}

enum ReservationStatus { pending, confirmed, cancelled }
