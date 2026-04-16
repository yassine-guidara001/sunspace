const express = require('express');
const router = express.Router();
const usersController = require('../controllers/users.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { createUserSchema, updateUserSchema } = require('../validators/users.validator');
const { ROLES } = require('../utils/roles');

/**
 * Routes des utilisateurs
 */

// 🔐 GET /api/users - Tous les utilisateurs (Admin)
router.get(
  '/',
  authMiddleware,
  requireRole(ROLES.ADMIN, ROLES.ENSEIGNANT),
  usersController.getAllUsers
);

// 🔐 POST /api/users - Créer un utilisateur (Admin)
router.post(
  '/',
  authMiddleware,
  requireRole(ROLES.ADMIN, ROLES.ENSEIGNANT),
  validate(createUserSchema),
  usersController.createUser
);

// 🔐 GET /api/users/me - Utilisateur actuel
router.get(
  '/me',
  authMiddleware,
  usersController.getCurrentUser
);

// 🔐 GET /api/users/:id - Utilisateur par ID
router.get(
  '/:id',
  authMiddleware,
  usersController.getUserById
);

// 🔐 PUT /api/users/:id - Mettre à jour (Admin ou self)
router.put(
  '/:id',
  authMiddleware,
  validate(updateUserSchema),
  usersController.updateUser
);

// 🔐 DELETE /api/users/:id - Supprimer (Admin)
router.delete(
  '/:id',
  authMiddleware,
  requireRole(ROLES.ADMIN),
  usersController.deleteUser
);

module.exports = router;
