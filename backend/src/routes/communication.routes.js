const express = require('express');
const communicationController = require('../controllers/communication.controller');
const { authMiddleware } = require('../middleware/auth');

const router = express.Router();

router.get('/recipients', authMiddleware, (req, res, next) =>
  communicationController.getRecipients(req, res, next)
);

// Messagerie privée
router.get('/messages', authMiddleware, (req, res, next) =>
  communicationController.getPrivateMessages(req, res, next)
);

router.post('/messages', authMiddleware, (req, res, next) =>
  communicationController.sendPrivateMessage(req, res, next)
);

router.patch('/messages/:id/read', authMiddleware, (req, res, next) =>
  communicationController.markPrivateMessageRead(req, res, next)
);

// Forum
router.get('/forum/threads', authMiddleware, (req, res, next) =>
  communicationController.getForumThreads(req, res, next)
);

router.get('/forum/threads/similar', authMiddleware, (req, res, next) =>
  communicationController.getSimilarForumThreads(req, res, next)
);

router.post('/forum/threads', authMiddleware, (req, res, next) =>
  communicationController.createForumThread(req, res, next)
);

router.patch('/forum/threads/:threadId/status', authMiddleware, (req, res, next) =>
  communicationController.updateForumThreadStatus(req, res, next)
);

router.post('/forum/threads/:threadId/replies', authMiddleware, (req, res, next) =>
  communicationController.addForumReply(req, res, next)
);

router.post('/forum/replies/validate', authMiddleware, (req, res, next) =>
  communicationController.validateForumReply(req, res, next)
);

router.post('/forum/replies/reaction', authMiddleware, (req, res, next) =>
  communicationController.reactToForumReply(req, res, next)
);

router.post('/forum/assistant/improve', authMiddleware, (req, res, next) =>
  communicationController.improveForumDraft(req, res, next)
);

router.get('/forum/notifications', authMiddleware, (req, res, next) =>
  communicationController.getForumNotifications(req, res, next)
);

router.patch('/forum/threads/:threadId/close', authMiddleware, (req, res, next) =>
  communicationController.closeForumThread(req, res, next)
);

// Alias REST demandés
router.post('/discussion', authMiddleware, (req, res, next) =>
  communicationController.createForumThread(req, res, next)
);

router.get('/discussions', authMiddleware, (req, res, next) =>
  communicationController.getForumThreads(req, res, next)
);

router.post('/reponse', authMiddleware, (req, res, next) =>
  communicationController.addForumReplyAlias(req, res, next)
);

router.post('/valider-reponse', authMiddleware, (req, res, next) =>
  communicationController.validateForumReply(req, res, next)
);

router.post('/reaction', authMiddleware, (req, res, next) =>
  communicationController.reactToForumReply(req, res, next)
);

router.get('/notifications', authMiddleware, (req, res, next) =>
  communicationController.getForumNotifications(req, res, next)
);

module.exports = router;
