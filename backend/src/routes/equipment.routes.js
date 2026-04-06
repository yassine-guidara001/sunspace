const express = require('express');
const equipmentController = require('../controllers/equipment.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');

const router = express.Router();

// GET /api/equipment-assets
router.get('/', equipmentController.getAllEquipments);

// GET /api/equipment-assets/:id
router.get('/:id', equipmentController.getEquipmentById);

// POST /api/equipment-assets
router.post(
  '/',
  authMiddleware,
  requireRole('ADMIN', 'TEACHERDIRECTOR', 'TECHNICIAN', 'Admin', 'Gestionnaire d\'espace'),
  equipmentController.createEquipment
);

// PUT /api/equipment-assets/:id
router.put(
  '/:id',
  authMiddleware,
  requireRole('ADMIN', 'TEACHERDIRECTOR', 'TECHNICIAN', 'Admin', 'Gestionnaire d\'espace'),
  equipmentController.updateEquipment
);

// DELETE /api/equipment-assets/:id
router.delete(
  '/:id',
  authMiddleware,
  requireRole('ADMIN', 'TEACHERDIRECTOR', 'TECHNICIAN', 'Admin', 'Gestionnaire d\'espace'),
  equipmentController.deleteEquipment
);

module.exports = router;
