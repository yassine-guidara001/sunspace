const express = require('express');
const trainingSessionsController = require('../controllers/trainingSessions.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { MANAGER_ROLES } = require('../utils/roles');

const router = express.Router();

const managerRoles = MANAGER_ROLES;

// GET /api/training-sessions
router.get('/', authMiddleware, trainingSessionsController.getAll);

// GET /api/training-sessions/:id
router.get('/:id', authMiddleware, trainingSessionsController.getById);

// POST /api/training-sessions
router.post(
  '/',
  authMiddleware,
  requireRole(...managerRoles),
  trainingSessionsController.create
);

// PUT /api/training-sessions/:id
router.put(
  '/:id',
  authMiddleware,
  trainingSessionsController.update
);

// DELETE /api/training-sessions/:id
router.delete(
  '/:id',
  authMiddleware,
  requireRole(...managerRoles),
  trainingSessionsController.remove
);

module.exports = router;
