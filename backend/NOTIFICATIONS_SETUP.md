# Système de Notifications Push - Guide d'Intégration

## 📋 Vue d'ensemble

Système complet de notifications push en temps réel utilisant Firebase Cloud Messaging (FCM) pour les applications web et mobile Flutter.

### Types de notifications implémentées
1. ✓ **Confirmation de réservation** - Quand une réservation est confirmée
2. ✓ **Rappels** - 24h et 1h avant une réservation
3. ✓ **Modifications/Annulations** - Modifications ou annulation de réservation
4. ✓ **Nouveaux cours** - Notification des nouveaux cours disponibles
5. ✓ **Début de session** - Notifications du début des sessions de formation
6. ✓ **Messages d'enseignants** - Messages des enseignants aux étudiants
7. ✓ **Échéance de paiement** - Rappels de paiement d'abonnement
8. ✓ **Promotions** - Offres spéciales et promotions

---

## 🛠️ Configuration Backend (Node.js/Express)

### 1. Installation des dépendances

```bash
cd backend
npm install firebase-admin
npm install @prisma/client prisma
```

### 2. Configuration Firebase

1. Créer un projet Firebase: https://console.firebase.google.com
2. Générer une clé de service: 
   - Aller à `Project Settings > Service Accounts`
   - Cliquer `Generate New Private Key`
3. Ajouter à votre `.env`:

```env
# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY='{"type": "service_account", ...}'
# OU
GOOGLE_APPLICATION_CREDENTIALS='/path/to/serviceAccountKey.json'
```

### 3. Migration de la base de données

```bash
# Générer migration
npx prisma migrate dev --name add_notifications

# Pusher le schéma
npx prisma db push
```

### 4. Intégration dans `index.js`

```javascript
const express = require('express');
const { notificationOrchestrator } = require('./src/services');

const app = express();

// ... configuration existante ...

// Routes
app.use('/api/notifications', require('./src/routes/notifications.routes'));

// Démarrer le service de notifications
app.listen(PORT, () => {
  console.log(`✓ Serveur lancé sur le port ${PORT}`);
  
  // Démarrer l'orchestrateur de notifications
  notificationOrchestrator.start();
});
```

### 5. Intégration dans les contrôleurs

#### Réservations
```javascript
// reservations.controller.js
const { notificationsService, notificationOrchestrator } = require('../services');

async createReservation(req, res, next) {
  try {
    // ... créer réservation ...
    
    if (reservation.status === 'CONFIRMED') {
      // Envoyer confirmation de réservation
      await notificationsService.notifyReservationConfirmation(reservation.id);
      await notificationOrchestrator.sendNotificationToUser(...)
    }
    
    res.status(201).json(reservation);
  } catch (error) {
    next(error);
  }
}

async updateReservation(req, res, next) {
  try {
    // ... update réservation ...
    
    // Notifier des modifications
    await notificationsService.notifyReservationModified(
      reservation.id,
      changes
    );
    
    res.json(reservation);
  } catch (error) {
    next(error);
  }
}

async cancelReservation(req, res, next) {
  try {
    // ... cancel réservation ...
    
    // Notifier de l'annulation
    await notificationsService.notifyReservationCancelled(
      reservation.id,
      req.body.reason
    );
    
    res.json({ message: 'Réservation annulée' });
  } catch (error) {
    next(error);
  }
}
```

#### Cours
```javascript
// courses.controller.js
async createCourse(req, res, next) {
  try {
    // ... créer cours ...
    
    // Notifier les utilisateurs
    await notificationsService.notifyNewCourseAvailable(course.id);
    
    res.status(201).json(course);
  } catch (error) {
    next(error);
  }
}
```

#### Sessions de formation
```javascript
// trainingSessions.controller.js
async startSession(req, res, next) {
  try {
    // ... start session ...
    
    if (session.mystatus === 'En_cours') {
      await notificationsService.notifyTrainingSessionStarted(session.id);
    }
    
    res.json(session);
  } catch (error) {
    next(error);
  }
}
```

---

## 📱 Configuration Frontend (Flutter)

### 1. Installation des dépendances

```bash
cd front
flutter pub add firebase_messaging
flutter pub get
```

### 2. Configuration Firebase (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^latest
  firebase_messaging: ^latest
  get: ^latest
```

### 3. Configuration iOS (sinon optionnel)

```bash
cd ios
pod install
```

### 4. Configuration Web (si nécessaire)

1. Ajouter `web/index.html`:
```html
<!-- Firebase Cloud Messaging Service Worker -->
<script>
  if ("serviceWorker" in navigator) {
    navigator.serviceWorker.register("firebase-messaging-sw.js");
  }
</script>
```

2. Créer `web/firebase-messaging-sw.js`:
```javascript
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/8.10.0/firebase-messaging.js");

firebase.initializeApp({
  apiKey: "YOUR_API_KEY",
  projectId: "YOUR_PROJECT_ID",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_APP_ID",
});

const messaging = firebase.messaging();
```

### 5. Initialiser dans `main.dart`

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_getx_app/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // Initialiser FCM Service
  Get.put(FCMService());
  
  runApp(const MyApp());
}
```

### 6. Intégrer la page de notifications

```dart
// Dans votre routeur
GetPage(
  name: '/notifications',
  page: () => const NotificationsPage(),
  binding: BindingsBuilder(() {
    Get.put(NotificationsController());
  }),
),
```

### 7. Ajouter un badge de notification

```dart
// Dans votre appbar ou navigation
Obx(() {
  final unreadCount = Get.find<NotificationsController>().unreadCount.value;
  
  return Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.notifications_outlined),
        onPressed: () => Get.toNamed('/notifications'),
      ),
      if (unreadCount > 0)
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: Text(
              unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ],
  );
})
```

---

## 🔌 Endpoints de l'API

### Enregistrement du Token FCM
```
POST /api/notifications/register-fcm
Authorization: Bearer <token>
Content-Type: application/json

{
  "token": "FCM_TOKEN",
  "device": "iPhone 12 / Android Device / Web"
}
```

### Récupérer les notifications
```
GET /api/notifications?skip=0&take=20&isRead=false&type=RESERVATION_CONFIRMATION
Authorization: Bearer <token>
```

### Marquer comme lue
```
PATCH /api/notifications/:id/read
Authorization: Bearer <token>
```

### Marquer toutes comme lues
```
PATCH /api/notifications/read-all
Authorization: Bearer <token>
```

### Supprimer une notification
```
DELETE /api/notifications/:id
Authorization: Bearer <token>
```

### Obtenir le nombre de non-lues
```
GET /api/notifications/unread-count
Authorization: Bearer <token>
```

---

## 🎯 Cas d'usage avancés

### Scheduler personnalisé

```javascript
// Dans notification-orchestrator.js
async scheduleReservationReminders() {
  // Programmer les rappels intelligemment
  // - 24h avant: rappel soft
  // - 1h avant: rappel urgent
  // - À l'heure: début de session
}

async broadcastPromotion(promotionId, targetAudience) {
  // Envoyer une promotion à un segment d'utilisateurs
  // Peut utiliser des topics FCM pour les broadcasts
}
```

### Topics FCM pour les broadcasts

```javascript
// Envoyer à tous les utilisateurs d'un cours
await fcmService.subscribeToTopic(
  tokens,
  `course_${courseId}`
);

await fcmService.sendNotificationToTopic(
  `course_${courseId}`,
  {
    title: 'Nouveau contenu',
    body: 'Une nouvelle leçon a été ajoutée',
  }
);
```

---

## 🐛 Troubleshooting

### Notifications pas reçues
1. Vérifier que les tokens FCM sont bien enregistrés: `SELECT * FROM FCMToken WHERE isActive = true;`
2. Vérifier les erreurs de Firebase dans les logs
3. Certains emulateurs ne supportent pas FCM

### Tokens expirés
- Firebase rafraîchit les tokens régulièrement
- L'app devrait automatiquement réenregistrer avec le nouveau token
- Les tokens non valides sont marqués comme `isActive = false`

### Permissions
- iOS/Android: Demander la permission explicitement
- Web: Utiliser Service Workers correctement
- Tester sur un device réel, pas sur emulateur

---

## 📊 Monitoring

### Vérifier les statistiques
```bash
curl http://localhost:3001/api/notifications/stats \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Logs
```
# Backend
tail -f logs/notifications.log

# Frontend
flutter logs | grep -i notification
```

---

## 🚀 Déploiement

Checklist avant production:
- [ ] Firebase en production configuré
- [ ] tokens FCM verrouillés par utilisateur
- [ ] Rate limiting sur les endpoints
- [ ] Logs et monitoring activés
- [ ] Plan de récupération en cas d'erreur
- [ ] Tests des notifications batch
- [ ] Politique de rétention des notifications (30 jours?)
