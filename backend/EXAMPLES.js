/**
 * EXAMPLES.js - Exemples d'utilisation du système de notifications
 * 
 * Cet fichier montre comment intégrer les notifications dans vos workflows
 */

const { notificationsService, notificationOrchestrator } = require('./src/services');

// ============ EXEMPLE 1: Confirmation de réservation ============
async function handleReservationCreated(reservationId) {
  try {
    // 1. Créer la notification
    const notification = await notificationsService.notifyReservationConfirmation(
      reservationId
    );

    console.log('Notification créée:', notification.id);

    // 2. Envoyer immédiatement via FCM au user
    await notificationOrchestrator.sendNotificationToUser(notification);

    // 3. (Optionnel) Programmer un rappel 24h avant
    const reservation = await prisma.reservation.findUnique({
      where: { id: reservationId },
    });

    const reminder24h = new Date(reservation.startDateTime);
    reminder24h.setHours(reminder24h.getHours() - 24);

    await notificationsService.scheduleNotification(
      notification.id,
      reminder24h
    );

    console.log('✓ Notification programmée pour 24h avant');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 2: Modifier une réservation ============
async function handleReservationModified(reservationId, changes) {
  try {
    // Notifier l'utilisateur des changements
    const notification = await notificationsService.notifyReservationModified(
      reservationId,
      {
        'Nouvelle date': changes.startDateTime,
        'Nouvelle heure': changes.startDateTime,
      }
    );

    // Envoyer immédiatement
    await notificationOrchestrator.sendNotificationToUser(notification);

    console.log('✓ Notification de modification envoyée');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 3: Annoncer un nouveau cours ============
async function handleNewCoursePublished(courseId, targetStudentIds = null) {
  try {
    // Notifier les utilisateurs cibles
    const notifications = await notificationsService.notifyNewCourseAvailable(
      courseId,
      targetStudentIds // null = tous les utilisateurs
    );

    console.log(`✓ ${notifications.length} notifications créées`);

    // Envoyer à tous les users
    for (const notification of notifications) {
      await notificationOrchestrator.sendNotificationToUser(notification);
    }

    console.log('✓ Toutes les notifications envoyées');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 4: Broadcast Promotion spéciale ============
async function handleNewPromotion(title, description, discount, endDate) {
  try {
    // Envoyer la promotion à TOUS les utilisateurs actifs
    await notificationOrchestrator.broadcastNotification(
      title,
      description,
      { blocked: false }, // query: tous les utilisateurs actifs
      'promotions' // Topic FCM optionnel
    );

    console.log('✓ Promotion broadcast envoyée');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 5: Message d'enseignant ============
async function handleTeacherMessage(studentId, courseName, message, teacherName) {
  try {
    const notification = await notificationsService.notifyTeacherMessage(
      studentId,
      courseName,
      message,
      teacherName
    );

    // Envoyer immédiatement
    await notificationOrchestrator.sendNotificationToUser(notification);

    console.log('✓ Message d\'enseignant envoyé');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 6: Rappel automatique avant session ============
async function scheduleSessionReminders(sessionId) {
  try {
    const session = await prisma.trainingSession.findUnique({
      where: { id: sessionId },
      include: {
        attendees: {
          select: { userId: true },
        },
      },
    });

    if (!session || !session.startDate) return;

    // Programmer rappel 24h avant
    const reminder24h = new Date(session.startDate);
    reminder24h.setHours(reminder24h.getHours() - 24);

    // Programmer rappel 1h avant
    const reminder1h = new Date(session.startDate);
    reminder1h.setHours(reminder1h.getHours() - 1);

    for (const attendee of session.attendees) {
      // Notification 24h
      const notif24h = await notificationsService.createNotification({
        userId: attendee.userId,
        type: 'TRAINING_SESSION_STARTED',
        title: `⏰ Session ${session.title} demain`,
        body: `N'oubliez pas: La session commence demain à ${session.startDate.toLocaleTimeString('fr-FR')}`,
        sessionId,
      });

      await notificationsService.scheduleNotification(notif24h.id, reminder24h);

      // Notification 1h
      const notif1h = await notificationsService.createNotification({
        userId: attendee.userId,
        type: 'TRAINING_SESSION_STARTED',
        title: `▶ Session ${session.title} dans 1h`,
        body: 'La session commence dans 1 heure!',
        sessionId,
      });

      await notificationsService.scheduleNotification(notif1h.id, reminder1h);
    }

    console.log(`✓ Rappels programmés pour ${session.attendees.length} participants`);
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 7: Annulation de réservation ============
async function handleReservationCancelled(reservationId, reason) {
  try {
    const notification = await notificationsService.notifyReservationCancelled(
      reservationId,
      reason
    );

    // Envoyer la notification
    await notificationOrchestrator.sendNotificationToUser(notification);

    // (Optionnel) Envoyer un email aussi
    console.log('✓ Notification d\'annulation envoyée');
  } catch (error) {
    console.error('Erreur:', error);
  }
}

// ============ EXEMPLE 8: Integration avec Express routes ============
const express = require('express');
const router = express.Router();

router.post('/reservations', async (req, res) => {
  try {
    // Créer la réservation
    const reservation = await createReservation(req.body);

    // Envoyer notifications
    await handleReservationCreated(reservation.id);

    res.status(201).json(reservation);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.patch('/reservations/:id', async (req, res) => {
  try {
    // Mettre à jour
    const updated = await updateReservation(req.params.id, req.body);

    // Notifier des changements
    if (req.body.startDateTime || req.body.endDateTime) {
      await handleReservationModified(req.params.id, req.body);
    }

    res.json(updated);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.delete('/reservations/:id', async (req, res) => {
  try {
    // Supprimer
    await deleteReservation(req.params.id);

    // Notifier l'annulation
    await handleReservationCancelled(req.params.id, req.body.reason || null);

    res.json({ message: 'Réservation annulée' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// ============ EXEMPLE 9: Tests & Monitoring ============
async function testNotifications() {
  try {
    console.log('🧪 Test du système de notifications...\n');

    // 1. Test d'envoi simple
    console.log('1️⃣ Test d\'envoi simple...');
    const testUser = 1; // remplacer par un user ID réel
    const testNotif = await notificationsService.createNotification({
      userId: testUser,
      type: 'PROMOTION_OFFER',
      title: '🎉 Test Notification',
      body: 'Ceci est une notification de test',
    });
    console.log('✓ Notification créée:', testNotif.id);

    // 2. Test d'envoi FCM
    console.log('\n2️⃣ Test d\'envoi FCM...');
    await notificationOrchestrator.sendNotificationToUser(testNotif);
    console.log('✓ Notification envoyée via FCM');

    // 3. Test de statistiques
    console.log('\n3️⃣ Statistiques...');
    const stats = await notificationOrchestrator.getStats();
    console.log(JSON.stringify(stats, null, 2));

    // 4. Test de marquage comme lue
    console.log('\n4️⃣ Test marquage comme lue...');
    await notificationsService.markAsRead(testNotif.id, testUser);
    console.log('✓ Notification marquée comme lue');

    console.log('\n✅ Tests terminés avec succès');
  } catch (error) {
    console.error('❌ Erreur pendant les tests:', error);
  }
}

// Exporter les fonctions
module.exports = {
  handleReservationCreated,
  handleReservationModified,
  handleNewCoursePublished,
  handleNewPromotion,
  handleTeacherMessage,
  scheduleSessionReminders,
  handleReservationCancelled,
  testNotifications,
};

// Lancer les tests si exécuté directement
if (require.main === module) {
  testNotifications();
}
