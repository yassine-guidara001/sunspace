const { PrismaClient } = require('@prisma/client');
const { NotFoundError, ValidationError } = require('../utils/errors');

const prisma = new PrismaClient();
const trainingSessionStartTimers = new Map();

class NotificationsService {
  _buildReminderWindow(hoursBeforeEvent, driftMinutes = 5) {
    const now = new Date();
    const target = now.getTime() + (hoursBeforeEvent * 60 * 60 * 1000);
    return {
      start: new Date(target - (driftMinutes * 60 * 1000)),
      end: new Date(target + (driftMinutes * 60 * 1000)),
    };
  }
  
  _buildSessionStartWindow(driftMinutes = 5) {
    const now = new Date();
    return {
      start: new Date(now.getTime() - (driftMinutes * 60 * 1000)),
      end: new Date(now.getTime() + (driftMinutes * 60 * 1000)),
    };
  }

  scheduleTrainingSessionStartNotification(sessionId, startDate) {
    if (!sessionId || !startDate) return;

    const existingTimer = trainingSessionStartTimers.get(sessionId);
    if (existingTimer) {
      clearTimeout(existingTimer);
      trainingSessionStartTimers.delete(sessionId);
    }

    const targetDate = startDate instanceof Date ? startDate : new Date(startDate);
    if (Number.isNaN(targetDate.getTime())) return;

    const delay = Math.max(0, targetDate.getTime() - Date.now());

    const timer = setTimeout(async () => {
      trainingSessionStartTimers.delete(sessionId);

      try {
        await this.notifyTrainingSessionStarted(sessionId);
      } catch (error) {
        console.error('Failed to deliver scheduled training session start notification:', error.message);
      }
    }, delay);

    trainingSessionStartTimers.set(sessionId, timer);
  }

  clearTrainingSessionStartNotification(sessionId) {
    const existingTimer = trainingSessionStartTimers.get(sessionId);
    if (!existingTimer) return;

    clearTimeout(existingTimer);
    trainingSessionStartTimers.delete(sessionId);
  }

  async cleanupLegacyStudentEnrollmentNotifications() {
    const result = await prisma.notification.deleteMany({
      where: {
        type: 'TEACHER_MESSAGE',
        title: '✅ Inscription confirmée',
      },
    });

    return { deleted: result.count };
  }

  /**
   * Créer une notification
   */
  async createNotification(data) {
    try {
      const {
        userId,
        type,
        title,
        body,
        notificationData,
        reservationId,
        courseId,
        sessionId,
      } = data;

      // Valider que l'utilisateur existe
      const user = await prisma.user.findUnique({
        where: { id: userId },
      });

      if (!user) {
        throw new NotFoundError('Utilisateur non trouvé');
      }

      // Créer la notification
      return await prisma.notification.create({
        data: {
          userId,
          type,
          title,
          body,
          data: notificationData || null,
          reservationId: reservationId || null,
          courseId: courseId || null,
          sessionId: sessionId || null,
        },
        include: {
          user: {
            select: {
              id: true,
              email: true,
              username: true,
            },
          },
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Marquer une notification comme lue
   */
  async markAsRead(notificationId, userId) {
    try {
      const notification = await prisma.notification.findUnique({
        where: { id: notificationId },
      });

      if (!notification) {
        throw new NotFoundError('Notification non trouvée');
      }

      if (notification.userId !== userId) {
        throw new ValidationError('Accès non autorisé');
      }

      return await prisma.notification.update({
        where: { id: notificationId },
        data: {
          isRead: true,
          readAt: new Date(),
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Marquer tous les notifications comme lues
   */
  async markAllAsRead(userId) {
    try {
      return await prisma.notification.updateMany({
        where: {
          userId,
          isRead: false,
        },
        data: {
          isRead: true,
          readAt: new Date(),
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtenir les notifications d'un utilisateur
   */
  async getUserNotifications(userId, options = {}) {
    try {
      const {
        skip = 0,
        take = 20,
        isRead = null,
        type = null,
      } = options;

      const where = { userId };
      if (isRead !== null) where.isRead = isRead;
      if (type) where.type = type;

      const [notifications, total] = await Promise.all([
        prisma.notification.findMany({
          where,
          skip,
          take,
          orderBy: { createdAt: 'desc' },
          include: {
            reservation: {
              select: {
                id: true,
                startDateTime: true,
                endDateTime: true,
                space: { select: { name: true } },
              },
            },
            course: {
              select: { id: true, title: true },
            },
            session: {
              select: { id: true, title: true, startDate: true },
            },
          },
        }),
        prisma.notification.count({ where }),
      ]);

      return {
        data: notifications,
        pagination: {
          total,
          skip,
          take,
        },
      };
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtenir le nombre de notifications non lues
   */
  async getUnreadCount(userId) {
    try {
      return await prisma.notification.count({
        where: {
          userId,
          isRead: false,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Supprimer une notification
   */
  async deleteNotification(notificationId, userId) {
    try {
      const notification = await prisma.notification.findUnique({
        where: { id: notificationId },
      });

      if (!notification) {
        throw new NotFoundError('Notification non trouvée');
      }

      if (notification.userId !== userId) {
        throw new ValidationError('Accès non autorisé');
      }

      return await prisma.notification.delete({
        where: { id: notificationId },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Supprimer toutes les notifications lues d'un utilisateur
   */
  async deleteReadNotifications(userId) {
    try {
      return await prisma.notification.deleteMany({
        where: {
          userId,
          isRead: true,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Créer une notification de confirmation de réservation
   */
  async notifyReservationConfirmation(reservationId) {
    try {
      const reservation = await prisma.reservation.findUnique({
        where: { id: reservationId },
        include: {
          user: true,
          space: true,
        },
      });

      if (!reservation) {
        throw new NotFoundError('Réservation non trouvée');
      }

      const startTime = new Date(reservation.startDateTime).toLocaleString('fr-FR');
      const endTime = new Date(reservation.endDateTime).toLocaleString('fr-FR');

      return await this.createNotification({
        userId: reservation.userId,
        type: 'RESERVATION_CONFIRMATION',
        title: '✓ Réservation confirmée',
        body: `Votre réservation de "${reservation.space.name}" du ${startTime} au ${endTime} a été confirmée.`,
        reservationId,
        notificationData: {
          reservationId,
          spaceName: reservation.space.name,
          startDateTime: reservation.startDateTime,
          endDateTime: reservation.endDateTime,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Créer une notification de rappel
   */
  async notifyReservationReminder(reservationId, hoursBeforeEvent) {
    try {
      const reservation = await prisma.reservation.findUnique({
        where: { id: reservationId },
        include: {
          user: true,
          space: true,
        },
      });

      if (!reservation) {
        throw new NotFoundError('Réservation non trouvée');
      }

      const reminderType = hoursBeforeEvent === 24 
        ? 'RESERVATION_REMINDER_24H' 
        : 'RESERVATION_REMINDER_1H';

      const startTime = new Date(reservation.startDateTime).toLocaleTimeString('fr-FR', {
        hour: '2-digit',
        minute: '2-digit',
      });

      return await this.createNotification({
        userId: reservation.userId,
        type: reminderType,
        title: `⏰ Rappel de réservation (${hoursBeforeEvent}h avant)`,
        body: `Rappel : Votre réservation de "${reservation.space.name}" commence à ${startTime}.`,
        reservationId,
        notificationData: {
          reservationId,
          spaceName: reservation.space.name,
          startDateTime: reservation.startDateTime,
          hoursBeforeEvent,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Créer une notification de modification de réservation
   */
  async notifyReservationModified(reservationId, changes) {
    try {
      const reservation = await prisma.reservation.findUnique({
        where: { id: reservationId },
        include: {
          user: true,
          space: true,
        },
      });

      if (!reservation) {
        throw new NotFoundError('Réservation non trouvée');
      }

      const changesList = Object.entries(changes)
        .map(([key, value]) => `${key}: ${value}`)
        .join(', ');

      return await this.createNotification({
        userId: reservation.userId,
        type: 'RESERVATION_MODIFIED',
        title: '✎ Réservation modifiée',
        body: `Votre réservation de "${reservation.space.name}" a été modifiée: ${changesList}`,
        reservationId,
        notificationData: {
          reservationId,
          changes,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Créer une notification d'annulation de réservation
   */
  async notifyReservationCancelled(reservationId, reason = null) {
    try {
      const reservation = await prisma.reservation.findUnique({
        where: { id: reservationId },
        include: {
          user: true,
          space: true,
        },
      });

      if (!reservation) {
        throw new NotFoundError('Réservation non trouvée');
      }

      const reasonText = reason ? ` Raison: ${reason}` : '';

      return await this.createNotification({
        userId: reservation.userId,
        type: 'RESERVATION_CANCELLED',
        title: '✗ Réservation annulée',
        body: `Votre réservation de "${reservation.space.name}" a été annulée.${reasonText}`,
        reservationId,
        notificationData: {
          reservationId,
          reason,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Notifier tous les utilisateurs d'un nouveau cours
   */
  async notifyNewCourseAvailable(courseId, targetUsers = null) {
    try {
      const course = await prisma.course.findUnique({
        where: { id: courseId },
        include: {
          instructor: true,
        },
      });

      if (!course) {
        throw new NotFoundError('Cours non trouvé');
      }

      // Déterminer les utilisateurs à notifier
      let userIds;
      if (targetUsers && targetUsers.length > 0) {
        userIds = targetUsers;
      } else {
        // Par défaut, notifier tous les utilisateurs actifs
        const users = await prisma.user.findMany({
          where: { blocked: false },
          select: { id: true },
        });
        userIds = users.map(u => u.id);
      }

      // Créer les notifications
      const notifications = [];
      for (const userId of userIds) {
        const notification = await this.createNotification({
          userId,
          type: 'NEW_COURSE_AVAILABLE',
          title: '🎓 Nouveau cours disponible',
          body: `Le cours "${course.title}" par ${course.instructor?.username || 'Administrateur'} est maintenant disponible.`,
          courseId,
          notificationData: {
            courseId,
            courseTitle: course.title,
            level: course.level,
            price: course.price,
          },
        });
        notifications.push(notification);
      }

      return notifications;
    } catch (error) {
      throw error;
    }
  }

  /**
   * Notifier du début d'une session de formation
   */
  async notifyTrainingSessionStarted(sessionId) {
    try {
      const session = await prisma.trainingSession.findUnique({
        where: { id: sessionId },
        include: {
          course: true,
          instructor: true,
          attendees: {
            select: { userId: true },
          },
        },
      });

      if (!session) {
        throw new NotFoundError('Session non trouvée');
      }

      const attendeeIds = session.attendees.map(a => a.userId);
      const notifications = [];

      for (const userId of attendeeIds) {
        const existingNotification = await prisma.notification.findFirst({
          where: {
            userId,
            sessionId,
            type: 'TRAINING_SESSION_STARTED',
          },
          select: { id: true },
        });

        if (existingNotification) {
          continue;
        }

        const notification = await this.createNotification({
          userId,
          type: 'TRAINING_SESSION_STARTED',
          title: '▶ Session de formation en cours',
          body: `La session "${session.title}" commence maintenant${session.meetingUrl ? '. Rejoignez le meeting.' : '.'}`,
          sessionId,
          notificationData: {
            sessionId,
            title: session.title,
            meetingUrl: session.meetingUrl,
            courseName: session.course?.title,
          },
        });
        notifications.push(notification);
      }

      return notifications;
    } catch (error) {
      throw error;
    }
  }

  async notifyTrainingSessionEnrollment(attendeeId, sessionId) {
    try {
      const session = await prisma.trainingSession.findUnique({
        where: { id: sessionId },
        include: {
          course: true,
          instructor: {
            select: {
              id: true,
              username: true,
              email: true,
            },
          },
          attendees: {
            include: {
              user: {
                select: {
                  id: true,
                  username: true,
                  email: true,
                },
              },
            },
          },
        },
      });

      if (!session) {
        throw new NotFoundError('Session non trouvée');
      }

      const instructorId = session.instructor?.id;
      if (!instructorId) {
        return null;
      }

      const attendee = session.attendees
        .map((item) => item.user)
        .find((user) => user?.id === attendeeId);

      const attendeeLabel = attendee?.username || attendee?.email || `#${attendeeId}`;

      // Nettoie l'ancienne notification envoyée par erreur à l'étudiant.
      await prisma.notification.deleteMany({
        where: {
          userId: attendeeId,
          sessionId,
          type: 'TEACHER_MESSAGE',
          title: '✅ Inscription confirmée',
        },
      });

      const existingNotification = await prisma.notification.findFirst({
        where: {
          userId: instructorId,
          sessionId,
          type: 'TEACHER_MESSAGE',
          title: '🧑‍🎓 Nouvelle inscription à une session',
          body: `L\'étudiant ${attendeeLabel} s\'est inscrit à "${session.title}".`,
        },
        select: { id: true },
      });

      if (existingNotification) {
        return existingNotification;
      }

      return await this.createNotification({
        userId: instructorId,
        type: 'TEACHER_MESSAGE',
        title: '🧑‍🎓 Nouvelle inscription à une session',
        body: `L'étudiant ${attendeeLabel} s'est inscrit à "${session.title}".`,
        sessionId,
        notificationData: {
          sessionId,
          title: session.title,
          attendeeId,
          attendeeLabel,
          instructorId,
          courseName: session.course?.title,
          startDate: session.startDate,
          event: 'TRAINING_SESSION_ENROLLMENT',
        },
      });
    } catch (error) {
      throw error;
    }
  }

  async processDueTrainingSessionStarts() {
    const window = this._buildSessionStartWindow(5);

    const sessions = await prisma.trainingSession.findMany({
      where: {
        startDate: {
          gte: window.start,
          lte: window.end,
        },
        mystatus: {
          notIn: ['Annulée', 'Terminée'],
        },
      },
      select: { id: true },
    });

    let created = 0;

    for (const session of sessions) {
      const alreadySent = await prisma.notification.findFirst({
        where: {
          sessionId: session.id,
          type: 'TRAINING_SESSION_STARTED',
        },
        select: { id: true },
      });

      if (alreadySent) {
        continue;
      }

      const sentNotifications = await this.notifyTrainingSessionStarted(session.id);
      created += sentNotifications.length;
    }

    return {
      created,
      sessionsMatched: sessions.length,
    };
  }

  async backfillMissingTrainingSessionStarts(hoursBack = 24) {
    const now = new Date();
    const since = new Date(now.getTime() - (hoursBack * 60 * 60 * 1000));

    const sessions = await prisma.trainingSession.findMany({
      where: {
        startDate: {
          gte: since,
          lte: now,
        },
        mystatus: {
          notIn: ['Annulée', 'Terminée'],
        },
      },
      select: { id: true },
    });

    let created = 0;

    for (const session of sessions) {
      const alreadySent = await prisma.notification.findFirst({
        where: {
          sessionId: session.id,
          type: 'TRAINING_SESSION_STARTED',
        },
        select: { id: true },
      });

      if (alreadySent) {
        continue;
      }

      const sentNotifications = await this.notifyTrainingSessionStarted(session.id);
      created += sentNotifications.length;
    }

    return {
      created,
      sessionsMatched: sessions.length,
      hoursBack,
    };
  }

  async processDueReservationReminders() {
    const runReminderPass = async (hoursBeforeEvent, reminderType) => {
      const window = this._buildReminderWindow(hoursBeforeEvent, 8);

      const reservations = await prisma.reservation.findMany({
        where: {
          status: 'CONFIRMED',
          startDateTime: {
            gte: window.start,
            lte: window.end,
          },
        },
        select: { id: true },
      });

      let created = 0;

      for (const reservation of reservations) {
        const alreadySent = await prisma.notification.findFirst({
          where: {
            reservationId: reservation.id,
            type: reminderType,
          },
          select: { id: true },
        });

        if (alreadySent) {
          continue;
        }

        await this.notifyReservationReminder(reservation.id, hoursBeforeEvent);
        created += 1;
      }

      return created;
    };

    const [created24h, created1h] = await Promise.all([
      runReminderPass(24, 'RESERVATION_REMINDER_24H'),
      runReminderPass(1, 'RESERVATION_REMINDER_1H'),
    ]);

    return {
      created24h,
      created1h,
      totalCreated: created24h + created1h,
    };
  }

  async backfillMissingReservationConfirmations() {
    const confirmedReservations = await prisma.reservation.findMany({
      where: { status: 'CONFIRMED' },
      select: { id: true },
    });

    let created = 0;

    for (const reservation of confirmedReservations) {
      const existingConfirmation = await prisma.notification.findFirst({
        where: {
          reservationId: reservation.id,
          type: 'RESERVATION_CONFIRMATION',
        },
        select: { id: true },
      });

      if (existingConfirmation) {
        continue;
      }

      await this.notifyReservationConfirmation(reservation.id);
      created += 1;
    }

    return { created };
  }

  /**
   * Envoyer une notification de message d'enseignant
   */
  async notifyTeacherMessage(userId, courseName, message, senderName) {
    try {
      return await this.createNotification({
        userId,
        type: 'TEACHER_MESSAGE',
        title: `💬 Message de ${senderName}`,
        body: message.substring(0, 150),
        notificationData: {
          courseName,
          senderName,
          message,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Notifier d'une échéance de paiement
   */
  async notifySubscriptionPaymentDue(userId, subscriptionName, dueDate) {
    try {
      const dueDateFormatted = new Date(dueDate).toLocaleDateString('fr-FR');

      return await this.createNotification({
        userId,
        type: 'SUBSCRIPTION_PAYMENT_DUE',
        title: '💳 Échéance de paiement',
        body: `Votre paiement pour "${subscriptionName}" est dû le ${dueDateFormatted}.`,
        notificationData: {
          subscriptionName,
          dueDate,
        },
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Envoyer une notification de promotion
   */
  async notifyPromotionOffer(userIds, promotionTitle, description, discountPercent, endDate) {
    try {
      const notifications = [];
      const endDateFormatted = new Date(endDate).toLocaleDateString('fr-FR');

      for (const userId of userIds) {
        const notification = await this.createNotification({
          userId,
          type: 'PROMOTION_OFFER',
          title: `🎉 ${promotionTitle}`,
          body: `${description} -${discountPercent}% jusqu'au ${endDateFormatted}`,
          notificationData: {
            promotionTitle,
            description,
            discountPercent,
            endDate,
          },
        });
        notifications.push(notification);
      }

      return notifications;
    } catch (error) {
      throw error;
    }
  }
}

module.exports = new NotificationsService();
