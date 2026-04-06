const express = require('express');
const router = express.Router();
const authController = require('../controllers/auth.controller');
const { validate } = require('../middleware/validation');
const { authMiddleware } = require('../middleware/auth');
const { loginSchema, registerSchema } = require('../validators/auth.validator');

/**
 * Routes d'authentification
 */

// 🔐 POST /api/auth/local - Login (compatible Strapi)
router.post(
  '/local',
  validate(loginSchema),
  authController.login
);

// 🔐 POST /api/auth/local/register - Register (compatible Strapi)
router.post(
  '/local/register',
  validate(registerSchema),
  authController.register
);

// 🔐 GET /api/auth/me - Obtenir l'utilisateur actuel
router.get(
  '/me',
  authMiddleware,
  authController.getMe
);

// 🔐 POST /api/auth/logout - Logout
router.post(
  '/logout',
  authMiddleware,
  authController.logout
);

module.exports = router;
