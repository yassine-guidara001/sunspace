const express = require('express');
const assignmentsController = require('../controllers/assignments.controller');
const { authMiddleware, requireRole } = require('../middleware/auth');

const router = express.Router();

const managerRoles = ['ADMIN', 'TEACHERDIRECTOR', 'Admin', 'Enseignant', 'Professionnel', 'Association'];

router.get('/', authMiddleware, assignmentsController.getAll);
router.get('/:id', authMiddleware, assignmentsController.getById);
router.post('/', authMiddleware, requireRole(...managerRoles), assignmentsController.create);
router.put('/:id', authMiddleware, requireRole(...managerRoles), assignmentsController.update);
router.patch('/:id', authMiddleware, requireRole(...managerRoles), assignmentsController.update);
router.delete('/:id', authMiddleware, requireRole(...managerRoles), assignmentsController.delete);

module.exports = router;
