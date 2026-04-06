const notificationsService = require('../services/notifications.service');

class NotificationsController {
  /**
   * Obtenir les notifications d'un utilisateur
   * GET /api/notifications
   */
  async getUserNotifications(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const { skip = 0, take = 20, isRead, type } = req.query;

      const result = await notificationsService.getUserNotifications(userId, {
        skip: parseInt(skip, 10),
        take: parseInt(take, 10),
        isRead: isRead !== undefined ? isRead === 'true' : null,
        type: type || null,
      });

      return res.json(result);
    } catch (error) {
      next(error);
    }
  }

  /**
   * Obtenir le nombre de notifications non lues
   * GET /api/notifications/unread-count
   */
  async getUnreadCount(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const count = await notificationsService.getUnreadCount(userId);

      return res.json({
        unreadCount: count,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Marquer une notification comme lue
   * PATCH /api/notifications/:id/read
   */
  async markAsRead(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const { id } = req.params;

      const result = await notificationsService.markAsRead(parseInt(id, 10), userId);

      return res.json({
        data: result,
        message: 'Notification marquée comme lue',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Marquer toutes les notifications comme lues
   * PATCH /api/notifications/read-all
   */
  async markAllAsRead(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const result = await notificationsService.markAllAsRead(userId);

      return res.json({
        message: `${result.count} notification(s) marquée(s) comme lue(s)`,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Supprimer une notification
   * DELETE /api/notifications/:id
   */
  async deleteNotification(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const { id } = req.params;

      await notificationsService.deleteNotification(parseInt(id, 10), userId);

      return res.json({
        message: 'Notification supprimée',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Supprimer toutes les notifications lues d'un utilisateur
   * DELETE /api/notifications/delete-read
   */
  async deleteReadNotifications(req, res, next) {
    try {
      const userId = req.user?.id;
      if (!userId) {
        return res.status(401).json({ error: 'Non authentifié' });
      }

      const result = await notificationsService.deleteReadNotifications(userId);

      return res.json({
        message: `${result.count} notification(s) lue(s) supprimée(s)`,
        count: result.count,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new NotificationsController();
