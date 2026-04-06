import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Service de Stockage pour la persistance des données locales
/// Utilise GetStorage (alternative légère à SharedPreferences)
class StorageService extends GetxService {
  late final GetStorage _box;
  
  /// Initialise le service de stockage
  /// Cette méthode doit être appelée avant toute utilisation
  Future<StorageService> init() async {
    // Initialiser GetStorage
    await GetStorage.init();
    _box = GetStorage();
    print('Service de stockage initialisé');
    return this;
  }

  // ==================== MÉTHODES GÉNÉRIQUES ====================
  
  /// Sauvegarder une valeur avec une clé
  /// Peut stocker: String, int, double, bool, List, Map
  Future<void> write(String key, dynamic value) async {
    await _box.write(key, value);
    print('Sauvegardé: $key = $value');
  }

  /// Lire une valeur avec une clé
  /// Retourne null si la clé n'existe pas
  T? read<T>(String key) {
    return _box.read<T>(key);
  }

  /// Supprimer une valeur avec une clé
  Future<void> remove(String key) async {
    await _box.remove(key);
    print('Supprimé: $key');
  }

  /// Effacer toutes les données
  /// Attention: Cette action est irréversible!
  Future<void> clearAll() async {
    await _box.erase();
    print('Toutes les données ont été effacées');
  }

  /// Vérifier si une clé existe
  bool hasData(String key) {
    return _box.hasData(key);
  }

  // ==================== MÉTHODES SPÉCIFIQUES ====================
  
  /// Clés de stockage couramment utilisées
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _themeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _onboardingKey = 'onboarding_completed';

  // ===== Authentification =====
  
  /// Sauvegarder le token d'authentification
  Future<void> saveToken(String token) async {
    await write(_tokenKey, token);
  }

  /// Récupérer le token d'authentification
  String? getToken() {
    return read<String>(_tokenKey);
  }

  /// Vérifier si l'utilisateur est connecté
  bool isLoggedIn() {
    return hasData(_tokenKey);
  }

  /// Supprimer le token (déconnexion)
  Future<void> removeToken() async {
    await remove(_tokenKey);
  }

  // ===== Données Utilisateur =====
  
  /// Sauvegarder les données utilisateur
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await write(_userKey, userData);
  }

  /// Récupérer les données utilisateur
  Map<String, dynamic>? getUserData() {
    return read<Map<String, dynamic>>(_userKey);
  }

  /// Supprimer les données utilisateur
  Future<void> removeUserData() async {
    await remove(_userKey);
  }

  // ===== Préférences =====
  
  /// Sauvegarder le mode thème (clair/sombre)
  Future<void> saveThemeMode(String themeMode) async {
    await write(_themeKey, themeMode);
  }

  /// Récupérer le mode thème
  String? getThemeMode() {
    return read<String>(_themeKey);
  }

  /// Sauvegarder la langue
  Future<void> saveLanguage(String languageCode) async {
    await write(_languageKey, languageCode);
  }

  /// Récupérer la langue
  String? getLanguage() {
    return read<String>(_languageKey);
  }

  // ===== Onboarding =====
  
  /// Marquer l'onboarding comme complété
  Future<void> completeOnboarding() async {
    await write(_onboardingKey, true);
  }

  /// Vérifier si l'onboarding est complété
  bool isOnboardingCompleted() {
    return read<bool>(_onboardingKey) ?? false;
  }

  // ===== Déconnexion Complète =====
  
  /// Supprimer toutes les données sensibles lors de la déconnexion
  Future<void> logout() async {
    await removeToken();
    await removeUserData();
    print('Déconnexion: données sensibles supprimées');
  }
}

/*
EXPLICATION DÉTAILLÉE:

1. **GetStorage vs SharedPreferences**
   - GetStorage est plus rapide et plus simple
   - Pas besoin de type spécifique lors de la lecture
   - Supporte les types complexes (List, Map) sans sérialisation manuelle
   - Moins de boilerplate code
   - API plus intuitive

2. **Initialisation Asynchrone**
   - GetStorage.init() doit être appelée avant toute utilisation
   - C'est pourquoi nous avons init() dans main.dart
   - Future<StorageService> permet à Get.putAsync de fonctionner
   - Le service n'est disponible qu'après l'initialisation complète

3. **Méthodes Génériques**
   - write(): Sauvegarde n'importe quel type de données
   - read<T>(): Lit les données avec type-safety
   - remove(): Supprime une clé spécifique
   - clearAll(): Efface tout (utile pour debug ou réinitialisation)
   - hasData(): Vérifie l'existence d'une clé

4. **Méthodes Spécifiques**
   - Encapsulent la logique métier
   - Cachent les clés de stockage (évite les erreurs de typo)
   - Facilitent la maintenance (changement de clé en un seul endroit)
   - Rendent le code plus lisible et compréhensible

5. **Gestion de l'Authentification**
   - saveToken(): Sauvegarde le token JWT reçu du backend
   - getToken(): Récupère le token pour les requêtes API
   - isLoggedIn(): Vérifie rapidement l'état de connexion
   - removeToken(): Supprime le token lors de la déconnexion

6. **Données Utilisateur**
   - Sauvegarde des informations comme: nom, email, avatar, etc.
   - Format Map permet une flexibilité totale
   - Accessible rapidement sans appel API

7. **Préférences Utilisateur**
   - Mode thème: 'light', 'dark', 'system'
   - Langue: 'fr', 'en', 'ar', etc.
   - Persiste entre les sessions

8. **Onboarding**
   - Garde en mémoire si l'utilisateur a vu les écrans d'introduction
   - Évite de les montrer à chaque lancement

9. **Sécurité**
   - Ne JAMAIS stocker de mots de passe en clair
   - Le token JWT est suffisant pour l'authentification
   - logout() efface les données sensibles

10. **Utilisation dans l'Application**
    Exemple dans un contrôleur:
    ```dart
    final storage = Get.find<StorageService>();
    
    // Sauvegarder
    await storage.saveToken('mon_token_jwt');
    
    // Lire
    String? token = storage.getToken();
    
    // Vérifier
    if (storage.isLoggedIn()) {
      // Utilisateur connecté
    }
    ```

11. **Avantages de cette Architecture**
    - Centralisation du stockage
    - Code réutilisable
    - Facile à tester (mock du service)
    - Type-safety avec les génériques
    - Noms de clés cohérents
    - Facile d'ajouter de nouvelles fonctionnalités

12. **Bonnes Pratiques**
    - Toujours utiliser des constantes pour les clés
    - Grouper les méthodes par fonctionnalité
    - Commenter les méthodes importantes
    - Gérer les cas où les données n'existent pas (null-safety)
*/
