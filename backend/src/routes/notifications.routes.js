const express = require('express');
const notificationsController = require('../controllers/notifications.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

// Routes Notifications - Specific routes FIRST
router.get('/unread-count', authMiddleware, (req, res, next) =>
  notificationsController.getUnreadCount(req, res, next)
);

router.patch('/read-all', authMiddleware, (req, res, next) =>
  notificationsController.markAllAsRead(req, res, next)
);

router.delete('/delete-read', authMiddleware, (req, res, next) =>
  notificationsController.deleteReadNotifications(req, res, next)
);

// Then generic routes with parameters
router.get('/', authMiddleware, (req, res, next) =>
  notificationsController.getUserNotifications(req, res, next)
);

router.patch('/:id/read', authMiddleware, (req, res, next) =>
  notificationsController.markAsRead(req, res, next)
);

router.delete('/:id', authMiddleware, (req, res, next) =>
  notificationsController.deleteNotification(req, res, next)
);

module.exports = router;
