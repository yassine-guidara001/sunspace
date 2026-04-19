import 'dart:async';

import 'package:flutter_getx_app/app/data/services/communication_api.dart';

enum AssistantProfile { etudiant, enseignant, professionnel, admin }

enum AssistantMessageRole { system, user, assistant }

class AssistantMessage {
  final AssistantMessageRole role;
  final String text;

  const AssistantMessage({
    required this.role,
    required this.text,
  });

  Map<String, String> toJson() {
    return {
      'role': role.name,
      'text': text,
    };
  }
}

class AssistantChatState {
  final List<AssistantMessage> history;
  final AssistantProfile? activeProfile;
  final bool isLoading;
  final String? errorMessage;

  const AssistantChatState({
    required this.history,
    required this.activeProfile,
    required this.isLoading,
    required this.errorMessage,
  });
}

class AssistantChatResult {
  final String answer;
  final Map<String, dynamic> session;
  final List<String> options;
  final Map<String, dynamic> contextData;

  const AssistantChatResult({
    required this.answer,
    required this.session,
    required this.options,
    required this.contextData,
  });
}

abstract class AssistantChatApiClient {
  Future<Map<String, dynamic>> chatWithSunspaceAssistant({
    required String message,
    Map<String, dynamic>? session,
    List<Map<String, String>>? history,
    String? profile,
    String? systemPrompt,
  });
}

class CommunicationApiAssistantClient implements AssistantChatApiClient {
  final CommunicationApi _api;

  CommunicationApiAssistantClient(this._api);

  @override
  Future<Map<String, dynamic>> chatWithSunspaceAssistant({
    required String message,
    Map<String, dynamic>? session,
    List<Map<String, String>>? history,
    String? profile,
    String? systemPrompt,
  }) {
    return _api.chatWithSunspaceAssistant(
      message: message,
      session: session,
      history: history,
      profile: profile,
      systemPrompt: systemPrompt,
    );
  }
}

class AssistantChatService {
  final AssistantChatApiClient _apiClient;
  final Duration streamStepDelay;

  static const List<String> _limitationMarkers = <String>[
    'depasse mes fonctionnalites',
    'dépasse mes fonctionnalités',
    'fonctionnalites actuelles',
    'fonctionnalités actuelles',
    'contacter notre equipe',
    'contacter notre équipe',
    'je ne peux pas',
    'je ne suis pas capable',
  ];

  AssistantChatService({
    required AssistantChatApiClient apiClient,
    this.streamStepDelay = const Duration(milliseconds: 12),
  }) : _apiClient = apiClient;

  List<String> resolveQuickOptions({
    required List<String> options,
    required Map<String, dynamic> contextData,
    required AssistantProfile profile,
  }) {
    final merged = <String>[
      ...options,
      ..._extractOptionsFromContext(contextData),
    ];

    final dedup = <String>[];
    final seen = <String>{};
    for (final item in merged) {
      final normalized = _normalizeOption(item);
      if (normalized.isEmpty || seen.contains(normalized)) continue;
      seen.add(normalized);
      dedup.add(item.trim());
    }

    if (dedup.isNotEmpty) return dedup;
    return _fallbackOptionsForProfile(profile);
  }

  String resolveAnswer({
    required String answer,
    required AssistantProfile profile,
    required List<String> quickOptions,
  }) {
    final trimmed = answer.trim();
    if (trimmed.isEmpty) {
      return 'Je suis pret a vous guider pas a pas. Choisissez une action ci-dessous ou decrivez votre objectif.';
    }

    if (!_isLimitationAnswer(trimmed)) return trimmed;

    final profileHint = switch (profile) {
      AssistantProfile.etudiant =>
        'reservations, cours publies, devoirs et sessions en ligne',
      AssistantProfile.enseignant =>
        'sessions, classes, inscriptions et suivi des soumissions de devoirs',
      AssistantProfile.professionnel =>
        'espaces, planning, disponibilites et organisation',
      AssistantProfile.admin =>
        'supervision des reservations, suivi des demandes en attente et pilotage operationnel quotidien',
    };

    final nextAction = quickOptions.isNotEmpty
        ? 'Choisissez une proposition ci-dessous pour continuer immediatement.'
        : 'Donnez un objectif concret (date, capacite, type de besoin) et je vous proposerai un plan d action.';

    return 'Cette demande est complexe, mais je peux tout de meme vous aider sur $profileHint. $nextAction';
  }

  static String profileLabel(AssistantProfile profile) {
    switch (profile) {
      case AssistantProfile.etudiant:
        return 'Étudiant';
      case AssistantProfile.enseignant:
        return 'Enseignant / Formateur';
      case AssistantProfile.professionnel:
        return 'Professionnel';
      case AssistantProfile.admin:
        return 'Admin';
    }
  }

  static String profileApiValue(AssistantProfile profile) {
    switch (profile) {
      case AssistantProfile.etudiant:
        return 'ETUDIANT';
      case AssistantProfile.enseignant:
        return 'ENSEIGNANT';
      case AssistantProfile.professionnel:
        return 'PROFESSIONNEL';
      case AssistantProfile.admin:
        return 'ADMIN';
    }
  }

  static String systemPromptForProfile(AssistantProfile profile) {
    switch (profile) {
      case AssistantProfile.etudiant:
        return 'Vous êtes l\'assistant SunSpace pour un profil Étudiant. Priorisez les réservations de salles, les cours publiés, les devoirs et les sessions en ligne. Réponses brèves, concrètes, orientées action.';
      case AssistantProfile.enseignant:
        return 'Vous êtes l\'assistant SunSpace pour un profil Enseignant/Formateur. Priorisez la gestion des formations, des sessions, des inscriptions étudiantes et des soumissions de devoirs. Réponses structurées avec prochaines actions.';
      case AssistantProfile.professionnel:
        return 'Vous êtes l\'assistant SunSpace pour un profil Professionnel. Priorisez les espaces de travail, les événements et le networking. Réponses orientées disponibilité, coût et prise de décision.';
      case AssistantProfile.admin:
        return 'Vous êtes l\'assistant SunSpace pour un profil Admin. Priorisez le suivi des nouvelles réservations, la supervision des demandes en attente et la coordination opérationnelle. Réponses courtes, factuelles et orientées décision.';
    }
  }

  AssistantProfile? profileFromSession(Map<String, dynamic> session) {
    final role = (session['role'] ?? '').toString().trim().toUpperCase();
    if (role == 'ETUDIANT') return AssistantProfile.etudiant;
    if (role == 'ENSEIGNANT') return AssistantProfile.enseignant;
    if (role == 'PROFESSIONNEL') return AssistantProfile.professionnel;
    if (role == 'ADMIN') return AssistantProfile.admin;
    return null;
  }

  List<Map<String, String>> buildApiHistory({
    required List<AssistantMessage> history,
    required AssistantProfile profile,
  }) {
    return <Map<String, String>>[
      {
        'role': AssistantMessageRole.system.name,
        'text': systemPromptForProfile(profile),
      },
      ...history.map((item) => item.toJson()),
    ];
  }

  Future<AssistantChatResult> sendMessage({
    required List<AssistantMessage> history,
    required String userMessage,
    required AssistantProfile profile,
    Map<String, dynamic>? session,
    FutureOr<void> Function(String partialText)? onStreamChunk,
  }) async {
    final profilePrompt = systemPromptForProfile(profile);

    final result = await _apiClient.chatWithSunspaceAssistant(
      message: userMessage,
      session: session,
      history: buildApiHistory(history: history, profile: profile),
      profile: profileApiValue(profile),
      systemPrompt: profilePrompt,
    );

    final reply = (result['reply'] ?? '').toString().trim();
    final question = (result['question'] ?? '').toString().trim();
    final rawAnswer =
        question.isNotEmpty ? '$reply\n\n$question'.trim() : reply;
    final contextData = result['contextData'] is Map
        ? Map<String, dynamic>.from(result['contextData'] as Map)
        : <String, dynamic>{};
    final options = resolveQuickOptions(
      options: _asStringList(result['options']),
      contextData: contextData,
      profile: profile,
    );
    final answer = resolveAnswer(
      answer: rawAnswer,
      profile: profile,
      quickOptions: options,
    );

    if (onStreamChunk != null && answer.isNotEmpty) {
      for (var index = 1; index <= answer.length; index += 1) {
        await onStreamChunk(answer.substring(0, index));
        if (streamStepDelay > Duration.zero) {
          await Future<void>.delayed(streamStepDelay);
        }
      }
    }

    return AssistantChatResult(
      answer: answer,
      session: result['session'] is Map
          ? Map<String, dynamic>.from(result['session'] as Map)
          : <String, dynamic>{},
      options: options,
      contextData: contextData,
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _extractOptionsFromContext(Map<String, dynamic> contextData) {
    final options = <String>[];

    final hasSpaces = (contextData['spaces'] is List) ||
        (contextData['spacesByDate'] is List);
    if (hasSpaces) {
      options.addAll(const <String>[
        'Voir les espaces disponibles',
        'Reserver une salle equipee',
      ]);
    }

    final nextActions = contextData['nextActions'];
    if (nextActions is List) {
      for (final item in nextActions) {
        final action = item.toString().trim();
        if (action.isNotEmpty) options.add(action);
      }
    }

    return options;
  }

  List<String> _fallbackOptionsForProfile(AssistantProfile profile) {
    switch (profile) {
      case AssistantProfile.etudiant:
        return const <String>[
          'Voir les espaces disponibles aujourd hui',
          'Reserver une salle d etude',
          'Donner les devoirs publies',
          'Donner les cours publies',
          'Donner les sessions de formation en ligne disponibles',
        ];
      case AssistantProfile.enseignant:
        return const <String>[
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Planifier une session de formation',
          'Voir les espaces disponibles',
          'Donner les cours publies',
          'Donner les devoirs publies',
        ];
      case AssistantProfile.professionnel:
        return const <String>[
          'Voir les espaces disponibles',
          'Reserver une salle equipee',
          'Planifier une session de formation',
          'Contacter l equipe support',
        ];
      case AssistantProfile.admin:
        return const <String>[
          'Quelles sont les nouvelles reservations pour aujourd hui ?',
          'Donner la liste des reservations en attente',
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Voir les espaces disponibles',
          'Planifier une session de formation',
        ];
    }
  }

  String _normalizeOption(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _isLimitationAnswer(String value) {
    final normalized = _normalizeOption(value);
    return _limitationMarkers.any(normalized.contains);
  }
}
