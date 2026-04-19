import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_getx_app/app/data/services/assistant_chat_service.dart';

class _FakeAssistantApiClient implements AssistantChatApiClient {
  Map<String, dynamic> response = <String, dynamic>{
    'reply': 'Réponse test',
    'question': '',
    'session': <String, dynamic>{'role': 'ETUDIANT'},
    'options': <String>['Option A'],
  };

  String? lastMessage;
  Map<String, dynamic>? lastSession;
  List<Map<String, String>>? lastHistory;
  String? lastProfile;
  String? lastSystemPrompt;

  @override
  Future<Map<String, dynamic>> chatWithSunspaceAssistant({
    required String message,
    Map<String, dynamic>? session,
    List<Map<String, String>>? history,
    String? profile,
    String? systemPrompt,
  }) async {
    lastMessage = message;
    lastSession = session;
    lastHistory = history;
    lastProfile = profile;
    lastSystemPrompt = systemPrompt;
    return response;
  }
}

void main() {
  group('AssistantChatService', () {
    test('injecte le bon system prompt selon le profil', () async {
      final fakeApi = _FakeAssistantApiClient();
      final service = AssistantChatService(
        apiClient: fakeApi,
        streamStepDelay: Duration.zero,
      );

      await service.sendMessage(
        history: const <AssistantMessage>[],
        userMessage: 'Bonjour',
        profile: AssistantProfile.enseignant,
        session: const <String, dynamic>{},
      );

      expect(fakeApi.lastProfile, equals('ENSEIGNANT'));
      expect(fakeApi.lastSystemPrompt, isNotNull);
      expect(fakeApi.lastSystemPrompt!.toLowerCase(), contains('enseignant'));
    });

    test('passe l\'historique complet à l\'API', () async {
      final fakeApi = _FakeAssistantApiClient();
      final service = AssistantChatService(
        apiClient: fakeApi,
        streamStepDelay: Duration.zero,
      );

      final history = <AssistantMessage>[
        const AssistantMessage(
          role: AssistantMessageRole.user,
          text: 'Message 1',
        ),
        const AssistantMessage(
          role: AssistantMessageRole.assistant,
          text: 'Réponse 1',
        ),
      ];

      await service.sendMessage(
        history: history,
        userMessage: 'Message 2',
        profile: AssistantProfile.etudiant,
        session: const <String, dynamic>{},
      );

      expect(fakeApi.lastHistory, isNotNull);
      expect(fakeApi.lastHistory!.length, equals(3));
      expect(fakeApi.lastHistory!.first['role'], equals('system'));
      expect(fakeApi.lastHistory![1]['text'], equals('Message 1'));
      expect(fakeApi.lastHistory![2]['text'], equals('Réponse 1'));
    });

    test('stream la réponse progressivement', () async {
      final fakeApi = _FakeAssistantApiClient();
      fakeApi.response = <String, dynamic>{
        'reply': 'Salut',
        'question': 'Comment puis-je aider ?',
        'session': <String, dynamic>{'role': 'PROFESSIONNEL'},
        'options': <String>['Voir les espaces'],
      };

      final service = AssistantChatService(
        apiClient: fakeApi,
        streamStepDelay: Duration.zero,
      );

      final chunks = <String>[];

      final result = await service.sendMessage(
        history: const <AssistantMessage>[],
        userMessage: 'Hello',
        profile: AssistantProfile.professionnel,
        session: const <String, dynamic>{},
        onStreamChunk: (partial) {
          chunks.add(partial);
        },
      );

      expect(chunks, isNotEmpty);
      expect(chunks.first.length, equals(1));
      expect(chunks.last, equals(result.answer));
      expect(result.answer, contains('Comment puis-je aider ?'));
    });
  });
}
