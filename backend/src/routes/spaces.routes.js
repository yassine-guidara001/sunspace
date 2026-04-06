const express = require('express');
const spacesController = require('../controllers/spaces.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { validate } = require('../middleware/validation');
const { createSpaceSchema, updateSpaceSchema } = require('../validators/spaces.validator');

const router = express.Router();

/**
 * Routes publiques (authentification requise)
 */

// GET /api/spaces - Obtenir tous les espaces
router.get('/', authMiddleware, spacesController.getAllSpaces);

// GET /api/spaces/:id - Obtenir un espace par ID
router.get('/:id', authMiddleware, spacesController.getSpaceById);

/**
 * Routes admin uniquement
 */

// POST /api/spaces - Créer un espace (Admin/Teacher Director)
router.post(
  '/',
  authMiddleware,
  requireRole('ADMIN', 'TEACHERDIRECTOR', 'Admin', 'Gestionnaire d\'espace'),
  validate(createSpaceSchema),
  spacesController.createSpace
);

// PUT /api/spaces/:id - Mettre à jour un espace (Admin/Teacher Director)
router.put(
  '/:id',
  authMiddleware,
  requireRole('ADMIN', 'TEACHERDIRECTOR', 'Admin', 'Gestionnaire d\'espace'),
  validate(updateSpaceSchema),
  spacesController.updateSpace
);

// DELETE /api/spaces/:id - Supprimer un espace (Admin uniquement)
router.delete(
  '/:id',
  authMiddleware,
  requireRole('ADMIN', 'Admin'),
  spacesController.deleteSpace
);

module.exports = router;
