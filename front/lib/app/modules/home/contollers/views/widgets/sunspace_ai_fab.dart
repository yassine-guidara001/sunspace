import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/services/communication_api.dart';
import 'package:get/get.dart';

class SunspaceAiFab extends StatefulWidget {
  const SunspaceAiFab({super.key});

  @override
  State<SunspaceAiFab> createState() => _SunspaceAiFabState();
}

class _SunspaceAiFabState extends State<SunspaceAiFab> {
  static const Color _border = Color(0xFFE2E8F0);

  final CommunicationApi _api = CommunicationApi();
  final StorageService _storageService = Get.find<StorageService>();

  String _resolveRole() {
    final userData = _storageService.getUserData();
    if (userData == null) return '';

    final rawRole = userData['role'];
    if (rawRole is String) {
      return rawRole.toLowerCase().trim();
    }

    if (rawRole is Map) {
      return (rawRole['name'] ?? rawRole['type'] ?? '')
          .toString()
          .toLowerCase();
    }

    return '';
  }

  String _assistantProfileFromCurrentUserRole() {
    final role = _resolveRole();
    if (role.contains('admin') || role.contains('administrateur')) {
      return 'ADMIN';
    }
    if (role.contains('enseignant') ||
        role.contains('teacher') ||
        role.contains('formateur')) {
      return 'ENSEIGNANT';
    }
    if (role.contains('professionnel') || role.contains('professional')) {
      return 'PROFESSIONNEL';
    }
    return 'ETUDIANT';
  }

  String _welcomeMessageForProfile(String profile) {
    switch (profile) {
      case 'ADMIN':
        return 'Bienvenue administrateur! Je vous accompagne pour suivre l activite du jour, prioriser les demandes et piloter les actions critiques.';
      case 'ENSEIGNANT':
        return 'Bienvenue enseignant! Je peux vous aider a suivre vos cours, vos devoirs et la dynamique de vos classes. Que souhaitez-vous analyser en priorite?';
      case 'PROFESSIONNEL':
        return 'Bienvenue professionnel! Je suis ici pour vous aider a reserver des espaces, planifier vos evenements et gerer vos disponibilites. Comment puis-je vous aider?';
      case 'ETUDIANT':
      default:
        return 'Bienvenue etudiant! Je peux vous aider a planifier vos reservations, suivre vos cours publies et reperer les devoirs actifs. Que souhaitez-vous faire en priorite?';
    }
  }

  List<String> _starterPromptsForProfile(String profile) {
    switch (profile) {
      case 'ADMIN':
        return const <String>[
          'Quelles sont les nouvelles reservations pour aujourd hui ?',
          'Donner la liste des reservations en attente',
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Voir les espaces disponibles',
          'Planifier une session de formation',
        ];
      case 'ENSEIGNANT':
        return const <String>[
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Planifier une session de formation',
          'Voir les espaces disponibles',
          'Donner les cours publies',
          'Consulter les inscriptions',
        ];
      case 'PROFESSIONNEL':
        return const <String>[
          'Voir les espaces disponibles',
          'Reserver une salle equipee',
          'Planifier une session de formation',
          'Contacter l equipe support',
          'Voir mes reservations',
          'Demander un equipement special',
        ];
      case 'ETUDIANT':
      default:
        return const <String>[
          'Voir les espaces disponibles aujourd hui',
          'Reserver une salle d etude',
          'Donner les cours publies',
          'Donner les sessions publiees par les enseignants',
          'Donner les devoirs publies',
          'Donner les sessions de formation en ligne disponibles',
          'Consulter le catalogue de formations',
        ];
    }
  }

  List<Map<String, dynamic>> _extractSpaceChoices(dynamic value) {
    final choices = <Map<String, dynamic>>[];
    if (value is Map && value['spaces'] is List) {
      for (final item in value['spaces'] as List) {
        if (item is Map) {
          choices.add(Map<String, dynamic>.from(item));
        }
      }
    }

    if (choices.isNotEmpty) return choices;

    if (value is Map && value['spacesByDate'] is List) {
      for (final group in value['spacesByDate'] as List) {
        if (group is! Map) continue;
        final date = group['date']?.toString().trim();
        final spaces = group['spaces'];
        if (spaces is! List) continue;
        for (final item in spaces) {
          if (item is! Map) continue;
          final space = Map<String, dynamic>.from(item);
          if ((space['date']?.toString().trim() ?? '').isEmpty &&
              (date ?? '').isNotEmpty) {
            space['date'] = date;
          }
          choices.add(space);
        }
      }
    }

    return choices;
  }

  String _spaceSelectionToken(Map<String, dynamic> space) {
    final id = space['id']?.toString().trim() ?? '';
    final date = space['date']?.toString().trim() ?? '';
    return '__SPACE_SELECT__|$id|$date';
  }

  String _spaceChipLabel(Map<String, dynamic> space) {
    final name = space['name']?.toString().trim() ?? 'Espace';
    final capacity = space['capacity']?.toString().trim() ?? '';
    final date = space['date']?.toString().trim() ?? '';
    final parts = <String>[name];
    if (capacity.isNotEmpty) parts.add('$capacity pers.');
    if (date.isNotEmpty) parts.add(date);
    return parts.join(' • ');
  }

  Widget _buildSpaceChoices(
    List<Map<String, dynamic>> choices,
    bool isLoading,
    Future<void> Function(String) onSelect,
  ) {
    if (choices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez un espace',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: choices
                .take(8)
                .map(
                  (space) => ActionChip(
                    label: Text(_spaceChipLabel(space)),
                    onPressed: isLoading
                        ? null
                        : () => onSelect(_spaceSelectionToken(space)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.length > 300) {
      return '${raw.substring(0, 300)}...';
    }
    return raw.isEmpty ? 'Erreur inattendue.' : raw;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  Future<void> _openAssistantBottomSheet() async {
    final inputCtrl = TextEditingController();
    final messages = <Map<String, String>>[];
    final quickOptions = <String>[];
    List<Map<String, dynamic>> spaceChoices = <Map<String, dynamic>>[];
    Map<String, dynamic> contextData = <String, dynamic>{};
    Map<String, dynamic> session = <String, dynamic>{};
    bool isLoading = false;
    bool initialized = false;
    final activeProfile = _assistantProfileFromCurrentUserRole();

    Future<void> sendMessage(StateSetter setModalState, String text) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || isLoading) return;

      setModalState(() {
        messages.add({'from': 'user', 'text': trimmed});
        inputCtrl.clear();
        quickOptions.clear();
        isLoading = true;
      });

      try {
        final result = await _api.chatWithSunspaceAssistant(
          message: trimmed,
          session: session,
          profile: activeProfile,
        );

        final reply = (result['reply'] ?? '').toString().trim();
        final question = (result['question'] ?? '').toString().trim();
        final answer =
            question.isNotEmpty ? '$reply\n\n$question'.trim() : reply;

        setModalState(() {
          session = result['session'] is Map
              ? Map<String, dynamic>.from(result['session'] as Map)
              : <String, dynamic>{};
          contextData = result['contextData'] is Map
              ? Map<String, dynamic>.from(result['contextData'] as Map)
              : <String, dynamic>{};
          spaceChoices = _extractSpaceChoices(contextData);
          quickOptions
            ..clear()
            ..addAll(_asStringList(result['options']));
          if (answer.isNotEmpty) {
            messages.add({'from': 'assistant', 'text': answer});
          }
          isLoading = false;
        });
      } catch (e) {
        setModalState(() => isLoading = false);
        _showError(_friendlyError(e));
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            if (!initialized) {
              initialized = true;
              setModalState(() {
                messages.clear();
                quickOptions
                  ..clear()
                  ..addAll(_starterPromptsForProfile(activeProfile));
                messages.add({
                  'from': 'assistant',
                  'text': _welcomeMessageForProfile(activeProfile),
                });
                isLoading = false;
              });
            }

            return SafeArea(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F766E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Assistant SunSpace',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: messages.isEmpty
                            ? const Center(
                                child: Text(
                                  'Initialisation de l\'assistant...',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              )
                            : ListView.separated(
                                itemCount: messages.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  final item = messages[index];
                                  final isUser = item['from'] == 'user';
                                  return Align(
                                    alignment: isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isUser
                                            ? const Color(0xFFEAF2FF)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: _border),
                                      ),
                                      child: Text(
                                        item['text'] ?? '',
                                        style: const TextStyle(height: 1.35),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (quickOptions.isNotEmpty && spaceChoices.isEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: quickOptions
                            .map(
                              (option) => ActionChip(
                                label: Text(option),
                                onPressed: isLoading
                                    ? null
                                    : () => sendMessage(setModalState, option),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    _buildSpaceChoices(
                      spaceChoices,
                      isLoading,
                      (value) => sendMessage(setModalState, value),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: inputCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Posez votre question...',
                              isDense: true,
                              filled: true,
                              fillColor: Color(0xFFF8FAFC),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: _border),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: _border),
                              ),
                            ),
                            onSubmitted: (value) =>
                                sendMessage(setModalState, value),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 42,
                          child: ElevatedButton.icon(
                            onPressed: isLoading
                                ? null
                                : () => sendMessage(
                                    setModalState, inputCtrl.text.trim()),
                            icon: isLoading
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 16),
                            label: const Text('Envoyer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F766E),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    inputCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _openAssistantBottomSheet,
      backgroundColor: const Color(0xFF0F766E),
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      tooltip: 'Assistant IA SunSpace',
      child: const Icon(Icons.auto_awesome),
    );
  }
}
