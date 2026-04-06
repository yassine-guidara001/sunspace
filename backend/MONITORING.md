# 🔍 DIAGNOSTIC & MONITORING

## Commandes de Diagnostic

### 1. Vérifier que Firebase est bien configuré

```bash
# Test simple - créer un test client
node -e "
const admin = require('firebase-admin');
try {
  if (process.env.FIREBASE_SERVICE_ACCOUNT_KEY) {
    const creds = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
    admin.initializeApp({ credential: admin.credential.cert(creds) });
    console.log('✓ Firebase initialisé avec succès');
  } else {
    console.log('✗ FIREBASE_SERVICE_ACCOUNT_KEY non trouvé');
  }
} catch(e) {
  console.error('✗ Erreur:', e.message);
}
"
```

### 2. Vérifier la base de données

```bash
# SQLite
sqlite3 database.db "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%Notification%';"

# MySQL
mysql -u user -p -e "SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_NAME LIKE '%notification%';"

# PostgreSQL
psql -U user -c "\dt *notification*"
```

### 3. Vérifier les Tables Prisma

```bash
# Via Prisma Studio
npx prisma studio

# Ou en ligne de commande
npx prisma db execute --stdin < check_tables.sql
```

### 4. Vérifier que l'Orchestrateur s'est bien lancé

```bash
# Dans les logs
grep "Orchestrateur de notifications démarré" logs/*.log

# Ou depuis le serveur
curl http://localhost:3001/api/notifications/unread-count \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 5. Vérifier les Tokens FCM

```bash
# Compter les tokens actifs
sqlite3 database.db "SELECT COUNT(*) FROM FCMToken WHERE isActive = true;"

# Lister les tokens d'un user
sqlite3 database.db "SELECT * FROM FCMToken WHERE userId = 1;"

# Voir les tokens par device
sqlite3 database.db "SELECT device, COUNT(*) FROM FCMToken GROUP BY device;"
```

### 6. Vérifier les Notifications Envoyées

```bash
# Notifications envoyées
sqlite3 database.db "SELECT COUNT(*) FROM Notification WHERE isSent = true;"

# Notifications non-lues
sqlite3 database.db "SELECT COUNT(*) FROM Notification WHERE isRead = false;"

# Par type
sqlite3 database.db "SELECT type, COUNT(*) FROM Notification GROUP BY type;"

# Dernières notifications
sqlite3 database.db "SELECT title, type, isSent, createdAt FROM Notification ORDER BY createdAt DESC LIMIT 10;"
```

---

## Health Check API

```bash
# Simuler une notification - créer et envoyer
curl -X POST http://localhost:3001/api/notifications/admin/test \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": 1,
    "title": "Test Notification",
    "body": "Ceci est un test"
  }'

# Voir les stats
curl http://localhost:3001/api/notifications/admin/stats \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Récupérer les notifications d'un user
curl "http://localhost:3001/api/notifications?skip=0&take=10" \
  -H "Authorization: Bearer USER_TOKEN"

# Vérifier les non-lues
curl http://localhost:3001/api/notifications/unread-count \
  -H "Authorization: Bearer USER_TOKEN"
```

---

## Debugging

### Si les notifications ne s'envoient pas

1. **Vérifier les logs**
```bash
# Backend
tail -f logs/notifications.log | grep -E "ERROR|✗|Failed"

# Flutter
flutter logs | grep -i "fcm\|notification"
```

2. **Vérifier que le service est lancé**
```bash
ps aux | grep node
ps aux | grep "notification"
```

3. **Tester manuellement avec Firebase**
```javascript
const admin = require('firebase-admin');
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

admin.messaging().send({
  notification: { title: 'Test', body: 'Message de test' },
  token: 'VOTRE_FCM_TOKEN'
}).then(r => console.log('Envoyé:', r))
  .catch(e => console.error('Erreur:', e));
```

4. **Vérifier les tokens**
```bash
# Les tokens doivent être enregistrés
curl http://localhost:3001/api/notifications/register-fcm \
  -X POST \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"token": "TEST_TOKEN"}'

# Résultat attendu: 201 Created
```

### Si les rappels ne se déclenchent pas

1. Vérifier l'intervalle du scheduler
```bash
grep "NOTIFICATION_CHECK_INTERVAL" .env
# Par défaut: 60000 (1 minute)
```

2. Vérifier les réservations programmées
```bash
sqlite3 database.db "SELECT * FROM Reservation WHERE startDateTime > datetime('now') LIMIT 5;"
```

3. Vérifier les notifications programmées
```bash
sqlite3 database.db "SELECT * FROM NotificationSchedule WHERE sent = false AND scheduledFor <= datetime('now') LIMIT 5;"
```

4. Forcer le traitement manuel
```javascript
const orchestrator = require('./src/services/notification-orchestrator');
await orchestrator.processReservationReminders();
console.log('✓ Rappels traités');
```

---

## Performance

### Vérifier la performance

```bash
# Temps de réponse des endpoints
ab -n 100 -c 10 -H "Authorization: Bearer TOKEN" \
  http://localhost:3001/api/notifications

# Résultat attendu: ~100-200ms
```

### Vérifier les indices de base de données

```sql
-- Vérifier les indices
SELECT * FROM sqlite_master WHERE type='index' AND name LIKE '%notification%';

-- Ou
EXPLAIN QUERY PLAN SELECT * FROM Notification WHERE userId = 1 AND isRead = false;
-- Devrait voir "SEARCH Notification USING ..."
```

---

## Monitoring & Metrics

### Endpoint de statistiques (à ajouter)

```javascript
// src/routes/notifications.routes.js

router.get('/admin/stats', authMiddleware, isAdmin, async (req, res) => {
  try {
    const stats = await notificationOrchestrator.getStats();
    res.json({
      ...stats,
      timestamp: new Date(),
      uptime: process.uptime(),
    });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});
```

### Logs à monitorer

```bash
# Erreurs d'envoi FCM
grep "FCM Error\|send failed" logs/app.log

# Tokens invalides
grep "Invalid token\|unregistered" logs/app.log

# Notifications en attente
grep "pending.*notification" logs/notifications.log

# Performance
grep "took.*ms" logs/app.log
```

---

## Alertes Recommandées

1. **Nombre de notifications non-lues > 1000**
   - Peut indiquer un problème d'envoi

2. **Tokens inactifs > 50% du total**
   - Utilisateurs qui n'ont pas accepté les permissions

3. **Taux d'erreur FCM > 5%**
   - Tokens mal configurés ou Firebase down

4. **Délai d'envoi > 5 secondes**
   - Performance dégradée

5. **Processus Orchestrateur arrêté**
   - Les rappels ne seront pas envoyés

---

## Recovery Procedures

### Si le service s'arrête

```bash
# 1. Vérifier le statut
systemctl status notifications 

# 2. Relancer manuellement
npm run start

# 3. Vérifier les erreurs
npm run dev 2>&1 | head -100
```

### Si les tokens ne s'enregistrent pas

```bash
# 1. Vérifier Firebase est reachable
curl https://www.googleapis.com/oauth2/v4/token -d "grant_type=refresh_token" 2>&1 | head

# 2. Vérifier la clé de service
echo $FIREBASE_SERVICE_ACCOUNT_KEY | jq . | head -5

# 3. Régénérer la clé si nécessaire
# Firebase Console > Project Settings > Service Accounts
```

### Si la base de données est corrompue

```bash
# Backup
sqlite3 database.db ".backup database.backup"

# Vaccum (optimiser)
sqlite3 database.db "VACUUM;"

# Vérifier l'intégrité
sqlite3 database.db "PRAGMA integrity_check;"
```

---

## Tests Automatisés

```bash
# Créer un script de test
cat > test_notifications.sh << 'EOF'
#!/bin/bash

echo "🧪 Test du système de notifications"

# 1. Test Firebase
echo "1. Firebase..."
node -e "require('./src/services/fcm.service')" && echo "✓" || echo "✗"

# 2. Test Database
echo "2. Database..."
sqlite3 database.db "SELECT 1 FROM FCMToken LIMIT 1 2>/dev/null" && echo "✓" || echo "✗"

# 3. Test API
echo "3. API..."
curl -s http://localhost:3001/api/notifications \
  -H "Authorization: Bearer $TOKEN" \
  | grep -q "data" && echo "✓" || echo "✗"

# 4. Test Orchestrator
echo "4. Orchestrator..."
ps aux | grep -q "node.*notification" && echo "✓" || echo "✗"

echo "✅ Tests terminés"
EOF

chmod +x test_notifications.sh
./test_notifications.sh
```

---

## Dashboard de Monitoring (optionnel)

Créer un endpoint qui retourne un JSON pour monitoring:

```javascript
app.get('/api/admin/health/notifications', (req, res) => {
  const healthy = {
    firebase: !!admin.apps.length,
    orchestrator: notificationOrchestrator.isRunning,
    uptime: process.uptime(),
    pendingNotifications: await getPendingCount(),
    failedTokens: await getFailedTokenCount(),
  };
  
  res.json(healthy);
});
```

Accès via: `GET /api/admin/health/notifications`

---

## 📞 Support

Si vous rencontrez des problèmes:

1. Consulter les logs: `npm run dev 2>&1`
2. Vérifier la checklist d'intégration
3. Tester manuellement avec les exemples
4. Vérifier les variables d'environnement
5. Contacter le support Firebase
