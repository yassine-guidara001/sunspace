const express = require('express');
const equipmentController = require('../controllers/equipment.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');
const { ROLES } = require('../utils/roles');

const router = express.Router();

// GET /api/equipment-assets
router.get('/', equipmentController.getAllEquipments);

// GET /api/equipment-assets/:id
router.get('/:id', equipmentController.getEquipmentById);

// POST /api/equipment-assets
router.post(
  '/',
  authMiddleware,
  requireRole(ROLES.ADMIN, ROLES.ENSEIGNANT, ROLES.PROFESSIONNEL, ROLES.GESTIONNAIRE_ESPACE),
  equipmentController.createEquipment
);

// PUT /api/equipment-assets/:id
router.put(
  '/:id',
  authMiddleware,
  requireRole(ROLES.ADMIN, ROLES.ENSEIGNANT, ROLES.PROFESSIONNEL, ROLES.GESTIONNAIRE_ESPACE),
  equipmentController.updateEquipment
);

// DELETE /api/equipment-assets/:id
router.delete(
  '/:id',
  authMiddleware,
  requireRole(ROLES.ADMIN, ROLES.ENSEIGNANT, ROLES.PROFESSIONNEL, ROLES.GESTIONNAIRE_ESPACE),
  equipmentController.deleteEquipment
);

module.exports = router;
