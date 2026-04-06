enum SessionType {
  online,
  presential,
  hybrid,
}

extension SessionTypeX on SessionType {
  String get label {
    switch (this) {
      case SessionType.online:
        return 'En ligne';
      case SessionType.presential:
        return 'Présentiel';
      case SessionType.hybrid:
        return 'Hybride';
    }
  }

  String get apiValue {
    switch (this) {
      case SessionType.online:
        return 'En_ligne';
      case SessionType.presential:
        return 'Présentiel';
      case SessionType.hybrid:
        return 'Hybride';
    }
  }

  static SessionType fromAny(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw.contains('présentiel') || raw.contains('presentiel')) {
      return SessionType.presential;
    }
    if (raw.contains('hybride') || raw.contains('hybrid')) {
      return SessionType.hybrid;
    }
    return SessionType.online;
  }
}

enum SessionStatus {
  planned,
  inProgress,
  completed,
  cancelled,
}

extension SessionStatusX on SessionStatus {
  String get label {
    switch (this) {
      case SessionStatus.planned:
        return 'Planifiée';
      case SessionStatus.inProgress:
        return 'En cours';
      case SessionStatus.completed:
        return 'Terminée';
      case SessionStatus.cancelled:
        return 'Annulée';
    }
  }

  String get apiValue {
    switch (this) {
      case SessionStatus.planned:
        return 'Planifiée';
      case SessionStatus.inProgress:
        return 'En cours';
      case SessionStatus.completed:
        return 'Terminée';
      case SessionStatus.cancelled:
        return 'Annulée';
    }
  }

  static SessionStatus fromAny(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();
    if (raw.contains('cours') || raw.contains('progress')) {
      return SessionStatus.inProgress;
    }
    if (raw.contains('termin') || raw.contains('completed')) {
      return SessionStatus.completed;
    }
    if (raw.contains('annul') || raw.contains('cancel')) {
      return SessionStatus.cancelled;
    }
    return SessionStatus.planned;
  }
}

class Participant {
  final int id;
  final String documentId;
  final String firstname;
  final String lastname;
  final String email;

  const Participant({
    required this.id,
    required this.documentId,
    required this.firstname,
    required this.lastname,
    required this.email,
  });

  String get fullName {
    final name = '$firstname $lastname'.trim();
    return name.isEmpty ? 'Participant' : name;
  }

  factory Participant.fromJson(Map<String, dynamic> json) {
    final data = _extractDataNode(json);
    return Participant(
      id: _toInt(data['id']),
      documentId: (data['documentId'] ?? data['document_id'] ?? '').toString(),
      firstname: (data['firstname'] ?? data['firstName'] ?? '').toString(),
      lastname: (data['lastname'] ?? data['lastName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
    );
  }
}

class TrainingSession {
  final int id;
  final String documentId;
  final String title;
  final int? courseAssociated;
  final String courseLabel;
  final SessionType type;
  final int maxParticipants;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? meetingLink;
  final String? notes;
  final SessionStatus status;
  final List<Participant> participants;
  final DateTime? createdAt;

  const TrainingSession({
    required this.id,
    required this.documentId,
    required this.title,
    required this.courseAssociated,
    required this.courseLabel,
    required this.type,
    required this.maxParticipants,
    required this.startDate,
    required this.endDate,
    required this.meetingLink,
    required this.notes,
    required this.status,
    required this.participants,
    required this.createdAt,
  });

  factory TrainingSession.fromJson(Map<String, dynamic> json) {
    final data = _extractDataNode(json);
    final participantsNode = data['attendees'] ?? data['participants'];
    final participantsData = _extractDataList(participantsNode);
    final courseNode = data['course'] ?? data['courseAssociated'];
    final courseData = _extractDataNodeIfMap(courseNode);

    final courseId = _toIntNullable(data['course']) ??
        _toIntNullable(data['courseAssociated']) ??
        _toIntNullable(courseData?['id']);

    final courseTitle =
        (courseData?['title'] ?? data['courseTitle'] ?? '').toString();

    final parsedParticipants = participantsData
        .map(_participantFromAny)
        .whereType<Participant>()
        .toList();

    return TrainingSession(
      id: _toInt(data['id']),
      documentId: (data['documentId'] ?? data['document_id'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      courseAssociated: courseId,
      courseLabel: courseTitle.isEmpty ? 'Non spécifié' : courseTitle,
      type: SessionTypeX.fromAny(data['type']),
      maxParticipants: _toInt(
          data['max_participants'] ?? data['maxParticipants'],
          fallback: 10),
      startDate: _toDateTime(data['start_datetime'] ?? data['startDate']),
      endDate: _toDateTime(data['end_datetime'] ?? data['endDate']),
      meetingLink:
          _toNullableString(data['meeting_url'] ?? data['meetingLink']),
      notes: _toNullableString(data['notes']),
      status: SessionStatusX.fromAny(data['mystatus'] ?? data['status']),
      participants: parsedParticipants,
      createdAt: _toDateTime(data['createdAt']),
    );
  }

  Map<String, dynamic> toStrapiData() {
    return {
      'title': title,
      'type': type.apiValue,
      'start_datetime': startDate?.toIso8601String(),
      'end_datetime': endDate?.toIso8601String(),
      'max_participants': maxParticipants,
      'meeting_url': (meetingLink ?? '').trim().isEmpty ? null : meetingLink,
      'mystatus': status.apiValue,
      'notes': (notes ?? '').trim().isEmpty ? null : notes,
      'course': courseAssociated,
      'attendees': participants.map((item) => item.id).toList(),
    };
  }

  TrainingSession copyWith({
    int? id,
    String? documentId,
    String? title,
    int? courseAssociated,
    String? courseLabel,
    SessionType? type,
    int? maxParticipants,
    DateTime? startDate,
    DateTime? endDate,
    String? meetingLink,
    String? notes,
    SessionStatus? status,
    List<Participant>? participants,
    DateTime? createdAt,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      title: title ?? this.title,
      courseAssociated: courseAssociated ?? this.courseAssociated,
      courseLabel: courseLabel ?? this.courseLabel,
      type: type ?? this.type,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      meetingLink: meetingLink ?? this.meetingLink,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

Map<String, dynamic> _extractDataNode(Map<String, dynamic> json) {
  if (json.containsKey('data')) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return _extractDataNode(data);
    }
  }

  final attributes = json['attributes'];
  if (attributes is Map<String, dynamic>) {
    return {
      'id': json['id'] ?? attributes['id'],
      'documentId': json['documentId'] ?? json['document_id'],
      ...attributes,
    };
  }

  return json;
}

Map<String, dynamic>? _extractDataNodeIfMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return _extractDataNode(value);
  }
  return null;
}

List<dynamic> _extractDataList(dynamic value) {
  if (value is Map<String, dynamic>) {
    final data = value['data'];
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      return [data];
    }
  }
  if (value is List) {
    return value;
  }
  return const [];
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _toIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String? _toNullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return text;
}

Participant? _participantFromAny(dynamic value) {
  if (value is Map<String, dynamic>) {
    return Participant.fromJson(value);
  }

  final id = _toIntNullable(value);
  if (id == null) return null;

  return Participant(
    id: id,
    documentId: '',
    firstname: '',
    lastname: '',
    email: '',
  );
}
