const express = require('express');
const associationsController = require('../controllers/associations.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');

const router = express.Router();

const managerRoles = ['ADMIN', 'TEACHERDIRECTOR', 'Association', 'Admin', 'Gestionnaire d\'espace'];

// GET /api/associations
router.get('/', authMiddleware, associationsController.getAllAssociations);

// GET /api/associations/:id
router.get('/:id', authMiddleware, associationsController.getAssociationById);

// POST /api/associations
router.post(
  '/',
  authMiddleware,
  requireRole(...managerRoles),
  associationsController.createAssociation
);

// PUT /api/associations/:id
// Allow authenticated users (authorization checked in service for budget-only updates)
router.put(
  '/:id',
  authMiddleware,
  associationsController.updateAssociation
);

// DELETE /api/associations/:id
router.delete(
  '/:id',
  authMiddleware,
  requireRole(...managerRoles),
  associationsController.deleteAssociation
);

module.exports = router;
