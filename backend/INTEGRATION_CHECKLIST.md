/**
 * INTEGRATION_CHECKLIST.md
 * 
 * Étapes pour intégrer le système de notifications dans src/index.js
 */

# Intégration du Système de Notifications

## 1. Importer les services au top du fichier

```javascript
// src/index.js

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

// 👇 AJOUTER CETTE LIGNE
const { notificationOrchestrator } = require('./services/notification-orchestrator');

const app = express();
```

## 2. Importer et monter les routes de notifications

```javascript
// Après les autres imports de routes
// 👇 AJOUTER CETTE LIGNE
const notificationsRoutes = require('./routes/notifications.routes');

// ... autres middleware ...

// 👇 AJOUTER CETTE SECTION
// Routes - Notifications
app.use('/api/notifications', notificationsRoutes);
```

## 3. Modifier le middleware d'authentification dans les routes

```javascript
// src/routes/notifications.routes.js

// Remplacer le middleware d'authentification actuel par votre middleware:
const { verifyToken } = require('../middleware/auth'); // ajuster le chemin

router.post('/register-fcm', verifyToken, (req, res, next) =>
  notificationsController.registerFCMToken(req, res, next)
);

// ✅ Votre middleware 'auth' doit définir req.user.id
```

## 4. Démarrer l'orchestrateur au boot du serveur

```javascript
// À la fin de src/index.js

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.log(`✓ Serveur lancé sur le port ${PORT}`);
  
  // 👇 AJOUTER CETTE SECTION
  // Démarrer le service de notifications
  if (process.env.ENABLE_NOTIFICATIONS !== 'false') {
    notificationOrchestrator.start();
    console.log('✓ Orchestrateur de notifications démarré');
    
    // Afficher les statistiques toutes les heures
    setInterval(async () => {
      const stats = await notificationOrchestrator.getStats();
      console.log('📊 Stats notifications:', stats);
    }, 60 * 60 * 1000);
  }
});
```

## 5. (Optionnel) Ajouter une route d'administrateur pour les statistiques

```javascript
// src/routes/notifications.routes.js

// Route admin pour voir les stats
router.get('/admin/stats', authMiddleware, isAdmin, (req, res, next) => {
  notificationOrchestrator.getStats().then(stats => {
    res.json(stats);
  }).catch(next);
});
```

## 6. Intégrer dans les contrôleurs existants

### Exemple: Réservations

```javascript
// src/controllers/reservations.controller.js

const { notificationsService, notificationOrchestrator } = require('../services');

class ReservationsController {
  async create(req, res, next) {
    try {
      const reservation = await createReservation(req.body);
      
      // 👇 AJOUTER CETTE SECTION
      if (reservation.status === 'CONFIRMED') {
        // Créer et envoyer notification
        const notification = await notificationsService
          .notifyReservationConfirmation(reservation.id);
        
        // Envoyer via FCM immédiatement
        await notificationOrchestrator.sendNotificationToUser(notification);
      }
      
      res.status(201).json(reservation);
    } catch (error) {
      next(error);
    }
  }

  async update(req, res, next) {
    try {
      const updated = await updateReservation(req.params.id, req.body);
      
      // 👇 AJOUTER CETTE SECTION
      if (req.body.startDateTime || req.body.endDateTime) {
        await notificationsService.notifyReservationModified(
          req.params.id,
          req.body
        );
      }
      
      res.json(updated);
    } catch (error) {
      next(error);
    }
  }

  async cancel(req, res, next) {
    try {
      await cancelReservation(req.params.id);
      
      // 👇 AJOUTER CETTE SECTION
      await notificationsService.notifyReservationCancelled(
        req.params.id,
        req.body.reason
      );
      
      res.json({ message: 'Annulée' });
    } catch (error) {
      next(error);
    }
  }
}
```

### Exemple: Cours

```javascript
// src/controllers/courses.controller.js

async publishCourse(req, res, next) {
  try {
    const course = await publishCourse(req.params.id);
    
    // 👇 AJOUTER CETTE SECTION
    // Notifier tous les utilisateurs
    await notificationsService.notifyNewCourseAvailable(course.id);
    
    res.json(course);
  } catch (error) {
    next(error);
  }
}
```

## 7. Configuration des variables d'environnement

```bash
# .env

# Firebase Configuration
FIREBASE_SERVICE_ACCOUNT_KEY='{"type": "service_account", ...}'

# Notifications
ENABLE_NOTIFICATIONS=true
NOTIFICATION_CHECK_INTERVAL=60000
DEBUG_NOTIFICATIONS=false
```

## 8. Teste l'intégration

```bash
# 1. Redémarrer le serveur
npm run dev

# 2. Vérifier les logs
# Devrait voir: "✓ Orchestrateur de notifications démarré"

# 3. Tester un endpoint
curl -X POST http://localhost:3001/api/notifications/register-fcm \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "FCM_TOKEN"}'

# 4. Vérifier la base de données
npx prisma studio
# Et voir les FCMToken et Notification tables remplies
```

## 9. (Optionnel) Ajouter des tests

```javascript
// tests/notifications.test.js

const request = require('supertest');
const app = require('../src/index');

describe('Notifications', () => {
  it('should register FCM token', async () => {
    const res = await request(app)
      .post('/api/notifications/register-fcm')
      .set('Authorization', `Bearer ${TOKEN}`)
      .send({ token: 'test_fcm_token' });
    
    expect(res.status).toBe(201);
    expect(res.body.data.token).toBe('test_fcm_token');
  });

  it('should fetch user notifications', async () => {
    const res = await request(app)
      .get('/api/notifications')
      .set('Authorization', `Bearer ${TOKEN}`);
    
    expect(res.status).toBe(200);
    expect(res.body.data).toBeInstanceOf(Array);
  });
});
```

---

## ✅ Checklist d'Intégration

- [ ] Importer notificationOrchestrator
- [ ] Monter les routes /api/notifications
- [ ] Démarrer l'orchestrateur au boot
- [ ] Ajouter notificationsService aux contrôleurs
- [ ] Intégrer dans réservations.controller.js
- [ ] Intégrer dans courses.controller.js
- [ ] Intégrer dans trainingSessions.controller.js
- [ ] Configurer les variables d'environnement
- [ ] Tester les endpoints
- [ ] Vérifier les données en DB
- [ ] Tester sur l'app Flutter

---

## 🆘 Problèmes Courants

### "notificationOrchestrator is not defined"
- Vérifier l'import au top du fichier
- Vérifier le chemin relatif

### "Notifications are not being sent"
- Vérifier que `ENABLE_NOTIFICATIONS` n'est pas `false`
- Vérifier que Firebase est configuré
- Vérifier les logs du serveur

### "Cannot find module 'firebase-admin'"
- Installer: `npm install firebase-admin`

### "Prisma tables don't exist"
- Exécuter la migration: `npx prisma migrate dev`
