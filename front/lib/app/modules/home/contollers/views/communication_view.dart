import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_getx_app/app/data/services/assistant_chat_service.dart';
import 'package:flutter_getx_app/app/core/service/storage_service.dart';
import 'package:flutter_getx_app/app/data/services/communication_api.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/home_controller.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/custom_sidebar.dart';
import 'package:flutter_getx_app/app/modules/home/contollers/views/notifications_page.dart';
import 'package:get/get.dart';

class CommunicationView extends StatefulWidget {
  const CommunicationView({super.key});

  @override
  State<CommunicationView> createState() => _CommunicationViewState();
}

class _CommunicationViewState extends State<CommunicationView>
    with SingleTickerProviderStateMixin {
  static const Color _bg = Color(0xFFF1F5F9);
  static const Color _border = Color(0xFFE2E8F0);

  final HomeController _homeController = Get.find<HomeController>();
  final StorageService _storageService = Get.find<StorageService>();
  final CommunicationApi _api = CommunicationApi();
  late final AssistantChatService _assistantChatService;

  late final TabController _tabController;

  final TextEditingController _messageSubjectCtrl = TextEditingController();
  final TextEditingController _messageBodyCtrl = TextEditingController();
  final TextEditingController _threadTitleCtrl = TextEditingController();
  final TextEditingController _threadBodyCtrl = TextEditingController();
  final TextEditingController _threadReplyCtrl = TextEditingController();
  Timer? _similarSearchDebounce;

  bool _isLoading = false;
  String _errorMessage = '';

  List<Map<String, dynamic>> _recipients = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _threads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _similarThreads = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _forumNotifications = <Map<String, dynamic>>[];

  String _recipientGroup = 'Enseignant';
  int? _selectedRecipientId;
  int? _replyThreadId;
  bool _markAsUrgent = false;
  bool _isSendingMessage = false;
  bool _isPostingThread = false;
  bool _isReplying = false;
  bool _isSearchingSimilar = false;
  bool _isImprovingDraft = false;
  bool _isCleaningOldMessages = false;
  bool _isCleaningForumThreads = false;
  bool _isUpdatingStatus = false;
  int? _validatingReplyId;
  String? _reactingKey;
  bool get _isTeacher {
    final role = _resolveRole();
    return role.contains('enseignant') ||
        role.contains('teacher') ||
        role.contains('formateur');
  }

  bool get _isStudent {
    final role = _resolveRole();
    return role.contains('etudiant') ||
        role.contains('student') ||
        role.contains('apprenant') ||
        role.contains('authenticated');
  }

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

  String get _displayName {
    final username = _homeController.currentUsername.value.trim();
    if (username.isNotEmpty && username != 'Utilisateur') {
      return username;
    }

    final email = _homeController.currentEmail.value.trim();
    if (email.isNotEmpty) {
      return email;
    }

    return 'Utilisateur';
  }

  String get _displayInitial {
    return _displayName.isNotEmpty
        ? _displayName.substring(0, 1).toUpperCase()
        : 'U';
  }

  String get _roleLabel {
    if (_isTeacher) return 'Enseignant';
    if (_isStudent) return 'Étudiant';
    return 'Utilisateur';
  }

  AssistantProfile _assistantProfileFromCurrentUserRole() {
    final role = _resolveRole();
    if (role.contains('admin') || role.contains('administrateur')) {
      return AssistantProfile.admin;
    }
    if (role.contains('enseignant') ||
        role.contains('teacher') ||
        role.contains('formateur')) {
      return AssistantProfile.enseignant;
    }
    if (role.contains('professionnel') || role.contains('professional')) {
      return AssistantProfile.professionnel;
    }
    if (role.contains('etudiant') ||
        role.contains('student') ||
        role.contains('apprenant')) {
      return AssistantProfile.etudiant;
    }

    // Fallback pour éviter de bloquer l'utilisateur si le rôle est ambigu.
    return AssistantProfile.etudiant;
  }

  @override
  void initState() {
    super.initState();
    _assistantChatService = AssistantChatService(
      apiClient: CommunicationApiAssistantClient(_api),
    );
    _tabController = TabController(length: 2, vsync: this);
    _recipientGroup = _isTeacher ? 'Étudiant' : 'Enseignant';

    if (_homeController.currentUsername.value == 'Utilisateur' &&
        _homeController.currentEmail.value.trim().isEmpty) {
      Future.microtask(
          () => _homeController.refreshCurrentUserIdentity(force: false));
    }

    _threadTitleCtrl.addListener(_scheduleSimilarSearch);
    _threadBodyCtrl.addListener(_scheduleSimilarSearch);

    Future.microtask(_loadAll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageSubjectCtrl.dispose();
    _messageBodyCtrl.dispose();
    _threadTitleCtrl.dispose();
    _threadBodyCtrl.dispose();
    _threadReplyCtrl.dispose();
    _similarSearchDebounce?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredRecipients {
    return _recipients.where((recipient) {
      final role = (recipient['role'] ?? '').toString().toLowerCase();
      if (_isTeacher) {
        return role.contains('etudiant') || role.contains('student');
      }

      if (_recipientGroup == 'Enseignant') {
        return role.contains('enseignant') ||
            role.contains('teacher') ||
            role.contains('formateur');
      }

      return role.contains('etudiant') ||
          role.contains('student') ||
          role.contains('apprenant');
    }).toList();
  }

  Map<String, dynamic>? get _selectedRecipient {
    if (_selectedRecipientId == null) return null;
    for (final recipient in _filteredRecipients) {
      if (recipient['id'] == _selectedRecipientId) return recipient;
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  int? get _currentUserId => _toInt(_storageService.getUserData()?['id']);

  int? _extractMessageUserId(Map<String, dynamic> message, String field) {
    final direct = _toInt(message[field]);
    if (direct != null) return direct;

    final nestedKey = field == 'senderId' ? 'sender' : 'recipient';
    final nested = message[nestedKey];
    if (nested is Map) {
      return _toInt(nested['id']);
    }

    return null;
  }

  List<Map<String, dynamic>> get _selectedConversationMessages {
    final currentUserId = _currentUserId;
    final otherUserId = _selectedRecipientId;

    if (currentUserId == null || otherUserId == null) {
      return const <Map<String, dynamic>>[];
    }

    return _messages.where((message) {
      final senderId = _extractMessageUserId(message, 'senderId');
      final recipientId = _extractMessageUserId(message, 'recipientId');

      if (senderId == null || recipientId == null) return false;

      final isMeToRecipient =
          senderId == currentUserId && recipientId == otherUserId;
      final isRecipientToMe =
          senderId == otherUserId && recipientId == currentUserId;

      return isMeToRecipient || isRecipientToMe;
    }).toList(growable: false);
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final recipientType =
          _isTeacher ? 'student' : _recipientGroup.toLowerCase();
      final results = await Future.wait([
        _api.getRecipients(type: recipientType),
        _api.getMessages(box: 'all'),
        _api.getThreads(),
        _api.getForumNotifications(),
      ]);

      if (!mounted) return;
      setState(() {
        _recipients = results[0];
        _messages = results[1];
        _threads = results[2];
        _forumNotifications = results[3];

        final recipientStillAvailable = _filteredRecipients
            .any((recipient) => recipient['id'] == _selectedRecipientId);
        if (!recipientStillAvailable) {
          _selectedRecipientId = _filteredRecipients.isNotEmpty
              ? (_filteredRecipients.first['id'] as int?)
              : null;
        }

        if (_replyThreadId == null && _threads.isNotEmpty) {
          _replyThreadId = _threads.first['id'] as int?;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyError(e);
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _reloadCurrentSection() async {
    await _loadAll();
  }

  void _showNotice({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!mounted) return;

    Get.closeAllSnackbars();
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Container(
            height: 24,
            width: 24,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w500,
            fontSize: 12,
            height: 1.25,
          ),
        ),
      ),
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      backgroundColor: backgroundColor,
      borderRadius: 14,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      maxWidth: 620,
      animationDuration: const Duration(milliseconds: 220),
      duration: const Duration(seconds: 3),
      forwardAnimationCurve: Curves.easeOutCubic,
      reverseAnimationCurve: Curves.easeInCubic,
      isDismissible: true,
      shouldIconPulse: false,
    );
  }

  void _showSuccess(String title, String message) {
    _showNotice(
      title: title,
      message: message,
      backgroundColor: const Color(0xFF15803D),
      icon: Icons.check_rounded,
    );
  }

  void _showInfo(String title, String message) {
    _showNotice(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFD97706),
      icon: Icons.info_outline_rounded,
    );
  }

  void _showError(String title, String message) {
    _showNotice(
      title: title,
      message: message,
      backgroundColor: const Color(0xFFB91C1C),
      icon: Icons.error_outline_rounded,
    );
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<String> _removeProfileOptions(List<String> options) {
    final blocked = <String>{
      'etudiant',
      'étudiant',
      'enseignant',
      'enseignant / formateur',
      'formateur',
      'professionnel',
    };

    return options
        .where((item) => !blocked.contains(item.trim().toLowerCase()))
        .toList();
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

  Map<AssistantProfile, Map<String, dynamic>> _questionsByRole() {
    return {
      AssistantProfile.etudiant: {
        'icon': Icons.school_outlined,
        'color': const Color(0xFF0EA5E9),
        'title': 'Espace Étudiant',
        'subtitle': 'Parcours, devoirs et réservations',
        'welcome':
            'Bienvenue étudiant! Je peux vous aider à planifier vos réservations, suivre vos cours publiés et repérer les devoirs actifs. Que souhaitez-vous faire en priorité?',
        'questions': const <String>[
          'Voir les espaces disponibles aujourd hui',
          'Réserver une salle d étude',
          'Donner les cours publiés',
          'Donner les sessions publiées par les enseignants',
          'Donner les devoirs publiés',
          'Donner les sessions de formation en ligne disponibles',
          'Consulter le catalogue de formations',
        ],
      },
      AssistantProfile.enseignant: {
        'icon': Icons.person_outline,
        'color': const Color(0xFF7C3AED),
        'title': 'Espace Enseignant',
        'subtitle': 'Pilotage de vos cours, devoirs et inscriptions',
        'welcome':
            'Bienvenue enseignant! Je peux vous aider a suivre vos cours, vos devoirs et la dynamique de vos classes. Que souhaitez-vous analyser en priorite?',
        'questions': const <String>[
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Planifier une session de formation',
          'Voir les espaces disponibles',
          'Donner les cours publies',
          'Consulter les inscriptions',
        ],
      },
      AssistantProfile.professionnel: {
        'icon': Icons.business_center_outlined,
        'color': const Color(0xFFF59E0B),
        'title': 'Espace Professionnel',
        'subtitle': 'Gestion de vos événements et réunions',
        'welcome':
            'Bienvenue professionnel! Je suis ici pour vous aider à réserver des espaces, planifier vos événements et gérer vos disponibilités. Comment puis-je vous aider?',
        'questions': const <String>[
          'Voir les espaces disponibles',
          'Réserver une salle équipée',
          'Planifier une session de formation',
          'Contacter l équipe support',
          'Voir mes réservations',
          'Demander un équipement spécial',
        ],
      },
      AssistantProfile.admin: {
        'icon': Icons.admin_panel_settings_outlined,
        'color': const Color(0xFF0F766E),
        'title': 'Espace Admin',
        'subtitle': 'Supervision des reservations et operations',
        'welcome':
            'Bienvenue administrateur! Je vous accompagne pour suivre l activite du jour, prioriser les demandes et piloter les actions critiques.',
        'questions': const <String>[
          'Quelles sont les nouvelles reservations pour aujourd hui ?',
          'Donner la liste des reservations en attente',
          'Quelle est la liste des etudiants inscrits a nos cours ?',
          'Y a-t-il des etudiants qui ont soumis des devoirs ?',
          'Voir les espaces disponibles',
          'Planifier une session de formation',
          'Consulter les inscriptions',
          'Donner les sessions de formation en ligne disponibles',
        ],
      },
    };
  }

  List<String> _starterPromptsForProfile(AssistantProfile profile) {
    return (_questionsByRole()[profile]?['questions'] as List<String>?) ??
        const <String>[];
  }

  String _welcomeMessageForProfile(AssistantProfile profile) {
    return (_questionsByRole()[profile]?['welcome'] as String?) ??
        'Bonjour! Comment puis-je vous aider?';
  }

  Future<void> _openAssistantBottomSheet() async {
    final inputCtrl = TextEditingController();
    final messages = <AssistantMessage>[];
    final quickOptions = <String>[];
    List<Map<String, dynamic>> spaceChoices = <Map<String, dynamic>>[];
    Map<String, dynamic> session = <String, dynamic>{};
    AssistantProfile? activeProfile = _assistantProfileFromCurrentUserRole();
    bool isLoading = false;
    bool isStreaming = false;
    bool initialized = false;
    String? inlineError;
    String? lastFailedUserMessage;

    AssistantProfile? detectProfileFromText(String raw) {
      final text = raw.trim().toLowerCase();
      if (text.isEmpty) return null;
      if (text.contains('etudiant') || text.contains('étudiant')) {
        return AssistantProfile.etudiant;
      }
      if (text.contains('enseignant') || text.contains('formateur')) {
        return AssistantProfile.enseignant;
      }
      if (text.contains('professionnel')) {
        return AssistantProfile.professionnel;
      }
      if (text.contains('admin') || text.contains('administrateur')) {
        return AssistantProfile.admin;
      }
      return null;
    }

    Future<void> initializeAssistant(StateSetter setModalState) async {
      // Afficher immédiatement la salutation personnalisée au rôle de l'utilisateur
      setModalState(() {
        isLoading = false;
        inlineError = null;
        messages.clear();
        activeProfile = _assistantProfileFromCurrentUserRole();
        quickOptions
          ..clear()
          ..addAll(_starterPromptsForProfile(activeProfile!));
        // Ajouter le message de bienvenue du rôle
        messages.add(
          AssistantMessage(
            role: AssistantMessageRole.assistant,
            text: _welcomeMessageForProfile(activeProfile!),
          ),
        );
      });
    }

    Future<void> sendMessage(
      StateSetter setModalState,
      String text, {
      bool appendUserMessage = true,
    }) async {
      final trimmed = text.trim();
      if (trimmed.isEmpty || isLoading) return;

      final requestedProfile = detectProfileFromText(trimmed);
      if (requestedProfile != null) {
        activeProfile = requestedProfile;
      }

      activeProfile ??= _assistantProfileFromCurrentUserRole();

      final historyBeforeRequest = List<AssistantMessage>.from(messages);
      var streamMessageIndex = -1;

      setModalState(() {
        if (appendUserMessage) {
          messages.add(
            AssistantMessage(
              role: AssistantMessageRole.user,
              text: trimmed,
            ),
          );
          inputCtrl.clear();
        }
        messages.add(
          const AssistantMessage(
            role: AssistantMessageRole.assistant,
            text: '',
          ),
        );
        streamMessageIndex = messages.length - 1;
        quickOptions.clear();
        isLoading = true;
        isStreaming = true;
        inlineError = null;
        lastFailedUserMessage = null;
      });

      try {
        final result = await _assistantChatService.sendMessage(
          history: historyBeforeRequest,
          userMessage: trimmed,
          profile: activeProfile!,
          session: session,
          onStreamChunk: (partial) {
            if (!mounted || streamMessageIndex < 0) return;
            setModalState(() {
              messages[streamMessageIndex] = AssistantMessage(
                role: AssistantMessageRole.assistant,
                text: partial,
              );
            });
          },
        );

        setModalState(() {
          session = result.session;
          activeProfile = _assistantChatService.profileFromSession(session) ??
              _assistantProfileFromCurrentUserRole();
          spaceChoices = _extractSpaceChoices(result.contextData);
          quickOptions
            ..clear()
            ..addAll(_removeProfileOptions(result.options));
          if (result.answer.isEmpty && streamMessageIndex >= 0) {
            messages.removeAt(streamMessageIndex);
          }
          isLoading = false;
          isStreaming = false;
        });
      } catch (e) {
        setModalState(() {
          if (streamMessageIndex >= 0 && streamMessageIndex < messages.length) {
            messages.removeAt(streamMessageIndex);
          }
          isLoading = false;
          isStreaming = false;
          inlineError =
              'Connexion impossible à l\'assistant. Vérifiez le réseau puis réessayez.';
          lastFailedUserMessage = trimmed;
        });
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
              unawaited(initializeAssistant(setModalState));
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assistant SunSpace',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Copilote d actions • ${AssistantChatService.profileLabel(activeProfile!)}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: isLoading
                              ? null
                              : () => initializeAssistant(setModalState),
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: const Text('Réinitialiser'),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (inlineError != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                color: Color(0xFFB91C1C), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                inlineError!,
                                style: const TextStyle(
                                  color: Color(0xFF991B1B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  isLoading || lastFailedUserMessage == null
                                      ? null
                                      : () => sendMessage(
                                            setModalState,
                                            lastFailedUserMessage!,
                                            appendUserMessage: false,
                                          ),
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: (_questionsByRole()[activeProfile]
                                              ?['color'] as Color? ??
                                          const Color(0xFF0EA5E9))
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _questionsByRole()[activeProfile]?['icon']
                                          as IconData? ??
                                      Icons.help_outline,
                                  color: _questionsByRole()[activeProfile]
                                          ?['color'] as Color? ??
                                      const Color(0xFF0EA5E9),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _questionsByRole()[activeProfile]
                                              ?['title'] as String? ??
                                          'Actions',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      _questionsByRole()[activeProfile]
                                              ?['subtitle'] as String? ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _starterPromptsForProfile(activeProfile!)
                                .map(
                                  (prompt) => ActionChip(
                                    label: Text(
                                      prompt,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor:
                                        (_questionsByRole()[activeProfile]
                                                    ?['color'] as Color? ??
                                                const Color(0xFF0EA5E9))
                                            .withValues(alpha: 0.08),
                                    labelStyle: TextStyle(
                                      color: _questionsByRole()[activeProfile]
                                              ?['color'] as Color? ??
                                          const Color(0xFF0EA5E9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    side: BorderSide(
                                      color: (_questionsByRole()[activeProfile]
                                                  ?['color'] as Color? ??
                                              const Color(0xFF0EA5E9))
                                          .withValues(alpha: 0.3),
                                    ),
                                    onPressed: isLoading
                                        ? null
                                        : () =>
                                            sendMessage(setModalState, prompt),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
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
                                itemCount:
                                    messages.length + (isStreaming ? 1 : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (_, index) {
                                  if (isStreaming && index == messages.length) {
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(color: _border),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 12,
                                              height: 12,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Assistant écrit...',
                                              style: TextStyle(
                                                color: Color(0xFF64748B),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  final item = messages[index];
                                  final isUser =
                                      item.role == AssistantMessageRole.user;
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
                                        item.text,
                                        style: const TextStyle(height: 1.35),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                    if (spaceChoices.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: spaceChoices
                            .take(8)
                            .map(
                              (space) => ActionChip(
                                label: Text(_spaceChipLabel(space)),
                                onPressed: isLoading
                                    ? null
                                    : () => sendMessage(
                                          setModalState,
                                          _spaceSelectionToken(space),
                                        ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (quickOptions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_questionsByRole()[activeProfile]?['color']
                                      as Color? ??
                                  const Color(0xFF0EA5E9))
                              .withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (_questionsByRole()[activeProfile]?['color']
                                        as Color? ??
                                    const Color(0xFF0EA5E9))
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: quickOptions
                              .map(
                                (option) => ActionChip(
                                  label: Text(
                                    option,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor:
                                      (_questionsByRole()[activeProfile]
                                                  ?['color'] as Color? ??
                                              const Color(0xFF0EA5E9))
                                          .withValues(alpha: 0.1),
                                  labelStyle: TextStyle(
                                    color: _questionsByRole()[activeProfile]
                                            ?['color'] as Color? ??
                                        const Color(0xFF0EA5E9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  side: BorderSide.none,
                                  onPressed: isLoading
                                      ? null
                                      : () =>
                                          sendMessage(setModalState, option),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    FocusTraversalGroup(
                      child: Row(
                        children: [
                          Expanded(
                            child: Semantics(
                              label: 'Champ de saisie du message assistant',
                              textField: true,
                              child: TextField(
                                controller: inputCtrl,
                                autofocus: true,
                                textInputAction: TextInputAction.send,
                                decoration:
                                    _inputDecoration('Posez votre question...'),
                                onSubmitted: (value) =>
                                    sendMessage(setModalState, value),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => sendMessage(
                                        setModalState,
                                        inputCtrl.text.trim(),
                                      ),
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

  Widget _buildAssistantFab() {
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

  Future<void> _sendPrivateMessage() async {
    final recipient = _selectedRecipient;
    final subject = _messageSubjectCtrl.text.trim();
    var body = _messageBodyCtrl.text.trim();

    if (recipient == null) {
      _showInfo('Précision requise', 'Sélectionnez un destinataire.');
      return;
    }

    if (body.isEmpty) {
      _showInfo('Précision requise', 'Rédigez un message avant l’envoi.');
      return;
    }

    if (_markAsUrgent && !body.toLowerCase().contains('urgent')) {
      body = '[URGENT] $body';
    }

    setState(() => _isSendingMessage = true);
    try {
      await _api.sendMessage(
        recipientId: recipient['id'] as int,
        subject: subject.isEmpty ? null : subject,
        body: body,
      );

      _messageSubjectCtrl.clear();
      _messageBodyCtrl.clear();
      _markAsUrgent = false;
      await _loadAll();
      _showSuccess('Succès', 'Message envoyé avec succès.');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isSendingMessage = false);
      }
    }
  }

  Future<void> _cleanupOldMessages() async {
    final targetRecipient = _selectedRecipientId;
    final recipientLabel = _filteredRecipients
        .firstWhereOrNull((item) => item['id'] == targetRecipient)?['username']
        ?.toString();

    final scopeText = targetRecipient == null
        ? 'de votre messagerie'
        : 'de la conversation avec ${recipientLabel ?? 'ce destinataire'}';

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Nettoyer la conversation'),
            content: Text(
              'Supprimer tous les messages $scopeText ? Cette action est définitive.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _isCleaningOldMessages = true);
    try {
      final result = await _api.deleteMessages(
        recipientId: targetRecipient,
      );
      final deleted = _toInt(result['deleted']) ?? 0;

      await _loadAll();
      _showSuccess(
        'Nettoyage terminé',
        deleted == 0
            ? 'Aucun message à supprimer.'
            : '$deleted message(s) supprimé(s).',
      );
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isCleaningOldMessages = false);
      }
    }
  }

  Future<void> _cleanupOldForumThreads() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Nettoyer le forum'),
            content: const Text(
              'Supprimer les discussions du forum ? Cette action est définitive.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed || !mounted) return;

    setState(() => _isCleaningForumThreads = true);
    try {
      final result = await _api.deleteForumThreads();
      final deleted = _toInt(result['deleted']) ?? 0;
      await _loadAll();

      _showSuccess(
        'Forum nettoyé',
        deleted == 0
            ? 'Aucune discussion à supprimer.'
            : '$deleted discussion(s) supprimée(s).',
      );
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isCleaningForumThreads = false);
      }
    }
  }

  Future<void> _createForumThread() async {
    final title = _threadTitleCtrl.text.trim();
    final body = _threadBodyCtrl.text.trim();

    if (title.isEmpty || body.isEmpty) {
      _showInfo(
          'Précision requise', 'Renseignez un titre et un corps de post.');
      return;
    }

    final tags = _suggestTags('$title $body');

    setState(() => _isPostingThread = true);
    try {
      await _api.createThread(title: title, body: body, tags: tags);
      _threadTitleCtrl.clear();
      _threadBodyCtrl.clear();
      await _loadAll();
      _showSuccess('Succès', 'Discussion publiée.');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isPostingThread = false);
      }
    }
  }

  Future<void> _replyToThread() async {
    final threadId = _replyThreadId;
    final body = _threadReplyCtrl.text.trim();

    if (threadId == null) {
      _showInfo('Précision requise', 'Sélectionnez une discussion.');
      return;
    }

    if (body.isEmpty) {
      _showInfo('Précision requise', 'Rédigez une réponse.');
      return;
    }

    setState(() => _isReplying = true);
    try {
      await _api.replyToThread(threadId: threadId, body: body);
      _threadReplyCtrl.clear();
      await _loadAll();
      _showSuccess('Succès', 'Réponse ajoutée.');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isReplying = false);
      }
    }
  }

  List<String> _suggestTags(String text) {
    final value = text.toLowerCase();

    if (value.contains('devoir') || value.contains('rendu')) {
      return const ['Devoir', 'Question de cours'];
    }
    if (value.contains('examen') || value.contains('test')) {
      return const ['Examen', 'Question de cours'];
    }
    if (value.contains('bug') ||
        value.contains('erreur') ||
        value.contains('connexion')) {
      return const ['Problème technique', 'Autre'];
    }
    if (value.contains('groupe') || value.contains('équipe')) {
      return const ['Travail de groupe', 'Ressource'];
    }
    return const ['Question de cours', 'Autre'];
  }

  void _scheduleSimilarSearch() {
    _similarSearchDebounce?.cancel();
    _similarSearchDebounce = Timer(const Duration(milliseconds: 450), () {
      _searchSimilarThreads();
    });
  }

  Future<void> _searchSimilarThreads() async {
    final text = '${_threadTitleCtrl.text} ${_threadBodyCtrl.text}'.trim();
    if (text.length < 8) {
      if (!mounted) return;
      setState(() {
        _similarThreads = const <Map<String, dynamic>>[];
        _isSearchingSimilar = false;
      });
      return;
    }

    if (mounted) {
      setState(() => _isSearchingSimilar = true);
    }

    try {
      final similar = await _api.getSimilarThreads(text);
      if (!mounted) return;
      setState(() {
        _similarThreads = similar;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _similarThreads = const <Map<String, dynamic>>[];
      });
    } finally {
      if (mounted) {
        setState(() => _isSearchingSimilar = false);
      }
    }
  }

  Future<void> _improvePostDraft() async {
    final title = _threadTitleCtrl.text.trim();
    final body = _threadBodyCtrl.text.trim();

    if (title.isEmpty && body.isEmpty) {
      _showInfo('Brouillon vide', 'Ajoutez un titre ou du contenu d’abord.');
      return;
    }

    setState(() => _isImprovingDraft = true);
    try {
      final improved = await _api.improvePostDraft(title: title, body: body);
      _threadTitleCtrl.text = (improved['title'] ?? title).toString();
      _threadBodyCtrl.text = (improved['body'] ?? body).toString();
      await _searchSimilarThreads();
      final tags = (improved['tags'] as List<dynamic>? ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .join(', ');
      _showSuccess('Post amélioré',
          tags.isEmpty ? 'Texte corrigé avec succès.' : 'Tags suggérés: $tags');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isImprovingDraft = false);
      }
    }
  }

  Future<void> _updateThreadStatus(int threadId, String status) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await _api.updateThreadStatus(threadId: threadId, status: status);
      await _loadAll();
      _showSuccess('Statut mis à jour',
          'Le statut est maintenant ${_statusLabel(status)}.');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _validateReply(int replyId) async {
    setState(() => _validatingReplyId = replyId);
    try {
      await _api.validateReply(replyId: replyId);
      await _loadAll();
      _showSuccess('Validation réussie', 'Réponse validée par l’enseignant.');
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _validatingReplyId = null);
      }
    }
  }

  Future<void> _reactToReply(int replyId, String reactionType) async {
    final key = '$replyId:$reactionType';
    setState(() => _reactingKey = key);
    try {
      await _api.reactToReply(replyId: replyId, reactionType: reactionType);
      await _loadAll();
    } catch (e) {
      _showError('Erreur', _friendlyError(e));
    } finally {
      if (mounted) {
        setState(() => _reactingKey = null);
      }
    }
  }

  String _statusLabel(String rawStatus) {
    final value = rawStatus.trim().toUpperCase();
    if (value == 'RESOLU') return 'RÉSOLU';
    if (value == 'EN_ATTENTE') return 'EN ATTENTE';
    return 'OPEN';
  }

  Color _statusColor(String rawStatus) {
    final value = rawStatus.trim().toUpperCase();
    if (value == 'RESOLU') return const Color(0xFF16A34A);
    if (value == 'EN_ATTENTE') return const Color(0xFFD97706);
    return const Color(0xFF1D4ED8);
  }

  String _roleLabelFromValue(dynamic role) {
    final normalized = role.toString().toLowerCase();
    final teacher = normalized.contains('teacher') ||
        normalized.contains('enseignant') ||
        normalized.contains('formateur');
    return teacher ? 'Enseignant' : 'Étudiant';
  }

  Color _roleColor(String roleLabel) {
    if (roleLabel == 'Enseignant') return const Color(0xFF7C3AED);
    return const Color(0xFF0EA5E9);
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year;
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _friendlyError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('unknown arg') ||
        lower.contains('unknown field') ||
        lower.contains('does not exist') ||
        (lower.contains('prisma') && lower.contains('column'))) {
      return 'Le backend attend des champs Prisma non appliqués en base. Exécutez: npx prisma db push, puis redémarrez le backend.';
    }

    if (raw.length > 1400) {
      return raw.substring(0, 1400);
    }

    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final hideSidebar = screenWidth < 1280;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned(
            top: -80,
            right: -60,
            child: _BackgroundOrb(
              size: 220,
              colors: [Color(0xFFD8EAFE), Color(0xFFF1F5F9)],
            ),
          ),
          const Positioned(
            bottom: -60,
            left: 180,
            child: _BackgroundOrb(
              size: 160,
              colors: [Color(0xFFE9F1FF), Color(0xFFF8FAFC)],
            ),
          ),
          Row(
            children: [
              if (!hideSidebar) const CustomSidebar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final contentIsCompact = constraints.maxWidth < 1000;

                    return Column(
                      children: [
                        _buildTopBar(context, contentIsCompact || hideSidebar),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(contentIsCompact ? 12 : 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(contentIsCompact),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.96),
                                    border: Border.all(color: _border),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x12000000),
                                        blurRadius: 20,
                                        offset: Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: const Color(0xFF0B6BFF),
                                    unselectedLabelColor:
                                        const Color(0xFF64748B),
                                    labelStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                    unselectedLabelStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    indicator: BoxDecoration(
                                      color: const Color(0xFFEAF2FF),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    indicatorPadding: const EdgeInsets.all(6),
                                    splashBorderRadius:
                                        BorderRadius.circular(14),
                                    tabs: const [
                                      Tab(text: 'Messagerie privée'),
                                      Tab(text: 'Forum de discussion'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                if (_errorMessage.trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _BannerMessage(
                                      message: _errorMessage,
                                      onRetry: _reloadCurrentSection,
                                    ),
                                  ),
                                Expanded(
                                  child: _isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator())
                                      : TabBarView(
                                          controller: _tabController,
                                          children: [
                                            _buildMessagingTab(),
                                            _buildForumTab(),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isCompact) {
    return Container(
      height: isCompact ? 56 : 62,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: _border)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isCompact) ...[
            IconButton(
              tooltip: 'Menu',
              onPressed: () => CustomSidebar.openDrawerMenu(context),
              icon: const Icon(Icons.menu, color: Color(0xFF475569)),
            ),
          ],
          const Spacer(),
          const NotificationBell(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    _displayInitial,
                    style: const TextStyle(
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 170),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          _roleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final messageCount = _messages.length;
    final threadCount = _threads.length;
    final contactCount = _filteredRecipients.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Espace de communication',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Communication',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isTeacher
                          ? 'Centralisez les échanges avec vos apprenants, suivez les réponses et gardez le forum actif.'
                          : 'Échangez avec vos enseignants et vos camarades dans un espace clair, rapide et organisé.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.14)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rôle actif',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _roleLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMetricCard(
                icon: Icons.mark_chat_unread_outlined,
                label: 'Messages',
                value: '$messageCount',
              ),
              _buildMetricCard(
                icon: Icons.forum_outlined,
                label: 'Discussions',
                value: '$threadCount',
              ),
              _buildMetricCard(
                icon: Icons.people_outline,
                label: 'Contacts',
                value: '$contactCount',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _surfaceDecoration([Color color = Colors.white]) {
    return BoxDecoration(
      color: color,
      border: Border.all(color: _border),
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0E000000),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF1D4ED8), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF64748B), height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagingTab() {
    final recipientOptions = _filteredRecipients;
    final conversationMessages = _selectedConversationMessages;

    if (_selectedRecipientId == null && recipientOptions.isNotEmpty) {
      _selectedRecipientId = recipientOptions.first['id'] as int?;
    }

    final recipientCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Destinataire',
            'Choisissez la personne à qui écrire et préparez un message clair.',
            Icons.person_search_outlined,
          ),
          const SizedBox(height: 10),
          if (!_isTeacher) ...[
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Enseignant'),
                  selected: _recipientGroup == 'Enseignant',
                  onSelected: (_) {
                    setState(() {
                      _recipientGroup = 'Enseignant';
                      _selectedRecipientId = null;
                    });
                    _loadAll();
                  },
                ),
                ChoiceChip(
                  label: const Text('Étudiant'),
                  selected: _recipientGroup == 'Étudiant',
                  onSelected: (_) {
                    setState(() {
                      _recipientGroup = 'Étudiant';
                      _selectedRecipientId = null;
                    });
                    _loadAll();
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<int>(
            value: _selectedRecipientId,
            decoration: _inputDecoration('Choisir un destinataire'),
            items: recipientOptions
                .map((recipient) => DropdownMenuItem<int>(
                      value: recipient['id'] as int,
                      child: Text(
                        '${recipient['username']} · ${recipient['role']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedRecipientId = value),
          ),
        ],
      ),
    );

    final conversationCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Conversation récentes',
            _selectedRecipientId == null
                ? 'Sélectionnez un destinataire pour afficher son fil de discussion.'
                : conversationMessages.isEmpty
                    ? 'Aucun message avec ce destinataire pour le moment.'
                    : 'Fil privé entre vous et ce destinataire.',
            Icons.mark_chat_read_outlined,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    '${conversationMessages.length} message(s)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed:
                      _isCleaningOldMessages ? null : _cleanupOldMessages,
                  icon: _isCleaningOldMessages
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_sweep_outlined, size: 16),
                  label: const Text('Nettoyer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    side: const BorderSide(color: _border),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final composerCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Composer un message',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageSubjectCtrl,
              decoration: _inputDecoration('Sujet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageBodyCtrl,
              minLines: 4,
              maxLines: 6,
              decoration: _inputDecoration(
                  'Décrivez votre question, devoir, note ou groupe...'),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              value: _markAsUrgent,
              onChanged: (value) {
                setState(() => _markAsUrgent = value ?? false);
              },
              title: const Text('Urgent'),
              subtitle:
                  const Text('Deadline, problème technique, réponse rapide'),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isSendingMessage ? null : _sendPrivateMessage,
                icon: _isSendingMessage
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined, size: 16),
                label: const Text('Envoyer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final messagesCard = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages récents',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedRecipientId == null
                ? const Center(
                    child: Text(
                      'Sélectionnez un destinataire pour voir la conversation.',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : conversationMessages.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun message disponible pour ce destinataire',
                          style: TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.separated(
                        itemCount: conversationMessages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final message = conversationMessages[index];
                          final sender =
                              message['sender'] as Map<String, dynamic>?;
                          final recipient =
                              message['recipient'] as Map<String, dynamic>?;
                          final isIncoming =
                              _extractMessageUserId(message, 'recipientId') ==
                                  _currentUserId;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isIncoming
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFFEAF2FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      sender?['username']?.toString() ??
                                          'Expéditeur',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '→ ${recipient?['username']?.toString() ?? 'Destinataire'}',
                                      style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 12),
                                    ),
                                    const Spacer(),
                                    if (message['isRead'] != true && isIncoming)
                                      const Text('Non lu',
                                          style: TextStyle(
                                              color: Color(0xFFDC2626),
                                              fontSize: 12)),
                                  ],
                                ),
                                if ((message['subject'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    message['subject'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(message['body'].toString()),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1040;

        if (isNarrow) {
          return SingleChildScrollView(
            child: Column(
              children: [
                recipientCard,
                const SizedBox(height: 12),
                conversationCard,
                const SizedBox(height: 12),
                composerCard,
                const SizedBox(height: 12),
                SizedBox(height: 420, child: messagesCard),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: recipientCard),
                const SizedBox(width: 12),
                Expanded(child: conversationCard),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 3, child: composerCard),
                  const SizedBox(width: 12),
                  Expanded(flex: 4, child: messagesCard),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForumTab() {
    final publishCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              'Publier un message forum',
              'Posez une question, partagez une ressource ou démarrez une discussion intelligente.',
              Icons.edit_note_outlined,
            ),
            const SizedBox(height: 10),
            if (_forumNotifications.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notifications forum',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (_forumNotifications.first['title'] ??
                              'Mise à jour forum')
                          .toString(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _threadTitleCtrl,
              decoration: _inputDecoration('Titre du post'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _threadBodyCtrl,
              minLines: 4,
              maxLines: 7,
              decoration: _inputDecoration('Corps du post'),
            ),
            const SizedBox(height: 8),
            Text(
              'Tags suggérés: ${_suggestTags('${_threadTitleCtrl.text} ${_threadBodyCtrl.text}').join(', ')}',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: _isImprovingDraft ? null : _improvePostDraft,
                icon: _isImprovingDraft
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high_outlined, size: 16),
                label: const Text('Améliorer mon post'),
              ),
            ),
            const SizedBox(height: 10),
            if (_isSearchingSimilar)
              const LinearProgressIndicator(minHeight: 2),
            if (_similarThreads.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Discussions similaires détectées',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 120),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _similarThreads.take(3).length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, idx) {
                    final item = _similarThreads.take(3).toList()[idx];
                    final score =
                        ((item['score'] as num?)?.toDouble() ?? 0) * 100;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? 'Discussion',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Similarité ${score.toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ElevatedButton.icon(
                onPressed: _isPostingThread ? null : _createForumThread,
                icon: _isPostingThread
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.publish_outlined, size: 16),
                label: const Text('Publier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B6BFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final discussionsCard = Container(
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Discussions récentes',
            'Vue thread style conversation: statut, réponses, validation et réactions.',
            Icons.forum_outlined,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${_threads.length} discussion(s)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed:
                    _isCleaningForumThreads ? null : _cleanupOldForumThreads,
                icon: _isCleaningForumThreads
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Nettoyer forum'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: _border),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _threads.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune discussion disponible',
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : ListView.separated(
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, index) {
                      final thread = _threads[index];
                      final replies =
                          (thread['replies'] as List<dynamic>? ?? const [])
                              .cast<dynamic>();
                      final tags =
                          (thread['tags'] as List<dynamic>? ?? const [])
                              .map((e) => e.toString())
                              .toList();
                      final selected = _replyThreadId == thread['id'];
                      final threadAuthor =
                          thread['author'] as Map<String, dynamic>?;
                      final threadStatus =
                          (thread['status'] ?? 'OPEN').toString().toUpperCase();
                      final threadDate = DateTime.tryParse(
                              thread['createdAt']?.toString() ?? '')
                          ?.toLocal();

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFEAF2FF)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    thread['title'].toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(threadStatus)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(threadStatus),
                                    style: TextStyle(
                                        color: _statusColor(threadStatus),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (threadAuthor != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _roleColor(_roleLabelFromValue(
                                              threadAuthor['role']))
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${threadAuthor['username']} · ${_roleLabelFromValue(threadAuthor['role'])}',
                                      style: TextStyle(
                                        color: _roleColor(_roleLabelFromValue(
                                            threadAuthor['role'])),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _formatDate(threadDate),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              thread['body'].toString(),
                              style: const TextStyle(
                                color: Color(0xFF334155),
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: tags
                                  .map((tag) => Chip(
                                        label: Text(tag),
                                        backgroundColor: Colors.white,
                                        side: const BorderSide(color: _border),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${replies.length} réponse(s)',
                              style: const TextStyle(
                                  color: Color(0xFF64748B), fontSize: 12),
                            ),
                            const SizedBox(height: 10),
                            if (_isTeacher)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final option in const <String>[
                                    'OPEN',
                                    'EN_ATTENTE',
                                    'RESOLU'
                                  ])
                                    ChoiceChip(
                                      label: Text(_statusLabel(option)),
                                      selected: threadStatus == option,
                                      onSelected: _isUpdatingStatus
                                          ? null
                                          : (_) => _updateThreadStatus(
                                              thread['id'] as int, option),
                                    ),
                                ],
                              ),
                            const SizedBox(height: 10),
                            if (replies.isEmpty)
                              const Text(
                                'Aucune réponse pour le moment.',
                                style: TextStyle(
                                    color: Color(0xFF94A3B8), fontSize: 12),
                              )
                            else
                              Column(
                                children: replies.map((rawReply) {
                                  final reply = Map<String, dynamic>.from(
                                    rawReply as Map,
                                  );
                                  final replyId =
                                      (reply['id'] as num?)?.toInt();
                                  final replyAuthor =
                                      reply['author'] as Map<String, dynamic>?;
                                  final validated =
                                      reply['isValidated'] == true;
                                  final validatedBy = reply['validatedBy']
                                      as Map<String, dynamic>?;
                                  final createdAt = DateTime.tryParse(
                                          reply['createdAt']?.toString() ?? '')
                                      ?.toLocal();
                                  final likeCount =
                                      (reply['likeCount'] as num?)?.toInt() ??
                                          0;
                                  final helpfulCount =
                                      (reply['helpfulCount'] as num?)
                                              ?.toInt() ??
                                          0;

                                  return Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: _border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  Text(
                                                    replyAuthor?['username']
                                                            ?.toString() ??
                                                        'Utilisateur',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: _roleColor(
                                                              _roleLabelFromValue(
                                                                  replyAuthor?[
                                                                      'role']))
                                                          .withValues(
                                                              alpha: 0.14),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      _roleLabelFromValue(
                                                          replyAuthor?['role']),
                                                      style: TextStyle(
                                                        color: _roleColor(
                                                            _roleLabelFromValue(
                                                                replyAuthor?[
                                                                    'role'])),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _formatDate(createdAt),
                                              style: const TextStyle(
                                                color: Color(0xFF94A3B8),
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          reply['body']?.toString() ?? '',
                                          style: const TextStyle(height: 1.35),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: replyId == null ||
                                                      _reactingKey ==
                                                          '$replyId:LIKE'
                                                  ? null
                                                  : () => _reactToReply(
                                                      replyId, 'LIKE'),
                                              icon: const Icon(
                                                  Icons.thumb_up_alt_outlined,
                                                  size: 15),
                                              label: Text('Like $likeCount'),
                                            ),
                                            OutlinedButton.icon(
                                              onPressed: replyId == null ||
                                                      _reactingKey ==
                                                          '$replyId:HELPFUL'
                                                  ? null
                                                  : () => _reactToReply(
                                                      replyId, 'HELPFUL'),
                                              icon: const Icon(
                                                  Icons.star_border,
                                                  size: 15),
                                              label:
                                                  Text('Helpful $helpfulCount'),
                                            ),
                                            if (_isTeacher)
                                              ElevatedButton.icon(
                                                onPressed: (replyId == null ||
                                                        validated ||
                                                        _validatingReplyId ==
                                                            replyId)
                                                    ? null
                                                    : () =>
                                                        _validateReply(replyId),
                                                icon: _validatingReplyId ==
                                                        replyId
                                                    ? const SizedBox(
                                                        width: 12,
                                                        height: 12,
                                                        child:
                                                            CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                                color: Colors
                                                                    .white),
                                                      )
                                                    : const Icon(
                                                        Icons.verified_outlined,
                                                        size: 15),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF16A34A),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                ),
                                                label: const Text(
                                                    'Valider cette réponse'),
                                              ),
                                            if (validated)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFDCFCE7),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          999),
                                                  border: Border.all(
                                                      color: const Color(
                                                          0xFF86EFAC)),
                                                ),
                                                child: Text(
                                                  validatedBy == null
                                                      ? 'Réponse validée par l’enseignant'
                                                      : 'Réponse validée par ${validatedBy['username']}',
                                                  style: const TextStyle(
                                                    color: Color(0xFF166534),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _replyThreadId = thread['id'] as int?;
                                  });
                                },
                                child:
                                    const Text('Répondre à cette discussion'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 1080;
        final useStackedReplyForm = constraints.maxWidth < 1180;

        final replyForm = Container(
          padding: const EdgeInsets.all(18),
          decoration: _surfaceDecoration(),
          child: useStackedReplyForm
              ? Column(
                  children: [
                    DropdownButtonFormField<int>(
                      value: _replyThreadId,
                      isExpanded: true,
                      decoration: _inputDecoration('Discussion à répondre'),
                      items: _threads
                          .map((thread) => DropdownMenuItem<int>(
                                value: thread['id'] as int,
                                child: Text(thread['title'].toString(),
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      selectedItemBuilder: (context) {
                        return _threads
                            .map(
                              (thread) => Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  thread['title'].toString(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList();
                      },
                      onChanged: (value) =>
                          setState(() => _replyThreadId = value),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _threadReplyCtrl,
                      minLines: 2,
                      maxLines: 4,
                      decoration: _inputDecoration('Votre réponse...'),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 42,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isReplying ? null : _replyToThread,
                        icon: _isReplying
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.reply_outlined, size: 16),
                        label: const Text('Répondre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _replyThreadId,
                        isExpanded: true,
                        decoration: _inputDecoration('Discussion à répondre'),
                        items: _threads
                            .map((thread) => DropdownMenuItem<int>(
                                  value: thread['id'] as int,
                                  child: Text(thread['title'].toString(),
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        selectedItemBuilder: (context) {
                          return _threads
                              .map(
                                (thread) => Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    thread['title'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList();
                        },
                        onChanged: (value) =>
                            setState(() => _replyThreadId = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _threadReplyCtrl,
                        minLines: 2,
                        maxLines: 4,
                        decoration: _inputDecoration('Votre réponse...'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _isReplying ? null : _replyToThread,
                        icon: _isReplying
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.reply_outlined, size: 16),
                        label: const Text('Répondre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B6BFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
        );

        return Column(
          children: [
            Expanded(
              child: isNarrow
                  ? Column(
                      children: [
                        Expanded(child: publishCard),
                        const SizedBox(height: 12),
                        Expanded(child: discussionsCard),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(flex: 3, child: publishCard),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: discussionsCard),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            replyForm,
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF93C5FD), width: 1),
      ),
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}

class _BannerMessage extends StatelessWidget {
  const _BannerMessage({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final compactMessage = message.length > 900
        ? '${message.substring(0, 900)}\n\n...message tronqué...'
        : message;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCD34D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_outlined,
                  color: Color(0xFFB45309)),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Erreur de chargement',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 160),
            child: SingleChildScrollView(
              child: SelectableText(
                compactMessage,
                style:
                    const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
